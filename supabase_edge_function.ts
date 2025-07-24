import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    // Add proper headers for Unicode support
    const headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    }

    if (req.method === 'OPTIONS') {
      return new Response(null, { status: 200, headers })
    }

    const authHeader = req.headers.get('Authorization')!
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers }
      )
    }

    // Get request body with proper Unicode handling
    const body = await req.text()
    const { title, body: entryBody, mood, date } = JSON.parse(body)

    // Validate required fields
    if (!title || !entryBody || !mood || !date) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers }
      )
    }

    // Validate mood range
    if (mood < 1 || mood > 5) {
      return new Response(
        JSON.stringify({ error: 'Mood must be between 1 and 5' }),
        { status: 400, headers }
      )
    }

    // Check if entry already exists for this date
    const { data: existingEntries } = await supabaseClient
      .from('journal_entries')
      .select('id')
      .eq('user_id', user.id)
      .eq('date', date)

    if (existingEntries && existingEntries.length > 0) {
      return new Response(
        JSON.stringify({ error: 'Entry already exists for this date' }),
        { status: 409, headers }
      )
    }

    // Insert new entry
    const { data, error } = await supabaseClient
      .from('journal_entries')
      .insert({
        user_id: user.id,
        title,
        body: entryBody,
        mood,
        date,
      })
      .select()
      .single()

    if (error) {
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 400, headers }
      )
    }

    return new Response(
      JSON.stringify({ data }),
      { status: 200, headers }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500, 
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Access-Control-Allow-Origin': '*'
        }
      }
    )
  }
}) 