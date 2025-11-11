'use client'

import { useState } from 'react'
import { createFightRecord } from '@/lib/actions/fighter'
import { FighterProfile } from '@/types'

interface RecordEntryFormProps {
  fighterProfile: FighterProfile
}

export function RecordEntryForm({ fighterProfile }: RecordEntryFormProps) {
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setIsSubmitting(true)
    setMessage(null)

    const formData = new FormData(e.currentTarget)
    const result = await createFightRecord(formData)

    if (result?.error) {
      setMessage({ type: 'error', text: result.error })
    } else if (result?.success) {
      setMessage({ type: 'success', text: result.message })
      // Reset form
      e.currentTarget.reset()
      // Refresh the page to show updated fight history
      window.location.reload()
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

  const results = ['Win', 'Loss', 'Draw']
  const methods = ['UD', 'SD', 'MD', 'KO', 'TKO', 'Submission', 'DQ', 'No Contest']

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
          <label htmlFor="opponentName" className="block text-sm font-medium text-gray-700 mb-2">
            Opponent Name
          </label>
          <input
            id="opponentName"
            name="opponentName"
            type="text"
            required
            className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
            placeholder="Enter opponent's name"
          />
        </div>

        <div>
          <label htmlFor="result" className="block text-sm font-medium text-gray-700 mb-2">
            Result
          </label>
          <select
            id="result"
            name="result"
            required
            className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
          >
            {results.map(result => (
              <option key={result} value={result}>{result}</option>
            ))}
          </select>
        </div>

        <div>
          <label htmlFor="method" className="block text-sm font-medium text-gray-700 mb-2">
            Method
          </label>
          <select
            id="method"
            name="method"
            required
            className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
          >
            {methods.map(method => (
              <option key={method} value={method}>{method}</option>
            ))}
          </select>
        </div>

        <div>
          <label htmlFor="round" className="block text-sm font-medium text-gray-700 mb-2">
            Round
          </label>
          <input
            id="round"
            name="round"
            type="number"
            min="1"
            max="15"
            required
            className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
            placeholder="Enter round number"
          />
        </div>

        <div>
          <label htmlFor="date" className="block text-sm font-medium text-gray-700 mb-2">
            Fight Date
          </label>
          <input
            id="date"
            name="date"
            type="date"
            required
            className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
          />
        </div>

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
          <label htmlFor="pointsEarned" className="block text-sm font-medium text-gray-700 mb-2">
            Points Earned
          </label>
          <input
            id="pointsEarned"
            name="pointsEarned"
            type="number"
            min="0"
            required
            defaultValue="10"
            className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
            placeholder="Enter points earned"
          />
        </div>

        <div>
          <label htmlFor="proofUrl" className="block text-sm font-medium text-gray-700 mb-2">
            Proof URL (Optional)
          </label>
          <input
            id="proofUrl"
            name="proofUrl"
            type="url"
            className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
            placeholder="Enter proof URL (video, image, etc.)"
          />
        </div>
      </div>

      <div>
        <label htmlFor="notes" className="block text-sm font-medium text-gray-700 mb-2">
          Notes (Optional)
        </label>
        <textarea
          id="notes"
          name="notes"
          rows={3}
          className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
          placeholder="Enter any additional notes about the fight"
        />
      </div>

      <button
        type="submit"
        disabled={isSubmitting}
        className="w-full bg-red-600 text-white py-2 px-4 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {isSubmitting ? 'Adding Fight Record...' : 'Add Fight Record'}
      </button>
    </form>
  )
}

