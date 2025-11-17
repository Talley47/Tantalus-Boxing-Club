import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { RecordEntryForm } from '@/components/record-entry/RecordEntryForm'
import { FightHistory } from '@/components/record-entry/FightHistory'

export default async function RecordEntryPage() {
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

  // Get fight history
  const { data: fightHistory } = await supabase
    .from('fight_records')
    .select('*')
    .eq('fighter_id', fighterProfile.id)
    .order('date', { ascending: false })

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Fight Record Entry</h1>
          <p className="text-gray-600 mt-2">
            Log your fights and track your progress
          </p>
        </div>
        
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Record Entry Form */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-6">
              Add Fight Record
            </h2>
            <RecordEntryForm fighterProfile={fighterProfile} />
          </div>
          
          {/* Fight History */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-6">
              Fight History
            </h2>
            <FightHistory fights={fightHistory || []} />
          </div>
        </div>
      </div>
    </div>
  )
}

