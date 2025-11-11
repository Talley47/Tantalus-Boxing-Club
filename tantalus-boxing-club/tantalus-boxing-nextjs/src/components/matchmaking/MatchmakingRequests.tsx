import { MatchmakingRequest } from '@/types'

interface MatchmakingRequestsProps {
  requests: MatchmakingRequest[]
}

export function MatchmakingRequests({ requests }: MatchmakingRequestsProps) {
  if (requests.length === 0) {
    return (
      <div className="text-center py-8">
        <div className="text-gray-400 mb-4">
          <svg className="mx-auto h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
        </div>
        <h3 className="text-lg font-medium text-gray-900 mb-2">No Matchmaking Requests</h3>
        <p className="text-gray-500">Submit a matchmaking request to find your next opponent.</p>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {requests.map((request) => (
        <div key={request.id} className="border border-gray-200 rounded-lg p-4">
          <div className="flex justify-between items-start mb-2">
            <div>
              <h3 className="text-sm font-medium text-gray-900">
                {request.weight_class} - {request.tier}
              </h3>
              <p className="text-sm text-gray-500">
                Max Distance: {request.max_distance} miles
              </p>
            </div>
            <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
              request.status === 'pending' 
                ? 'bg-yellow-100 text-yellow-800'
                : request.status === 'matched'
                ? 'bg-green-100 text-green-800'
                : 'bg-gray-100 text-gray-800'
            }`}>
              {request.status}
            </span>
          </div>
          
          {request.preferred_date && (
            <p className="text-sm text-gray-600 mb-2">
              Preferred Date: {new Date(request.preferred_date).toLocaleDateString()}
            </p>
          )}
          
          {request.notes && (
            <p className="text-sm text-gray-600 mb-2">
              Notes: {request.notes}
            </p>
          )}
          
          <p className="text-xs text-gray-400">
            Submitted: {new Date(request.created_at).toLocaleDateString()}
          </p>
        </div>
      ))}
    </div>
  )
}