import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { AdminDashboard } from '@/components/admin/AdminDashboard'
import { Navigation } from '@/components/navigation/Navigation'

export default async function AdminPage() {
  const supabase = createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    redirect('/login')
  }

  // Check if user is admin (you'll need to implement this check)
  // For now, we'll allow access - implement proper admin check later

  // Get system statistics
  const { data: systemStats } = await supabase
    .from('system_settings')
    .select('*')
    .eq('id', 'main')
    .single()

  // Get recent disputes
  const { data: recentDisputes } = await supabase
    .from('disputes')
    .select(`
      *,
      user:profiles!disputes_user_id_fkey(full_name, email)
    `)
    .order('created_at', { ascending: false })
    .limit(5)

  // Get recent users
  const { data: recentUsers } = await supabase
    .from('profiles')
    .select(`
      *,
      fighter_profile:fighter_profiles(*)
    `)
    .order('created_at', { ascending: false })
    .limit(5)

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Admin Dashboard</h1>
          <p className="text-gray-600 mt-2">
            Manage users, disputes, and system settings
          </p>
        </div>
        
        <AdminDashboard 
          systemStats={systemStats}
          recentDisputes={recentDisputes || []}
          recentUsers={recentUsers || []}
        />
      </div>
    </div>
  )
}

