'use client'

import { useState } from 'react'
import { requestMatchmaking } from '@/lib/actions/fighter'
import { FighterProfile } from '@/types'

interface MatchmakingFormProps {
  fighterProfile: FighterProfile
}

export function MatchmakingForm({ fighterProfile }: MatchmakingFormProps) {
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setIsSubmitting(true)
    setMessage(null)

    const formData = new FormData(e.currentTarget)
    const result = await requestMatchmaking(formData)

    if (result?.error) {
      setMessage({ type: 'error', text: result.error })
    } else if (result?.success) {
      setMessage({ type: 'success', text: result.message })
      // Reset form
      e.currentTarget.reset()
    }

    setIsSubmitting(false)
  }

  const weightClasses = [
    'Flyweight',
    'Bantamweight', 
    'Featherweight',
    'Lightweight',
    'Welterweight',
    'Middleweight',
    'Light Heavyweight',
    'Cruiserweight',
    'Heavyweight'
  ]

  const tiers = [
    'Amateur',
    'Semi-Pro',
    'Pro',
    'Contender',
    'Elite',
    'Champion'
  ]

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {message && (
        <div className={`p-4 rounded-md ${
          message.type === 'success' 
            ? 'bg-green-50 text-green-800 border border-green-200' 
            : 'bg-red-50 text-red-800 border border-red-200'
        }`}>
          {message.text}
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <label htmlFor="weightClass" className="block text-sm font-medium text-gray-700 mb-2">
            Weight Class
          </label>
          <select
            id="weightClass"
            name="weightClass"
            required
            defaultValue={fighterProfile.weight_class}
            className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
          >
            {weightClasses.map(weightClass => (
              <option key={weightClass} value={weightClass}>{weightClass}</option>
            ))}
          </select>
        </div>

        <div>
          <label htmlFor="tier" className="block text-sm font-medium text-gray-700 mb-2">
            Preferred Tier
          </label>
          <select
            id="tier"
            name="tier"
            required
            defaultValue={fighterProfile.tier}
            className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
          >
            {tiers.map(tier => (
              <option key={tier} value={tier}>{tier}</option>
            ))}
          </select>
        </div>

        <div>
          <label htmlFor="maxDistance" className="block text-sm font-medium text-gray-700 mb-2">
            Max Distance (miles)
          </label>
          <input
            id="maxDistance"
            name="maxDistance"
            type="number"
            min="1"
            max="1000"
            required
            defaultValue="50"
            className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
            placeholder="Enter maximum distance"
          />
        </div>

        <div>
          <label htmlFor="preferredDate" className="block text-sm font-medium text-gray-700 mb-2">
            Preferred Date (Optional)
          </label>
          <input
            id="preferredDate"
            name="preferredDate"
            type="date"
            className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
          />
        </div>
      </div>

      <div>
        <label htmlFor="notes" className="block text-sm font-medium text-gray-700 mb-2">
          Additional Notes (Optional)
        </label>
        <textarea
          id="notes"
          name="notes"
          rows={3}
          className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
          placeholder="Enter any additional information about your matchmaking preferences"
        />
      </div>

      <button
        type="submit"
        disabled={isSubmitting}
        className="w-full bg-red-600 text-white py-2 px-4 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {isSubmitting ? 'Submitting Request...' : 'Submit Matchmaking Request'}
      </button>
    </form>
  )
}