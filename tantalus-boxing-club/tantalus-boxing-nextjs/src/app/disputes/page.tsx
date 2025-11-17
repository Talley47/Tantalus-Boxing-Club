import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { DisputeForm } from '@/components/disputes/DisputeForm'
import { Navigation } from '@/components/navigation/Navigation'

export default async function DisputesPage() {
  const supabase = await createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    redirect('/login')
  }

  // Get user's disputes
  const { data: userDisputes } = await supabase
    .from('disputes')
    .select(`
      *,
      fight:fight_records!disputes_related_fight_id_fkey(opponent_name, result, date)
    `)
    .eq('user_id', user.id)
    .order('created_at', { ascending: false })

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Dispute Center</h1>
          <p className="text-gray-600 mt-2">
            Submit disputes and track their resolution
          </p>
        </div>
        
        <DisputeForm 
          userDisputes={userDisputes || []}
        />
      </div>
    </div>
  )
}

