// @ts-nocheck
// Supabase Edge Function: send-notification
// Uses FCM HTTP v1 API with Service Account authentication (OAuth2 JWT flow).
// Secrets required (set via Supabase Dashboard → Settings → Edge Functions):
//   FIREBASE_SERVICE_ACCOUNT_JSON  — full service account JSON string
// Auto-available in every Edge Function:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FIREBASE_PROJECT_ID = "fueldirect-462cc";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ── OAuth2 Access Token via Service Account JWT ────────────────────────────

async function getGoogleAccessToken(): Promise<string> {
  const saJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!saJson) throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON secret not set");

  console.log("[Auth] Parsing service account JSON...");
  const sa = JSON.parse(saJson);
  console.log("[Auth] Service account email:", sa.client_email);

  const now = Math.floor(Date.now() / 1000);
  const claimSet = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  // Base64url encode without padding
  const b64url = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/=/g, "")
      .replace(/\+/g, "-")
      .replace(/\//g, "_");

  const header = b64url({ alg: "RS256", typ: "JWT" });
  const payload = b64url(claimSet);
  const signingInput = `${header}.${payload}`;

  // Import service account private key (PKCS8 PEM → CryptoKey)
  const pem = (sa.private_key as string)
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\r?\n/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const sigBytes = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signingInput),
  );

  const sig = btoa(String.fromCharCode(...new Uint8Array(sigBytes)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  const jwt = `${signingInput}.${sig}`;

  // Exchange JWT for short-lived Google OAuth2 access token
  console.log("[Auth] Exchanging JWT for Google access token...");
  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  if (!tokenRes.ok) {
    const err = await tokenRes.text();
    console.error("[Auth] OAuth token exchange FAILED:", err);
    throw new Error(`OAuth token exchange failed: ${err}`);
  }

  const tokenData = await tokenRes.json();
  console.log("[Auth] Google access token obtained ✓ (expires in 3600s)");
  return tokenData.access_token as string;
}

// ── FCM v1 Send ────────────────────────────────────────────────────────────

async function sendFCMMessage(
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string> = {},
): Promise<void> {
  const accessToken = await getGoogleAccessToken();

  const message = {
    message: {
      token: fcmToken,
      notification: { title, body },
      data, // all values must be strings for FCM data payload
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channel_id: "order_updates",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        headers: { "apns-priority": "10" },
        payload: { aps: { sound: "default", badge: 1 } },
      },
    },
  };

  console.log("[FCM] Sending to token:", fcmToken.substring(0, 20) + "...");
  console.log("[FCM] Payload:", JSON.stringify({ title, body, data }));

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(message),
    },
  );

  const responseText = await res.text();

  if (!res.ok) {
    console.error(`[FCM] Send FAILED (HTTP ${res.status}):`, responseText);
    throw new Error(`FCM send failed (${res.status}): ${responseText}`);
  }

  const result = JSON.parse(responseText);
  console.log("[FCM] Message sent successfully ✓ name:", result.name);
}

// ── Main Handler ────────────────────────────────────────────────────────────

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  console.log("[Handler] Request received:", req.method, req.url);

  try {
    // Init Supabase with service-role key to bypass RLS for token lookup
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    if (!supabaseUrl || !serviceRole) {
      throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars");
    }

    const supabase = createClient(supabaseUrl, serviceRole);

    // Parse request body
    let requestBody: Record<string, unknown>;
    try {
      requestBody = await req.json();
    } catch {
      return new Response(
        JSON.stringify({ error: "Invalid JSON body" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const { target_type, target_id, title, body, data } = requestBody as {
      target_type: string;
      target_id: string;
      title: string;
      body: string;
      data?: Record<string, string>;
    };

    console.log(`[Handler] target_type=${target_type}, target_id=${target_id}, title="${title}"`);

    // Validate required fields
    if (!target_type || !target_id || !title || !body) {
      console.warn("[Handler] Missing required fields");
      return new Response(
        JSON.stringify({
          error: "Missing required fields: target_type, target_id, title, body",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // ── Look up FCM token from Supabase ──
    let fcmToken: string | null = null;

    if (target_type === "user") {
      console.log("[DB] Looking up FCM token in profiles table...");
      const { data: profile, error } = await supabase
        .from("profiles")
        .select("fcm_token")
        .eq("id", target_id)
        .maybeSingle();

      if (error) {
        console.error("[DB] profiles lookup error:", error.message);
      } else {
        console.log("[DB] Profile found, fcm_token:", profile?.fcm_token ? "present" : "NULL");
      }
      fcmToken = profile?.fcm_token ?? null;

    } else if (target_type === "driver") {
      console.log("[DB] Looking up FCM token in drivers table...");
      const { data: driver, error } = await supabase
        .from("drivers")
        .select("fcm_token")
        .eq("id", target_id)
        .maybeSingle();

      if (error) {
        console.error("[DB] drivers lookup error:", error.message);
      } else {
        console.log("[DB] Driver found, fcm_token:", driver?.fcm_token ? "present" : "NULL");
      }
      fcmToken = driver?.fcm_token ?? null;

    } else {
      console.warn("[Handler] Invalid target_type:", target_type);
      return new Response(
        JSON.stringify({ error: "target_type must be 'user' or 'driver'" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // Graceful skip if no token registered
    if (!fcmToken) {
      console.warn(
        `[Handler] No FCM token for ${target_type} ${target_id} — notification skipped.`,
        "\nThis means the target device hasn't registered its FCM token yet.",
      );
      return new Response(
        JSON.stringify({ success: true, skipped: true, reason: "no_token" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Ensure all data values are strings (FCM requirement)
    const stringData: Record<string, string> = {};
    if (data && typeof data === "object") {
      for (const [k, v] of Object.entries(data)) {
        stringData[k] = String(v);
      }
    }

    // ── Save Notification to Database for In-App History ──
    let dbError = null;
    console.log(`[DB] Saving notification to database for ${target_type} ${target_id}...`);
    if (target_type === "driver") {
      const { error } = await supabase.from("notifications").insert({
        driver_id: target_id,
        title: title,
        body: body,
        message: body, // Added for compatibility with Flutter UI
        type: data?.type || 'system',
        is_read: false,
        order_id: data?.order_id || null
      });
      dbError = error;
    } else if (target_type === "user") {
      const { error } = await supabase.from("notifications").insert({
        user_id: target_id,
        title: title,
        body: body,
        message: body, // Added for compatibility with Flutter UI
        type: data?.type || 'system',
        is_read: false,
        order_id: data?.order_id || null
      });
      dbError = error;
    }
    
    if (dbError) {
      console.error("[DB] Failed to save notification history:", dbError.message);
    } else {
      console.log("[DB] Notification history saved successfully ✓");
    }

    await sendFCMMessage(fcmToken, title, body, stringData);

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );

  } catch (error) {
    const errMsg = (error as Error).message;
    console.error("[Handler] Unhandled error:", errMsg);
    return new Response(
      JSON.stringify({ error: errMsg }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
