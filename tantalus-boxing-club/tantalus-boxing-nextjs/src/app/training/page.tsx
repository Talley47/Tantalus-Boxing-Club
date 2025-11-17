import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { TrainingCamps } from '@/components/training/TrainingCamps'
import { Navigation } from '@/components/navigation/Navigation'

export default async function TrainingPage() {
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

  // Get training camps
  const { data: trainingCamps } = await supabase
    .from('training_camps')
    .select(`
      *,
      creator:profiles!training_camps_created_by_fkey(full_name)
    `)
    .order('created_at', { ascending: false })

  // Get training logs
  const { data: trainingLogs } = await supabase
    .from('training_logs')
    .select('*')
    .eq('fighter_id', fighterProfile.id)
    .order('date', { ascending: false })

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Training Camps</h1>
          <p className="text-gray-600 mt-2">
            Join training camps and track your progress
          </p>
        </div>
        
        <TrainingCamps 
          trainingCamps={trainingCamps || []} 
          trainingLogs={trainingLogs || []}
          fighterProfile={fighterProfile}
        />
      </div>
    </div>
  )
}

