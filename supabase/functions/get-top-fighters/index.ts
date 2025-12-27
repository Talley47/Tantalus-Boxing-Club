// ============================================================================
// 🎯 BEST PRACTICE: Edge Function for Top Fighters Leaderboard
// ============================================================================
// This uses SERVICE_ROLE_KEY (bypasses RLS) - NEVER expose this to browser!
// Deploy: supabase functions deploy get-top-fighters
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client with SERVICE_ROLE_KEY (bypasses RLS)
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // Parse query parameters
    const url = new URL(req.url)
    const limit = parseInt(url.searchParams.get('limit') || '30', 10)

    // Query fighter_profiles using SERVICE_ROLE (bypasses RLS)
    const { data, error } = await supabaseAdmin
      .from('fighter_profiles')
      .select('user_id, name, handle, tier, points, weight_class, wins, losses, draws, height_feet, height_inches, weight, reach, stance, hometown, birthday, trainer, gym')
      .not('user_id', 'is', null)
      .order('points', { ascending: false })
      .limit(limit)

    if (error) {
      throw error
    }

    // Filter out admin accounts (optional - do this server-side)
    const filteredData = data.filter(fighter => {
      // You can add admin filtering logic here if needed
      return true
    })

    return new Response(
      JSON.stringify({ 
        success: true, 
        fighters: filteredData,
        count: filteredData.length 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      },
    )
  }
})

