import { FighterProfile } from '@/types'

interface FighterDashboardProps {
  fighterProfile: FighterProfile
}

export function FighterDashboard({ fighterProfile }: FighterDashboardProps) {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      {/* Fighter Stats */}
      <div className="lg:col-span-2">
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Fighter Statistics</h2>
          
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600">{fighterProfile.wins}</div>
              <div className="text-sm text-gray-600">Wins</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-red-600">{fighterProfile.losses}</div>
              <div className="text-sm text-gray-600">Losses</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-yellow-600">{fighterProfile.draws}</div>
              <div className="text-sm text-gray-600">Draws</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600">{fighterProfile.points}</div>
              <div className="text-sm text-gray-600">Points</div>
            </div>
          </div>
          
          <div className="mt-6">
            <div className="flex justify-between items-center mb-2">
              <span className="text-sm font-medium text-gray-700">Win Percentage</span>
              <span className="text-sm font-medium text-gray-900">
                {fighterProfile.win_percentage}%
              </span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-2">
              <div 
                className="bg-green-600 h-2 rounded-full" 
                style={{ width: `${fighterProfile.win_percentage}%` }}
              />
            </div>
          </div>
        </div>
      </div>
      
      {/* Fighter Info */}
      <div className="space-y-6">
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Fighter Information</h3>
          
          <div className="space-y-3">
            <div>
              <span className="text-sm font-medium text-gray-500">Name:</span>
              <p className="text-sm text-gray-900">{fighterProfile.name}</p>
            </div>
            <div>
              <span className="text-sm font-medium text-gray-500">Handle:</span>
              <p className="text-sm text-gray-900">@{fighterProfile.handle}</p>
            </div>
            <div>
              <span className="text-sm font-medium text-gray-500">Tier:</span>
              <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                {fighterProfile.tier}
              </span>
            </div>
            <div>
              <span className="text-sm font-medium text-gray-500">Weight Class:</span>
              <p className="text-sm text-gray-900">{fighterProfile.weight_class}</p>
            </div>
            <div>
              <span className="text-sm font-medium text-gray-500">Stance:</span>
              <p className="text-sm text-gray-900">{fighterProfile.stance}</p>
            </div>
            <div>
              <span className="text-sm font-medium text-gray-500">Hometown:</span>
              <p className="text-sm text-gray-900">{fighterProfile.hometown}</p>
            </div>
          </div>
        </div>
        
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Physical Stats</h3>
          
          <div className="space-y-3">
            <div>
              <span className="text-sm font-medium text-gray-500">Height:</span>
              <p className="text-sm text-gray-900">
                {Math.floor(fighterProfile.height / 30.48)}' {Math.round((fighterProfile.height % 30.48) / 2.54)}"
              </p>
            </div>
            <div>
              <span className="text-sm font-medium text-gray-500">Weight:</span>
              <p className="text-sm text-gray-900">
                {Math.round(fighterProfile.weight * 2.20462)} lbs
              </p>
            </div>
            <div>
              <span className="text-sm font-medium text-gray-500">Reach:</span>
              <p className="text-sm text-gray-900">
                {Math.round(fighterProfile.reach / 2.54)}"
              </p>
            </div>
            <div>
              <span className="text-sm font-medium text-gray-500">Age:</span>
              <p className="text-sm text-gray-900">{fighterProfile.age}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

