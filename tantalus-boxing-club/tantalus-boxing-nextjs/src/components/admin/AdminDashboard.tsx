'use client'

import { useState } from 'react'
import { getSystemStats, updateSystemSettings } from '@/lib/actions/admin'

interface AdminDashboardProps {
  systemStats: any
  recentDisputes: any[]
  recentUsers: any[]
}

export function AdminDashboard({ systemStats, recentDisputes, recentUsers }: AdminDashboardProps) {
  const [isUpdating, setIsUpdating] = useState(false)
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  const handleSystemSettingsUpdate = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setIsUpdating(true)
    setMessage(null)

    const formData = new FormData(e.currentTarget)
    const result = await updateSystemSettings(formData)

    if (result?.error) {
      setMessage({ type: 'error', text: result.error })
    } else if (result?.success) {
      setMessage({ type: 'success', text: result.message })
    }

    setIsUpdating(false)
  }

  return (
    <div className="space-y-8">
      {/* System Statistics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <div className="w-8 h-8 bg-blue-500 rounded-md flex items-center justify-center">
                <span className="text-white text-sm font-medium">👥</span>
              </div>
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Total Users</p>
              <p className="text-2xl font-bold text-gray-900">{systemStats?.total_users || 0}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <div className="w-8 h-8 bg-green-500 rounded-md flex items-center justify-center">
                <span className="text-white text-sm font-medium">🥊</span>
              </div>
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Total Fighters</p>
              <p className="text-2xl font-bold text-gray-900">{systemStats?.total_fighters || 0}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <div className="w-8 h-8 bg-purple-500 rounded-md flex items-center justify-center">
                <span className="text-white text-sm font-medium">🏆</span>
              </div>
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Tournaments</p>
              <p className="text-2xl font-bold text-gray-900">{systemStats?.total_tournaments || 0}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <div className="w-8 h-8 bg-red-500 rounded-md flex items-center justify-center">
                <span className="text-white text-sm font-medium">⚠️</span>
              </div>
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Pending Disputes</p>
              <p className="text-2xl font-bold text-gray-900">{systemStats?.pending_disputes || 0}</p>
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* System Settings */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-6">System Settings</h2>
          
          {message && (
            <div className={`p-4 rounded-md mb-6 ${
              message.type === 'success' 
                ? 'bg-green-50 text-green-800 border border-green-200' 
                : 'bg-red-50 text-red-800 border border-red-200'
            }`}>
              {message.text}
            </div>
          )}

          <form onSubmit={handleSystemSettingsUpdate} className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label htmlFor="maintenanceMode" className="block text-sm font-medium text-gray-700 mb-2">
                  Maintenance Mode
                </label>
                <select
                  id="maintenanceMode"
                  name="maintenanceMode"
                  defaultValue={systemStats?.maintenance_mode ? 'true' : 'false'}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                >
                  <option value="false">Disabled</option>
                  <option value="true">Enabled</option>
                </select>
              </div>

              <div>
                <label htmlFor="registrationEnabled" className="block text-sm font-medium text-gray-700 mb-2">
                  Registration
                </label>
                <select
                  id="registrationEnabled"
                  name="registrationEnabled"
                  defaultValue={systemStats?.registration_enabled ? 'true' : 'false'}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                >
                  <option value="true">Enabled</option>
                  <option value="false">Disabled</option>
                </select>
              </div>

              <div>
                <label htmlFor="maxFightersPerTournament" className="block text-sm font-medium text-gray-700 mb-2">
                  Max Fighters per Tournament
                </label>
                <input
                  id="maxFightersPerTournament"
                  name="maxFightersPerTournament"
                  type="number"
                  min="2"
                  max="64"
                  defaultValue={systemStats?.max_fighters_per_tournament || 16}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                />
              </div>

              <div>
                <label htmlFor="pointsPerWin" className="block text-sm font-medium text-gray-700 mb-2">
                  Points per Win
                </label>
                <input
                  id="pointsPerWin"
                  name="pointsPerWin"
                  type="number"
                  min="1"
                  max="100"
                  defaultValue={systemStats?.points_per_win || 10}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={isUpdating}
              className="w-full bg-red-600 text-white py-2 px-4 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isUpdating ? 'Updating...' : 'Update Settings'}
            </button>
          </form>
        </div>

        {/* Recent Disputes */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-6">Recent Disputes</h2>
          
          <div className="space-y-4">
            {recentDisputes.map((dispute) => (
              <div key={dispute.id} className="border border-gray-200 rounded-lg p-4">
                <div className="flex justify-between items-start mb-2">
                  <h3 className="text-sm font-medium text-gray-900">{dispute.title}</h3>
                  <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                    dispute.status === 'pending' 
                      ? 'bg-yellow-100 text-yellow-800'
                      : dispute.status === 'resolved'
                      ? 'bg-green-100 text-green-800'
                      : 'bg-red-100 text-red-800'
                  }`}>
                    {dispute.status}
                  </span>
                </div>
                <p className="text-sm text-gray-600 mb-2">{dispute.description}</p>
                <div className="flex justify-between items-center text-xs text-gray-500">
                  <span>By {dispute.user?.full_name || 'Unknown'}</span>
                  <span>{new Date(dispute.created_at).toLocaleDateString()}</span>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-4">
            <a 
              href="/admin/disputes"
              className="text-red-600 hover:text-red-700 text-sm font-medium"
            >
              View all disputes →
            </a>
          </div>
        </div>
      </div>

      {/* Recent Users */}
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-semibold text-gray-900 mb-6">Recent Users</h2>
        
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  User
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Role
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Fighter Profile
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Joined
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {recentUsers.map((user) => (
                <tr key={user.id}>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div>
                      <div className="text-sm font-medium text-gray-900">{user.full_name}</div>
                      <div className="text-sm text-gray-500">{user.email}</div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                      user.role === 'admin' 
                        ? 'bg-red-100 text-red-800'
                        : user.role === 'moderator'
                        ? 'bg-blue-100 text-blue-800'
                        : 'bg-gray-100 text-gray-800'
                    }`}>
                      {user.role || 'user'}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {user.fighter_profile ? 'Yes' : 'No'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {new Date(user.created_at).toLocaleDateString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="mt-4">
          <a 
            href="/admin/users"
            className="text-red-600 hover:text-red-700 text-sm font-medium"
          >
            View all users →
          </a>
        </div>
      </div>
    </div>
  )
}

