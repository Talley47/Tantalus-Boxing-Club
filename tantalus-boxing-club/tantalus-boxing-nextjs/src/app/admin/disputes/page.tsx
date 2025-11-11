import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { DisputeResolution } from '@/components/admin/DisputeResolution'
import { Navigation } from '@/components/navigation/Navigation'

export default async function AdminDisputesPage({
  searchParams,
}: {
  searchParams: { status?: string }
}) {
  const supabase = createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    redirect('/login')
  }

  // Check if user is admin (you'll need to implement this check)
  // For now, we'll allow access - implement proper admin check later

  const status = searchParams.status || ''

  // Get disputes
  let query = supabase
    .from('disputes')
    .select(`
      *,
      user:profiles!disputes_user_id_fkey(full_name, email),
      fight:fight_records!disputes_related_fight_id_fkey(opponent_name, result, date)
    `)
    .order('created_at', { ascending: false })

  if (status) {
    query = query.eq('status', status)
  }

  const { data: disputes } = await query

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Dispute Resolution</h1>
          <p className="text-gray-600 mt-2">
            Review and resolve user disputes
          </p>
        </div>
        
        <DisputeResolution 
          disputes={disputes || []}
          currentStatus={status}
        />
      </div>
    </div>
  )
}

