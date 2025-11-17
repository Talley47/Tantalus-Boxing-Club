import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { RankingsList } from '@/components/rankings/RankingsList'
import { RankingsFilters } from '@/components/rankings/RankingsFilters'

export default async function RankingsPage({
  searchParams,
}: {
  searchParams: { weightClass?: string; tier?: string }
}) {
  const supabase = await createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    redirect('/login')
  }

  // Get fighter rankings
  let query = supabase
    .from('fighter_profiles')
    .select('*')
    .order('points', { ascending: false })
    .limit(100)

  if (searchParams.weightClass) {
    query = query.eq('weight_class', searchParams.weightClass)
  }

  if (searchParams.tier) {
    query = query.eq('tier', searchParams.tier)
  }

  const { data: rankings } = await query

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Fighter Rankings</h1>
          <p className="text-gray-600 mt-2">
            See how you stack up against other fighters
          </p>
        </div>
        
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          {/* Rankings List */}
          <div className="lg:col-span-3">
            <RankingsList rankings={rankings || []} />
          </div>
          
          {/* Filters */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-6">
              Filter Rankings
            </h2>
            <RankingsFilters />
          </div>
        </div>
      </div>
    </div>
  )
}
