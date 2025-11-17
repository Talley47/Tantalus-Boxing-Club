import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { FighterDashboard } from '@/components/dashboard/FighterDashboard'
import { Navigation } from '@/components/Navigation'

export default async function DashboardPage() {
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

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">
            Welcome back, {fighterProfile.name}!
          </h1>
          <p className="text-gray-600 mt-2">
            Ready to step into the ring?
          </p>
        </div>
        
        <FighterDashboard fighterProfile={fighterProfile} />
      </div>
    </div>
  )
}
