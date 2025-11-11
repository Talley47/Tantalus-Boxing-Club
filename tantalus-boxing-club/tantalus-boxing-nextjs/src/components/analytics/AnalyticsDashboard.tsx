'use client'

import { useState } from 'react'
import { FighterProfile, FightRecord, TrainingLog, Tournament } from '@/types'

interface AnalyticsDashboardProps {
  fighterProfile: FighterProfile
  fightRecords: FightRecord[]
  trainingLogs: TrainingLog[]
  allFighters: FighterProfile[]
  allFightRecords: FightRecord[]
  tournaments: Tournament[]
}

export function AnalyticsDashboard({ 
  fighterProfile, 
  fightRecords, 
  trainingLogs, 
  allFighters, 
  allFightRecords, 
  tournaments 
}: AnalyticsDashboardProps) {
  const [activeTab, setActiveTab] = useState('personal')

  // Calculate personal analytics
  const totalFights = fightRecords.length
  const wins = fightRecords.filter(f => f.result === 'Win').length
  const losses = fightRecords.filter(f => f.result === 'Loss').length
  const draws = fightRecords.filter(f => f.result === 'Draw').length
  const winPercentage = totalFights > 0 ? (wins / totalFights) * 100 : 0

  const totalTrainingMinutes = trainingLogs.reduce((sum, log) => sum + log.duration_minutes, 0)
  const averageTrainingPerSession = trainingLogs.length > 0 ? totalTrainingMinutes / trainingLogs.length : 0

  // Recent performance (last 10 fights)
  const recentFights = fightRecords.slice(0, 10)
  const recentWins = recentFights.filter(f => f.result === 'Win').length
  const recentWinPercentage = recentFights.length > 0 ? (recentWins / recentFights.length) * 100 : 0

  // Training frequency (last 30 days)
  const thirtyDaysAgo = new Date()
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
  
  const recentTrainingLogs = trainingLogs.filter(log => 
    new Date(log.date) >= thirtyDaysAgo
  )

  // League analytics
  const totalLeagueFighters = allFighters.length
  const totalLeagueFights = allFightRecords.length
  const totalLeagueTournaments = tournaments.length

  // Tier distribution
  const tierDistribution = allFighters.reduce((acc, fighter) => {
    acc[fighter.tier] = (acc[fighter.tier] || 0) + 1
    return acc
  }, {} as Record<string, number>)

  // Weight class distribution
  const weightClassDistribution = allFighters.reduce((acc, fighter) => {
    acc[fighter.weight_class] = (acc[fighter.weight_class] || 0) + 1
    return acc
  }, {} as Record<string, number>)

  const tabs = [
    { id: 'personal', name: 'Personal Analytics', icon: '👤' },
    { id: 'league', name: 'League Analytics', icon: '🏆' },
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
          {/* Personal Analytics Tab */}
          {activeTab === 'personal' && (
            <div className="space-y-8">
              {/* Key Metrics */}
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <div className="bg-blue-50 rounded-lg p-6">
                  <div className="flex items-center">
                    <div className="flex-shrink-0">
                      <div className="w-8 h-8 bg-blue-500 rounded-md flex items-center justify-center">
                        <span className="text-white text-sm font-medium">W</span>
                      </div>
                    </div>
                    <div className="ml-4">
                      <p className="text-sm font-medium text-blue-600">Wins</p>
                      <p className="text-2xl font-bold text-blue-900">{wins}</p>
                    </div>
                  </div>
                </div>

                <div className="bg-red-50 rounded-lg p-6">
                  <div className="flex items-center">
                    <div className="flex-shrink-0">
                      <div className="w-8 h-8 bg-red-500 rounded-md flex items-center justify-center">
                        <span className="text-white text-sm font-medium">L</span>
                      </div>
                    </div>
                    <div className="ml-4">
                      <p className="text-sm font-medium text-red-600">Losses</p>
                      <p className="text-2xl font-bold text-red-900">{losses}</p>
                    </div>
                  </div>
                </div>

                <div className="bg-green-50 rounded-lg p-6">
                  <div className="flex items-center">
                    <div className="flex-shrink-0">
                      <div className="w-8 h-8 bg-green-500 rounded-md flex items-center justify-center">
                        <span className="text-white text-sm font-medium">%</span>
                      </div>
                    </div>
                    <div className="ml-4">
                      <p className="text-sm font-medium text-green-600">Win Rate</p>
                      <p className="text-2xl font-bold text-green-900">{Math.round(winPercentage)}%</p>
                    </div>
                  </div>
                </div>

                <div className="bg-purple-50 rounded-lg p-6">
                  <div className="flex items-center">
                    <div className="flex-shrink-0">
                      <div className="w-8 h-8 bg-purple-500 rounded-md flex items-center justify-center">
                        <span className="text-white text-sm font-medium">P</span>
                      </div>
                    </div>
                    <div className="ml-4">
                      <p className="text-sm font-medium text-purple-600">Points</p>
                      <p className="text-2xl font-bold text-purple-900">{fighterProfile.points}</p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Performance Charts */}
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                {/* Win/Loss Chart */}
                <div className="bg-white border border-gray-200 rounded-lg p-6">
                  <h3 className="text-lg font-medium text-gray-900 mb-4">Fight Record</h3>
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-600">Wins</span>
                      <div className="flex items-center">
                        <div className="w-32 bg-gray-200 rounded-full h-2 mr-3">
                          <div 
                            className="bg-green-500 h-2 rounded-full" 
                            style={{ width: `${totalFights > 0 ? (wins / totalFights) * 100 : 0}%` }}
                          />
                        </div>
                        <span className="text-sm font-medium text-gray-900">{wins}</span>
                      </div>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-600">Losses</span>
                      <div className="flex items-center">
                        <div className="w-32 bg-gray-200 rounded-full h-2 mr-3">
                          <div 
                            className="bg-red-500 h-2 rounded-full" 
                            style={{ width: `${totalFights > 0 ? (losses / totalFights) * 100 : 0}%` }}
                          />
                        </div>
                        <span className="text-sm font-medium text-gray-900">{losses}</span>
                      </div>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-600">Draws</span>
                      <div className="flex items-center">
                        <div className="w-32 bg-gray-200 rounded-full h-2 mr-3">
                          <div 
                            className="bg-yellow-500 h-2 rounded-full" 
                            style={{ width: `${totalFights > 0 ? (draws / totalFights) * 100 : 0}%` }}
                          />
                        </div>
                        <span className="text-sm font-medium text-gray-900">{draws}</span>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Training Stats */}
                <div className="bg-white border border-gray-200 rounded-lg p-6">
                  <h3 className="text-lg font-medium text-gray-900 mb-4">Training Statistics</h3>
                  <div className="space-y-4">
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Total Training Time</span>
                      <span className="text-sm font-medium text-gray-900">
                        {Math.round(totalTrainingMinutes / 60)} hours
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Average Session</span>
                      <span className="text-sm font-medium text-gray-900">
                        {Math.round(averageTrainingPerSession)} minutes
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Recent Sessions (30 days)</span>
                      <span className="text-sm font-medium text-gray-900">
                        {recentTrainingLogs.length}
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Recent Performance */}
              <div className="bg-white border border-gray-200 rounded-lg p-6">
                <h3 className="text-lg font-medium text-gray-900 mb-4">Recent Performance</h3>
                <div className="space-y-2">
                  {recentFights.slice(0, 5).map((fight) => (
                    <div key={fight.id} className="flex items-center justify-between py-2 border-b border-gray-100">
                      <div>
                        <span className="text-sm font-medium text-gray-900">vs {fight.opponent_name}</span>
                        <span className="text-sm text-gray-500 ml-2">
                          {new Date(fight.date).toLocaleDateString()}
                        </span>
                      </div>
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        fight.result === 'Win' 
                          ? 'bg-green-100 text-green-800'
                          : fight.result === 'Loss'
                          ? 'bg-red-100 text-red-800'
                          : 'bg-yellow-100 text-yellow-800'
                      }`}>
                        {fight.result} ({fight.method})
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* League Analytics Tab */}
          {activeTab === 'league' && (
            <div className="space-y-8">
              {/* League Overview */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-blue-50 rounded-lg p-6">
                  <div className="flex items-center">
                    <div className="flex-shrink-0">
                      <div className="w-8 h-8 bg-blue-500 rounded-md flex items-center justify-center">
                        <span className="text-white text-sm font-medium">👥</span>
                      </div>
                    </div>
                    <div className="ml-4">
                      <p className="text-sm font-medium text-blue-600">Total Fighters</p>
                      <p className="text-2xl font-bold text-blue-900">{totalLeagueFighters}</p>
                    </div>
                  </div>
                </div>

                <div className="bg-green-50 rounded-lg p-6">
                  <div className="flex items-center">
                    <div className="flex-shrink-0">
                      <div className="w-8 h-8 bg-green-500 rounded-md flex items-center justify-center">
                        <span className="text-white text-sm font-medium">🥊</span>
                      </div>
                    </div>
                    <div className="ml-4">
                      <p className="text-sm font-medium text-green-600">Total Fights</p>
                      <p className="text-2xl font-bold text-green-900">{totalLeagueFights}</p>
                    </div>
                  </div>
                </div>

                <div className="bg-purple-50 rounded-lg p-6">
                  <div className="flex items-center">
                    <div className="flex-shrink-0">
                      <div className="w-8 h-8 bg-purple-500 rounded-md flex items-center justify-center">
                        <span className="text-white text-sm font-medium">🏆</span>
                      </div>
                    </div>
                    <div className="ml-4">
                      <p className="text-sm font-medium text-purple-600">Tournaments</p>
                      <p className="text-2xl font-bold text-purple-900">{totalLeagueTournaments}</p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Tier Distribution */}
              <div className="bg-white border border-gray-200 rounded-lg p-6">
                <h3 className="text-lg font-medium text-gray-900 mb-4">Tier Distribution</h3>
                <div className="space-y-3">
                  {Object.entries(tierDistribution).map(([tier, count]) => (
                    <div key={tier} className="flex items-center justify-between">
                      <span className="text-sm text-gray-600">{tier}</span>
                      <div className="flex items-center">
                        <div className="w-32 bg-gray-200 rounded-full h-2 mr-3">
                          <div 
                            className="bg-red-500 h-2 rounded-full" 
                            style={{ width: `${(count / totalLeagueFighters) * 100}%` }}
                          />
                        </div>
                        <span className="text-sm font-medium text-gray-900">{count}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Weight Class Distribution */}
              <div className="bg-white border border-gray-200 rounded-lg p-6">
                <h3 className="text-lg font-medium text-gray-900 mb-4">Weight Class Distribution</h3>
                <div className="space-y-3">
                  {Object.entries(weightClassDistribution).map(([weightClass, count]) => (
                    <div key={weightClass} className="flex items-center justify-between">
                      <span className="text-sm text-gray-600">{weightClass}</span>
                      <div className="flex items-center">
                        <div className="w-32 bg-gray-200 rounded-full h-2 mr-3">
                          <div 
                            className="bg-blue-500 h-2 rounded-full" 
                            style={{ width: `${(count / totalLeagueFighters) * 100}%` }}
                          />
                        </div>
                        <span className="text-sm font-medium text-gray-900">{count}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Top Fighters */}
              <div className="bg-white border border-gray-200 rounded-lg p-6">
                <h3 className="text-lg font-medium text-gray-900 mb-4">Top Fighters</h3>
                <div className="space-y-3">
                  {allFighters.slice(0, 10).map((fighter, index) => (
                    <div key={fighter.id} className="flex items-center justify-between py-2 border-b border-gray-100">
                      <div className="flex items-center">
                        <span className="text-sm font-medium text-gray-900 mr-3">#{index + 1}</span>
                        <div>
                          <span className="text-sm font-medium text-gray-900">{fighter.name}</span>
                          <span className="text-sm text-gray-500 ml-2">({fighter.tier})</span>
                        </div>
                      </div>
                      <div className="text-right">
                        <span className="text-sm font-medium text-gray-900">{fighter.points} pts</span>
                        <div className="text-xs text-gray-500">
                          {fighter.wins}-{fighter.losses}-{fighter.draws}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

