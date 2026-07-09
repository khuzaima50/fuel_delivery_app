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

    if (authError || !user) throw new Error('Unauthorized')

    const body = await req.json()
    const { amount, action } = body

    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY') ?? ''
    console.log(`[Debug] Stripe Key starts with: ${stripeKey.substring(0, 7)}...`)

    const stripe = new Stripe(stripeKey, {
      apiVersion: '2022-11-15',
    })

    // Handle Onboarding Link Action
    if (action === 'create_account_link') {
       const { data: driver, error: driverError } = await supabaseClient
        .from('drivers')
        .select('stripe_account_id, email, stripe_onboarding_completed')
        .eq('id', user.id)
        .single()

      if (driverError) throw driverError

      let stripeAccountId = driver.stripe_account_id
      let onboardingCompleted = driver.stripe_onboarding_completed

      if (!stripeAccountId) {
        const account = await stripe.accounts.create({
          type: 'express',
          email: driver.email,
          capabilities: { transfers: { requested: true } },
        })
        stripeAccountId = account.id
        await supabaseClient.from('drivers').update({ stripe_account_id: stripeAccountId }).eq('id', user.id)
      } else if (!onboardingCompleted) {
        const account = await stripe.accounts.retrieve(stripeAccountId)
        if (account.details_submitted && account.charges_enabled) {
          await supabaseClient.from('drivers').update({ stripe_onboarding_completed: true }).eq('id', user.id)
          return new Response(JSON.stringify({ url: null, completed: true }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
        }
      }

      const accountLink = await stripe.accountLinks.create({
        account: stripeAccountId,
        refresh_url: 'https://example.com/stripe-refresh',
        return_url: 'https://example.com/stripe-return',
        type: 'account_onboarding',
      })

      return new Response(JSON.stringify({ url: accountLink.url }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // Default: Payout Logic
    const { data: driver, error: driverError } = await supabaseClient
      .from('drivers')
      .select('stripe_account_id, wallet_balance')
      .eq('id', user.id)
      .single()

    if (driverError) throw driverError
    if (!driver.stripe_account_id) throw new Error('Stripe account not linked')
    if (driver.wallet_balance < amount) throw new Error('Insufficient balance')

    // Create Transfer to Connect Account
    const transfer = await stripe.transfers.create({
      amount: Math.round(amount * 100), // convert to cents
      currency: 'usd',
      destination: driver.stripe_account_id,
    })

    // Update Balance
    await supabaseClient
      .from('drivers')
      .update({ wallet_balance: driver.wallet_balance - amount })
      .eq('id', user.id)

    // Log Transaction
    await supabaseClient.from('wallet_transactions').insert({
      driver_id: user.id,
      amount: -amount,
      type: 'withdrawal',
      status: 'completed',
      stripe_transfer_id: transfer.id,
    })

    return new Response(
      JSON.stringify({ success: true, transfer_id: transfer.id }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
