// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import Stripe from "https://esm.sh/stripe@12.0.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)

    if (authError || !user) {
      throw new Error('Unauthorized')
    }

    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY') ?? ''
    console.log(`[Debug] Stripe Key starts with: ${stripeKey.substring(0, 7)}...`)

    const stripe = new Stripe(stripeKey, {
      apiVersion: '2022-11-15',
    })

    // 1. Get driver info
    const { data: driver, error: driverError } = await supabaseClient
      .from('drivers')
      .select('stripe_account_id, email, full_name, stripe_onboarding_completed')
      .eq('id', user.id)
      .single()

    if (driverError) throw driverError

    let stripeAccountId = driver.stripe_account_id
    let onboardingCompleted = driver.stripe_onboarding_completed

    // 2. Create Stripe account if not exists
    if (!stripeAccountId) {
      const account = await stripe.accounts.create({
        type: 'express',
        email: driver.email,
        capabilities: {
          transfers: { requested: true },
        },
        metadata: {
          driver_id: user.id,
        },
      })
      stripeAccountId = account.id

      // Save to DB
      await supabaseClient
        .from('drivers')
        .update({ stripe_account_id: stripeAccountId })
        .eq('id', user.id)
    } else if (!onboardingCompleted) {
      // Check if they finished onboarding already
      const account = await stripe.accounts.retrieve(stripeAccountId)
      if (account.details_submitted && account.charges_enabled) {
        onboardingCompleted = true
        await supabaseClient
          .from('drivers')
          .update({ stripe_onboarding_completed: true })
          .eq('id', user.id)
        
        return new Response(
          JSON.stringify({ url: null, completed: true }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // 3. Create Account Link
    const accountLink = await stripe.accountLinks.create({
      account: stripeAccountId,
      refresh_url: 'https://example.com/stripe-refresh', // You can change this to your app's deep link
      return_url: 'https://example.com/stripe-return',   // You can change this to your app's deep link
      type: 'account_onboarding',
    })

    return new Response(
      JSON.stringify({ url: accountLink.url }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
