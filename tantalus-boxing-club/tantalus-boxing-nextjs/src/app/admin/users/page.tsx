import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { UserManagement } from '@/components/admin/UserManagement'
import { Navigation } from '@/components/navigation/Navigation'

export default async function AdminUsersPage({
  searchParams,
}: {
  searchParams: { page?: string; search?: string }
}) {
  const supabase = await createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    redirect('/login')
  }

  // Check if user is admin (you'll need to implement this check)
  // For now, we'll allow access - implement proper admin check later

  const page = parseInt(searchParams.page || '1')
  const search = searchParams.search || ''

  // Get users with pagination
  const { data: users } = await supabase
    .from('profiles')
    .select(`
      *,
      fighter_profile:fighter_profiles(*)
    `)
    .order('created_at', { ascending: false })
    .range((page - 1) * 20, page * 20 - 1)

  // Get total count
  const { count: totalUsers } = await supabase
    .from('profiles')
    .select('*', { count: 'exact', head: true })

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">User Management</h1>
          <p className="text-gray-600 mt-2">
            Manage user accounts, roles, and permissions
          </p>
        </div>
        
        <UserManagement 
          users={users || []}
          totalUsers={totalUsers || 0}
          currentPage={page}
          search={search}
        />
      </div>
    </div>
  )
}

