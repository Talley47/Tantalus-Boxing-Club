import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { MatchmakingForm } from '@/components/matchmaking/MatchmakingForm'
import { MatchmakingRequests } from '@/components/matchmaking/MatchmakingRequests'

export default async function MatchmakingPage() {
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

  // Get matchmaking requests
  const { data: requests } = await supabase
    .from('matchmaking_requests')
    .select('*')
    .eq('fighter_id', fighterProfile.id)
    .order('created_at', { ascending: false })

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Matchmaking</h1>
          <p className="text-gray-600 mt-2">
            Find your next opponent and schedule fights
          </p>
        </div>
        
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Matchmaking Form */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-6">
              Request a Match
            </h2>
            <MatchmakingForm fighterProfile={fighterProfile} />
          </div>
          
          {/* Matchmaking Requests */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-6">
              Your Matchmaking Requests
            </h2>
            <MatchmakingRequests requests={requests || []} />
          </div>
        </div>
      </div>
    </div>
  )
}