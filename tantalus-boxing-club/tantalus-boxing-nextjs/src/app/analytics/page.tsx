import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { AnalyticsDashboard } from '@/components/analytics/AnalyticsDashboard'
import { Navigation } from '@/components/navigation/Navigation'

export default async function AnalyticsPage() {
  const supabase = await createClient()
  
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

  // Get fighter analytics
  const { data: fightRecords } = await supabase
    .from('fight_records')
    .select('*')
    .eq('fighter_id', fighterProfile.id)
    .order('date', { ascending: false })

  const { data: trainingLogs } = await supabase
    .from('training_logs')
    .select('*')
    .eq('fighter_id', fighterProfile.id)
    .order('date', { ascending: false })

  // Get league analytics
  const { data: allFighters } = await supabase
    .from('fighter_profiles')
    .select('*')
    .order('points', { ascending: false })

  const { data: allFightRecords } = await supabase
    .from('fight_records')
    .select('*')
    .order('date', { ascending: false })

  const { data: tournaments } = await supabase
    .from('tournaments')
    .select('*')
    .order('created_at', { ascending: false })

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Analytics Dashboard</h1>
          <p className="text-gray-600 mt-2">
            Track your performance and league statistics
          </p>
        </div>
        
        <AnalyticsDashboard 
          fighterProfile={fighterProfile}
          fightRecords={fightRecords || []}
          trainingLogs={trainingLogs || []}
          allFighters={allFighters || []}
          allFightRecords={allFightRecords || []}
          tournaments={tournaments || []}
        />
      </div>
    </div>
  )
}

