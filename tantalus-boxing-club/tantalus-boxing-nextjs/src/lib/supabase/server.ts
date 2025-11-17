import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

  if (!supabaseUrl || !supabaseAnonKey) {
    // In development, provide helpful error message
    if (process.env.NODE_ENV === 'development') {
      throw new Error(
        'Missing Supabase environment variables. Please set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY'
      )
    }
    // In production/build, throw error to prevent incomplete builds
    // This ensures environment variables are properly configured
    throw new Error(
      'Missing Supabase environment variables. Please set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY in Vercel environment variables.'
    )
  }

  const cookieStore = await cookies()

  return createServerClient(supabaseUrl, supabaseAnonKey, {
    cookies: {
      getAll() {
        return cookieStore.getAll()
      },
      setAll(cookiesToSet) {
        try {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options)
          )
        } catch {
          // The `setAll` method was called from a Server Component.
          // This can be ignored if you have middleware refreshing
          // user sessions.
        }
      },
    },
  })
}
