import { Tournament } from '@/types'
import Link from 'next/link'

interface TournamentsListProps {
  tournaments: Tournament[]
}

export function TournamentsList({ tournaments }: TournamentsListProps) {
  if (tournaments.length === 0) {
    return (
      <div className="bg-white rounded-lg shadow p-6">
        <div className="text-center py-8">
          <div className="text-gray-400 mb-4">
            <svg className="mx-auto h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">No Tournaments Available</h3>
          <p className="text-gray-500">Create a tournament to get started.</p>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {tournaments.map((tournament) => (
        <div key={tournament.id} className="bg-white rounded-lg shadow p-6">
          <div className="flex justify-between items-start mb-4">
            <div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">
                {tournament.name}
              </h3>
              <p className="text-gray-600 mb-2">
                {tournament.description || 'No description provided'}
              </p>
            </div>
            <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${
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
              Created by {tournament.creator?.full_name || 'Unknown'}
            </div>
            <Link
              href={`/tournaments/${tournament.id}`}
              className="bg-red-600 text-white px-4 py-2 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors"
            >
              View Details
            </Link>
          </div>
        </div>
      ))}
    </div>
  )
}

