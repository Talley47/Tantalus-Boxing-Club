import { FightRecord } from '@/types'

interface FightHistoryProps {
  fights: FightRecord[]
}

export function FightHistory({ fights }: FightHistoryProps) {
  if (fights.length === 0) {
    return (
      <div className="text-center py-8">
        <div className="text-gray-400 mb-4">
          <svg className="mx-auto h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
        </div>
        <h3 className="text-lg font-medium text-gray-900 mb-2">No Fight Records</h3>
        <p className="text-gray-500">Add your first fight record to get started.</p>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {fights.map((fight) => (
        <div key={fight.id} className="border border-gray-200 rounded-lg p-4">
          <div className="flex justify-between items-start mb-2">
            <div>
              <h3 className="text-sm font-medium text-gray-900">
                vs {fight.opponent_name}
              </h3>
              <p className="text-sm text-gray-500">
                {new Date(fight.date).toLocaleDateString()} • Round {fight.round}
              </p>
            </div>
            <div className="text-right">
              <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                fight.result === 'Win' 
                  ? 'bg-green-100 text-green-800'
                  : fight.result === 'Loss'
                  ? 'bg-red-100 text-red-800'
                  : 'bg-yellow-100 text-yellow-800'
              }`}>
                {fight.result}
              </span>
              <p className="text-xs text-gray-500 mt-1">
                {fight.method}
              </p>
            </div>
          </div>
          
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <span className="text-gray-500">Weight Class:</span>
              <p className="text-gray-900">{fight.weight_class}</p>
            </div>
            <div>
              <span className="text-gray-500">Points Earned:</span>
              <p className="text-gray-900">{fight.points_earned}</p>
            </div>
          </div>
          
          {fight.notes && (
            <div className="mt-3">
              <span className="text-sm text-gray-500">Notes:</span>
              <p className="text-sm text-gray-900">{fight.notes}</p>
            </div>
          )}
          
          {fight.proof_url && (
            <div className="mt-3">
              <a 
                href={fight.proof_url} 
                target="_blank" 
                rel="noopener noreferrer"
                className="text-sm text-red-600 hover:text-red-700"
              >
                View Proof →
              </a>
            </div>
          )}
        </div>
      ))}
    </div>
  )
}

