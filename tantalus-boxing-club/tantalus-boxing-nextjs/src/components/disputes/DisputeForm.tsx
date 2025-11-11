'use client'

import { useState } from 'react'
import { createDispute } from '@/lib/actions/admin'

interface DisputeFormProps {
  userDisputes: any[]
}

export function DisputeForm({ userDisputes }: DisputeFormProps) {
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  const handleSubmitDispute = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setIsSubmitting(true)
    setMessage(null)

    const formData = new FormData(e.currentTarget)
    const result = await createDispute(formData)

    if (result?.error) {
      setMessage({ type: 'error', text: result.error })
    } else if (result?.success) {
      setMessage({ type: 'success', text: result.message })
      e.currentTarget.reset()
      window.location.reload()
    }

    setIsSubmitting(false)
  }

  return (
    <div className="space-y-8">
      {/* Create Dispute Form */}
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-semibold text-gray-900 mb-6">Submit a Dispute</h2>
        
        {message && (
          <div className={`p-4 rounded-md mb-6 ${
            message.type === 'success' 
              ? 'bg-green-50 text-green-800 border border-green-200' 
              : 'bg-red-50 text-red-800 border border-red-200'
          }`}>
            {message.text}
          </div>
        )}

        <form onSubmit={handleSubmitDispute} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label htmlFor="title" className="block text-sm font-medium text-gray-700 mb-2">
                Dispute Title
              </label>
              <input
                id="title"
                name="title"
                type="text"
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                placeholder="Brief title for your dispute"
              />
            </div>

            <div>
              <label htmlFor="category" className="block text-sm font-medium text-gray-700 mb-2">
                Category
              </label>
              <select
                id="category"
                name="category"
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
              >
                <option value="">Select category...</option>
                <option value="fight_result">Fight Result</option>
                <option value="points">Points/Scoring</option>
                <option value="behavior">User Behavior</option>
                <option value="technical">Technical Issue</option>
                <option value="other">Other</option>
              </select>
            </div>
          </div>

          <div>
            <label htmlFor="description" className="block text-sm font-medium text-gray-700 mb-2">
              Description
            </label>
            <textarea
              id="description"
              name="description"
              rows={4}
              required
              className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
              placeholder="Please provide a detailed description of your dispute..."
            />
          </div>

          <div>
            <label htmlFor="relatedFightId" className="block text-sm font-medium text-gray-700 mb-2">
              Related Fight ID (Optional)
            </label>
            <input
              id="relatedFightId"
              name="relatedFightId"
              type="text"
              className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
              placeholder="Enter fight ID if this dispute is related to a specific fight"
            />
          </div>

          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full bg-red-600 text-white py-2 px-4 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isSubmitting ? 'Submitting...' : 'Submit Dispute'}
          </button>
        </form>
      </div>

      {/* User's Disputes */}
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-semibold text-gray-900 mb-6">Your Disputes</h2>
        
        <div className="space-y-4">
          {userDisputes.map((dispute) => (
            <div key={dispute.id} className="border border-gray-200 rounded-lg p-4">
              <div className="flex justify-between items-start mb-2">
                <h3 className="text-sm font-medium text-gray-900">{dispute.title}</h3>
                <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                  dispute.status === 'pending' 
                    ? 'bg-yellow-100 text-yellow-800'
                    : dispute.status === 'in_review'
                    ? 'bg-blue-100 text-blue-800'
                    : dispute.status === 'resolved'
                    ? 'bg-green-100 text-green-800'
                    : 'bg-red-100 text-red-800'
                }`}>
                  {dispute.status.replace('_', ' ').toUpperCase()}
                </span>
              </div>
              
              <p className="text-sm text-gray-600 mb-2">{dispute.description}</p>
              
              <div className="flex justify-between items-center text-xs text-gray-500">
                <span>Category: {dispute.category.replace('_', ' ').toUpperCase()}</span>
                <span>{new Date(dispute.created_at).toLocaleDateString()}</span>
              </div>

              {dispute.fight && (
                <div className="mt-2 p-2 bg-gray-50 rounded text-xs">
                  Related Fight: vs {dispute.fight.opponent_name} ({dispute.fight.result})
                </div>
              )}

              {dispute.status === 'resolved' && dispute.resolution && (
                <div className="mt-3 p-3 bg-green-50 rounded-lg">
                  <p className="text-sm font-medium text-green-800">Resolution:</p>
                  <p className="text-sm text-green-700">{dispute.resolution}</p>
                  {dispute.admin_notes && (
                    <p className="text-xs text-green-600 mt-1">Admin Notes: {dispute.admin_notes}</p>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>

        {userDisputes.length === 0 && (
          <div className="text-center py-8">
            <div className="text-gray-400 mb-4">
              <svg className="mx-auto h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">No Disputes Yet</h3>
            <p className="text-gray-500">You haven't submitted any disputes yet.</p>
          </div>
        )}
      </div>
    </div>
  )
}

