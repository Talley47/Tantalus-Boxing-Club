import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { MediaHub } from '@/components/media/MediaHub'
import { Navigation } from '@/components/navigation/Navigation'

export default async function MediaPage() {
  const supabase = createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    redirect('/login')
  }

  // Get fighter profile
  const { data: fighterProfile } = await supabase
    .from('fighter_profiles')
    .select('*')
    .eq('user_id', user.id)
    .single()

  if (!fighterProfile) {
    redirect('/register')
  }

  // Get media assets
  const { data: mediaAssets } = await supabase
    .from('media_assets')
    .select(`
      *,
      user:profiles!media_assets_user_id_fkey(full_name)
    `)
    .order('created_at', { ascending: false })

  // Get interviews
  const { data: interviews } = await supabase
    .from('interviews')
    .select(`
      *,
      fighter:fighter_profiles!interviews_fighter_id_fkey(name, handle)
    `)
    .order('scheduled_date', { ascending: true })

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Media Hub</h1>
          <p className="text-gray-600 mt-2">
            Share your highlights, training videos, and interviews
          </p>
        </div>
        
        <MediaHub 
          mediaAssets={mediaAssets || []} 
          interviews={interviews || []}
          fighterProfile={fighterProfile}
        />
      </div>
    </div>
  )
}

