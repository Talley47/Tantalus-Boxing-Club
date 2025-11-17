import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { MonitoringDashboard } from '@/components/admin/MonitoringDashboard'
import { Navigation } from '@/components/navigation/Navigation'

export default async function AdminMonitoringPage() {
  const supabase = await createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    redirect('/login')
  }

  // Check if user is admin (you'll need to implement this check)
  // For now, we'll allow access - implement proper admin check later

  // Get system metrics
  const { data: systemStats } = await supabase
    .from('system_settings')
    .select('*')
    .eq('id', 'main')
    .single()

  // Get recent logs
  const { data: recentLogs } = await supabase
    .from('application_logs')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(100)

  // Get error logs
  const { data: errorLogs } = await supabase
    .from('application_logs')
    .select('*')
    .eq('level', 'error')
    .order('created_at', { ascending: false })
    .limit(50)

  // Get performance metrics
  const { data: performanceLogs } = await supabase
    .from('application_logs')
    .select('*')
    .eq('level', 'performance')
    .order('created_at', { ascending: false })
    .limit(100)

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">System Monitoring</h1>
          <p className="text-gray-600 mt-2">
            Monitor system health, performance, and errors
          </p>
        </div>
        
        <MonitoringDashboard 
          systemStats={systemStats}
          recentLogs={recentLogs || []}
          errorLogs={errorLogs || []}
          performanceLogs={performanceLogs || []}
        />
      </div>
    </div>
  )
}

