import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { TournamentsList } from '@/components/tournaments/TournamentsList'
import { CreateTournamentForm } from '@/components/tournaments/CreateTournamentForm'

export default async function TournamentsPage() {
  const supabase = await createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    redirect('/login')
  }

  // Get tournaments
  const { data: tournaments } = await supabase
    .from('tournaments')
    .select(`
      *,
      creator:profiles!tournaments_created_by_fkey(full_name)
    `)
    .order('created_at', { ascending: false })

  // Get user's fighter profile
  const { data: fighterProfile } = await supabase
    .from('fighter_profiles')
    .select('id')
    .eq('user_id', user.id)
    .single()

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Tournaments</h1>
          <p className="text-gray-600 mt-2">
            Compete in tournaments and climb the rankings
          </p>
        </div>
        
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Tournaments List */}
          <div className="lg:col-span-2">
            <TournamentsList tournaments={tournaments || []} />
          </div>
          
          {/* Create Tournament Form */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-6">
              Create Tournament
            </h2>
            <CreateTournamentForm />
          </div>
        </div>
      </div>
    </div>
  )
}
