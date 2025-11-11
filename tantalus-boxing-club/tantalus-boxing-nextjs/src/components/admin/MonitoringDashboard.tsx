'use client'

import { useState } from 'react'

interface MonitoringDashboardProps {
  systemStats: any
  recentLogs: any[]
  errorLogs: any[]
  performanceLogs: any[]
}

export function MonitoringDashboard({ 
  systemStats, 
  recentLogs, 
  errorLogs, 
  performanceLogs 
}: MonitoringDashboardProps) {
  const [activeTab, setActiveTab] = useState('overview')

  // Calculate metrics
  const totalLogs = recentLogs.length
  const errorCount = errorLogs.length
  const performanceCount = performanceLogs.length
  
  // Get error rate
  const errorRate = totalLogs > 0 ? (errorCount / totalLogs) * 100 : 0
  
  // Get recent errors (last 24 hours)
  const oneDayAgo = new Date()
  oneDayAgo.setDate(oneDayAgo.getDate() - 1)
  
  const recentErrors = errorLogs.filter(log => 
    new Date(log.created_at) >= oneDayAgo
  )
  
  // Get performance metrics
  const avgPerformance = performanceLogs.length > 0 
    ? performanceLogs.reduce((sum, log) => sum + (log.meta?.duration || 0), 0) / performanceLogs.length
    : 0

  const tabs = [
    { id: 'overview', name: 'Overview', icon: '📊' },
    { id: 'logs', name: 'Logs', icon: '📝' },
    { id: 'errors', name: 'Errors', icon: '🚨' },
    { id: 'performance', name: 'Performance', icon: '⚡' },
  ]

  return (
    <div className="space-y-8">
      {/* Tab Navigation */}
      <div className="bg-white rounded-lg shadow">
        <div className="border-b border-gray-200">
          <nav className="-mb-px flex space-x-8 px-6">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`py-4 px-1 border-b-2 font-medium text-sm ${
                  activeTab === tab.id
                    ? 'border-red-500 text-red-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                {tab.icon} {tab.name}
              </button>
            ))}
          </nav>
        </div>

        <div className="p-6">
          {/* Overview Tab */}
          {activeTab === 'overview' && (
            <div className="space-y-8">
              {/* Key Metrics */}
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <div className="bg-blue-50 rounded-lg p-6">
                  <div className="flex items-center">
                    <div className="flex-shrink-0">
                      <div className="w-8 h-8 bg-blue-500 rounded-md flex items-center justify-center">
                        <span className="text-white text-sm font-medium">📝</span>
                      </div>
                    </div>
                    <div className="ml-4">
                      <p className="text-sm font-medium text-blue-600">Total Logs</p>
                      <p className="text-2xl font-bold text-blue-900">{totalLogs}</p>
                    </div>
                  </div>
                </div>

                <div className="bg-red-50 rounded-lg p-6">
                  <div className="flex items-center">
                    <div className="flex-shrink-0">
                      <div className="w-8 h-8 bg-red-500 rounded-md flex items-center justify-center">
                        <span className="text-white text-sm font-medium">🚨</span>
                      </div>
                    </div>
                    <div className="ml-4">
                      <p className="text-sm font-medium text-red-600">Errors</p>
                      <p className="text-2xl font-bold text-red-900">{errorCount}</p>
                    </div>
                  </div>
                </div>

                <div className="bg-yellow-50 rounded-lg p-6">
                  <div className="flex items-center">
                    <div className="flex-shrink-0">
                      <div className="w-8 h-8 bg-yellow-500 rounded-md flex items-center justify-center">
                        <span className="text-white text-sm font-medium">📈</span>
                      </div>
                    </div>
                    <div className="ml-4">
                      <p className="text-sm font-medium text-yellow-600">Error Rate</p>
                      <p className="text-2xl font-bold text-yellow-900">{errorRate.toFixed(1)}%</p>
                    </div>
                  </div>
                </div>

                <div className="bg-green-50 rounded-lg p-6">
                  <div className="flex items-center">
                    <div className="flex-shrink-0">
                      <div className="w-8 h-8 bg-green-500 rounded-md flex items-center justify-center">
                        <span className="text-white text-sm font-medium">⚡</span>
                      </div>
                    </div>
                    <div className="ml-4">
                      <p className="text-sm font-medium text-green-600">Avg Performance</p>
                      <p className="text-2xl font-bold text-green-900">{Math.round(avgPerformance)}ms</p>
                    </div>
                  </div>
                </div>
              </div>

              {/* System Status */}
              <div className="bg-white border border-gray-200 rounded-lg p-6">
                <h3 className="text-lg font-medium text-gray-900 mb-4">System Status</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <h4 className="text-sm font-medium text-gray-700 mb-2">Database</h4>
                    <div className="flex items-center">
                      <div className="w-3 h-3 bg-green-500 rounded-full mr-2"></div>
                      <span className="text-sm text-gray-900">Connected</span>
                    </div>
                  </div>
                  
                  <div>
                    <h4 className="text-sm font-medium text-gray-700 mb-2">Redis</h4>
                    <div className="flex items-center">
                      <div className="w-3 h-3 bg-green-500 rounded-full mr-2"></div>
                      <span className="text-sm text-gray-900">Connected</span>
                    </div>
                  </div>
                  
                  <div>
                    <h4 className="text-sm font-medium text-gray-700 mb-2">Storage</h4>
                    <div className="flex items-center">
                      <div className="w-3 h-3 bg-green-500 rounded-full mr-2"></div>
                      <span className="text-sm text-gray-900">Available</span>
                    </div>
                  </div>
                  
                  <div>
                    <h4 className="text-sm font-medium text-gray-700 mb-2">Monitoring</h4>
                    <div className="flex items-center">
                      <div className="w-3 h-3 bg-green-500 rounded-full mr-2"></div>
                      <span className="text-sm text-gray-900">Active</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Recent Activity */}
              <div className="bg-white border border-gray-200 rounded-lg p-6">
                <h3 className="text-lg font-medium text-gray-900 mb-4">Recent Activity</h3>
                <div className="space-y-3">
                  {recentLogs.slice(0, 5).map((log) => (
                    <div key={log.id} className="flex items-center justify-between py-2 border-b border-gray-100">
                      <div className="flex items-center">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium mr-3 ${
                          log.level === 'error' 
                            ? 'bg-red-100 text-red-800'
                            : log.level === 'warn'
                            ? 'bg-yellow-100 text-yellow-800'
                            : log.level === 'info'
                            ? 'bg-blue-100 text-blue-800'
                            : 'bg-gray-100 text-gray-800'
                        }`}>
                          {log.level}
                        </span>
                        <span className="text-sm text-gray-900">{log.message}</span>
                      </div>
                      <span className="text-xs text-gray-500">
                        {new Date(log.created_at).toLocaleTimeString()}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* Logs Tab */}
          {activeTab === 'logs' && (
            <div className="space-y-4">
              {recentLogs.map((log) => (
                <div key={log.id} className="border border-gray-200 rounded-lg p-4">
                  <div className="flex justify-between items-start mb-2">
                    <div className="flex items-center">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium mr-3 ${
                        log.level === 'error' 
                          ? 'bg-red-100 text-red-800'
                          : log.level === 'warn'
                          ? 'bg-yellow-100 text-yellow-800'
                          : log.level === 'info'
                          ? 'bg-blue-100 text-blue-800'
                          : 'bg-gray-100 text-gray-800'
                      }`}>
                        {log.level}
                      </span>
                      <span className="text-sm font-medium text-gray-900">{log.message}</span>
                    </div>
                    <span className="text-xs text-gray-500">
                      {new Date(log.created_at).toLocaleString()}
                    </span>
                  </div>
                  {log.meta && (
                    <pre className="text-xs text-gray-600 bg-gray-50 p-2 rounded mt-2 overflow-auto">
                      {JSON.stringify(log.meta, null, 2)}
                    </pre>
                  )}
                </div>
              ))}
            </div>
          )}

          {/* Errors Tab */}
          {activeTab === 'errors' && (
            <div className="space-y-4">
              {errorLogs.map((log) => (
                <div key={log.id} className="border border-red-200 rounded-lg p-4 bg-red-50">
                  <div className="flex justify-between items-start mb-2">
                    <div>
                      <span className="text-sm font-medium text-red-900">{log.message}</span>
                    </div>
                    <span className="text-xs text-red-600">
                      {new Date(log.created_at).toLocaleString()}
                    </span>
                  </div>
                  {log.meta && (
                    <pre className="text-xs text-red-700 bg-red-100 p-2 rounded mt-2 overflow-auto">
                      {JSON.stringify(log.meta, null, 2)}
                    </pre>
                  )}
                </div>
              ))}
            </div>
          )}

          {/* Performance Tab */}
          {activeTab === 'performance' && (
            <div className="space-y-4">
              {performanceLogs.map((log) => (
                <div key={log.id} className="border border-gray-200 rounded-lg p-4">
                  <div className="flex justify-between items-start mb-2">
                    <div>
                      <span className="text-sm font-medium text-gray-900">{log.message}</span>
                      <span className="text-sm text-gray-600 ml-2">
                        ({log.meta?.operation || 'Unknown operation'})
                      </span>
                    </div>
                    <div className="text-right">
                      <span className="text-sm font-medium text-gray-900">
                        {log.meta?.duration || 0}ms
                      </span>
                      <div className="text-xs text-gray-500">
                        {new Date(log.created_at).toLocaleString()}
                      </div>
                    </div>
                  </div>
                  {log.meta && (
                    <pre className="text-xs text-gray-600 bg-gray-50 p-2 rounded mt-2 overflow-auto">
                      {JSON.stringify(log.meta, null, 2)}
                    </pre>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

