'use client'

import { useState } from 'react'
import { Tournament, FighterProfile } from '@/types'
import { joinTournament, leaveTournament } from '@/lib/actions/tournaments'

interface TournamentListProps {
  tournaments: Tournament[]
  userTournamentIds: string[]
  fighterProfile: FighterProfile
}

export function TournamentList({ tournaments, userTournamentIds, fighterProfile }: TournamentListProps) {
  const [loading, setLoading] = useState<string | null>(null)
  const [message, setMessage] = useState<{ type: 'success' | 'error', text: string } | null>(null)

  const handleJoinTournament = async (tournamentId: string) => {
    setLoading(tournamentId)
    setMessage(null)

    const result = await joinTournament(tournamentId)

    if (result?.error) {
      setMessage({ type: 'error', text: result.error })
    } else if (result?.success) {
      setMessage({ type: 'success', text: result.message })
      // Refresh the page to update the list
      window.location.reload()
    }

    setLoading(null)
  }

  const handleLeaveTournament = async (tournamentId: string) => {
    setLoading(tournamentId)
    setMessage(null)

    const result = await leaveTournament(tournamentId)

    if (result?.error) {
      setMessage({ type: 'error', text: result.error })
    } else if (result?.success) {
      setMessage({ type: 'success', text: result.message })
      // Refresh the page to update the list
      window.location.reload()
    }

    setLoading(null)
  }

  if (tournaments.length === 0) {
    return (
      <div className="text-center py-8">
        <div className="text-gray-400 mb-4">
          <svg className="mx-auto h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
          </svg>
        </div>
        <h3 className="text-lg font-medium text-gray-900 mb-2">No Tournaments Available</h3>
        <p className="text-gray-500">Create a tournament to get started</p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {message && (
        <div className={`p-4 rounded-md ${
          message.type === 'success' 
            ? 'bg-green-50 text-green-800 border border-green-200' 
            : 'bg-red-50 text-red-800 border border-red-200'
        }`}>
          {message.text}
        </div>
      )}

      {tournaments.map((tournament) => {
        const isJoined = userTournamentIds.includes(tournament.id)
        const canJoin = tournament.status === 'upcoming' && 
                       tournament.current_participants < tournament.max_participants &&
                       tournament.weight_class === fighterProfile.weight_class &&
                       !isJoined

        return (
          <div key={tournament.id} className="bg-white rounded-lg shadow p-6">
            <div className="flex justify-between items-start mb-4">
              <div>
                <h3 className="text-xl font-semibold text-gray-900">{tournament.name}</h3>
                {tournament.description && (
                  <p className="text-gray-600 mt-1">{tournament.description}</p>
                )}
              </div>
              <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                tournament.status === 'upcoming' 
                  ? 'bg-blue-100 text-blue-800'
                  : tournament.status === 'active'
                  ? 'bg-green-100 text-green-800'
                  : tournament.status === 'completed'
                  ? 'bg-gray-100 text-gray-800'
                  : 'bg-red-100 text-red-800'
              }`}>
                {tournament.status}
              </span>
            </div>

            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-4">
              <div>
                <span className="text-sm font-medium text-gray-500">Weight Class</span>
                <p className="text-sm text-gray-900">{tournament.weight_class}</p>
              </div>
              <div>
                <span className="text-sm font-medium text-gray-500">Participants</span>
                <p className="text-sm text-gray-900">
                  {tournament.current_participants} / {tournament.max_participants}
                </p>
              </div>
              <div>
                <span className="text-sm font-medium text-gray-500">Entry Fee</span>
                <p className="text-sm text-gray-900">${tournament.entry_fee}</p>
              </div>
              <div>
                <span className="text-sm font-medium text-gray-500">Prize Pool</span>
                <p className="text-sm text-gray-900">${tournament.prize_pool}</p>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <div>
                <span className="text-sm font-medium text-gray-500">Start Date</span>
                <p className="text-sm text-gray-900">
                  {new Date(tournament.start_date).toLocaleDateString()}
                </p>
              </div>
              <div>
                <span className="text-sm font-medium text-gray-500">End Date</span>
                <p className="text-sm text-gray-900">
                  {new Date(tournament.end_date).toLocaleDateString()}
                </p>
              </div>
            </div>

            <div className="flex justify-between items-center">
              <div className="text-sm text-gray-500">
                Created: {new Date(tournament.created_at).toLocaleDateString()}
              </div>
              
              <div className="flex space-x-2">
                {isJoined ? (
                  <button
                    onClick={() => handleLeaveTournament(tournament.id)}
                    disabled={loading === tournament.id || tournament.status !== 'upcoming'}
                    className="px-4 py-2 text-sm font-medium text-red-600 bg-red-50 border border-red-200 rounded-md hover:bg-red-100 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {loading === tournament.id ? 'Leaving...' : 'Leave Tournament'}
                  </button>
                ) : (
                  <button
                    onClick={() => handleJoinTournament(tournament.id)}
                    disabled={loading === tournament.id || !canJoin}
                    className="px-4 py-2 text-sm font-medium text-white bg-red-600 border border-transparent rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {loading === tournament.id ? 'Joining...' : 'Join Tournament'}
                  </button>
                )}
              </div>
            </div>
          </div>
        )
      })}
    </div>
  )
}

