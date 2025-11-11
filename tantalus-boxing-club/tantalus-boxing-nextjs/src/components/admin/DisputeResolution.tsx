'use client'

import { useState } from 'react'
import { resolveDispute } from '@/lib/actions/admin'

interface DisputeResolutionProps {
  disputes: any[]
  currentStatus: string
}

export function DisputeResolution({ disputes, currentStatus }: DisputeResolutionProps) {
  const [isResolving, setIsResolving] = useState(false)
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)
  const [selectedDispute, setSelectedDispute] = useState<any>(null)
  const [showResolveModal, setShowResolveModal] = useState(false)

  const handleResolveDispute = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setIsResolving(true)
    setMessage(null)

    const formData = new FormData(e.currentTarget)
    const result = await resolveDispute(
      selectedDispute.id, 
      formData.get('resolution') as string,
      formData.get('adminNotes') as string
    )

    if (result?.error) {
      setMessage({ type: 'error', text: result.error })
    } else if (result?.success) {
      setMessage({ type: 'success', text: result.message })
      setShowResolveModal(false)
      setSelectedDispute(null)
      window.location.reload()
    }

    setIsResolving(false)
  }

  const statusOptions = [
    { value: '', label: 'All Disputes' },
    { value: 'pending', label: 'Pending' },
    { value: 'in_review', label: 'In Review' },
    { value: 'resolved', label: 'Resolved' },
    { value: 'dismissed', label: 'Dismissed' },
  ]

  return (
    <div className="space-y-6">
      {/* Status Filter */}
      <div className="bg-white rounded-lg shadow p-6">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1">
            <select
              value={currentStatus}
              onChange={(e) => {
                const url = new URL(window.location.href)
                if (e.target.value) {
                  url.searchParams.set('status', e.target.value)
                } else {
                  url.searchParams.delete('status')
                }
                window.location.href = url.toString()
              }}
              className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
            >
              {statusOptions.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Message Display */}
      {message && (
        <div className={`p-4 rounded-md ${
          message.type === 'success' 
            ? 'bg-green-50 text-green-800 border border-green-200' 
            : 'bg-red-50 text-red-800 border border-red-200'
        }`}>
          {message.text}
        </div>
      )}

      {/* Disputes List */}
      <div className="space-y-4">
        {disputes.map((dispute) => (
          <div key={dispute.id} className="bg-white rounded-lg shadow p-6">
            <div className="flex justify-between items-start mb-4">
              <div>
                <h3 className="text-lg font-medium text-gray-900">{dispute.title}</h3>
                <p className="text-sm text-gray-500">
                  By {dispute.user?.full_name || 'Unknown User'} •{' '}
                  {new Date(dispute.created_at).toLocaleDateString()}
                </p>
              </div>
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

            <div className="mb-4">
              <p className="text-sm text-gray-700">{dispute.description}</p>
            </div>

            {dispute.fight && (
              <div className="mb-4 p-4 bg-gray-50 rounded-lg">
                <h4 className="text-sm font-medium text-gray-900 mb-2">Related Fight</h4>
                <p className="text-sm text-gray-600">
                  vs {dispute.fight.opponent_name} • {dispute.fight.result} •{' '}
                  {new Date(dispute.fight.date).toLocaleDateString()}
                </p>
              </div>
            )}

            <div className="flex justify-between items-center">
              <div className="text-sm text-gray-500">
                Category: {dispute.category.replace('_', ' ').toUpperCase()}
              </div>
              
              {dispute.status === 'pending' && (
                <button
                  onClick={() => {
                    setSelectedDispute(dispute)
                    setShowResolveModal(true)
                  }}
                  className="bg-red-600 text-white px-4 py-2 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors"
                >
                  Resolve Dispute
                </button>
              )}

              {dispute.status === 'resolved' && dispute.resolution && (
                <div className="text-sm">
                  <p className="font-medium text-gray-900">Resolution:</p>
                  <p className="text-gray-600">{dispute.resolution}</p>
                  {dispute.admin_notes && (
                    <p className="text-gray-500 mt-1">Admin Notes: {dispute.admin_notes}</p>
                  )}
                </div>
              )}
            </div>
          </div>
        ))}
      </div>

      {disputes.length === 0 && (
        <div className="text-center py-8">
          <div className="text-gray-400 mb-4">
            <svg className="mx-auto h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">No Disputes Found</h3>
          <p className="text-gray-500">
            {currentStatus ? `No disputes with status "${currentStatus}"` : 'No disputes available'}
          </p>
        </div>
      )}

      {/* Resolve Dispute Modal */}
      {showResolveModal && selectedDispute && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
            <div className="mt-3">
              <h3 className="text-lg font-medium text-gray-900 mb-4">
                Resolve Dispute: {selectedDispute.title}
              </h3>
              
              <form onSubmit={handleResolveDispute} className="space-y-4">
                <div>
                  <label htmlFor="resolution" className="block text-sm font-medium text-gray-700 mb-2">
                    Resolution
                  </label>
                  <select
                    id="resolution"
                    name="resolution"
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                  >
                    <option value="">Select resolution...</option>
                    <option value="upheld">Upheld - User's complaint is valid</option>
                    <option value="dismissed">Dismissed - No violation found</option>
                    <option value="partial">Partial - Some points valid</option>
                    <option value="pending_investigation">Pending Investigation</option>
                  </select>
                </div>

                <div>
                  <label htmlFor="adminNotes" className="block text-sm font-medium text-gray-700 mb-2">
                    Admin Notes (Optional)
                  </label>
                  <textarea
                    id="adminNotes"
                    name="adminNotes"
                    rows={3}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                    placeholder="Enter additional notes about the resolution..."
                  />
                </div>

                <div className="flex justify-end space-x-3">
                  <button
                    type="button"
                    onClick={() => {
                      setShowResolveModal(false)
                      setSelectedDispute(null)
                    }}
                    className="bg-gray-300 text-gray-700 px-4 py-2 rounded-md hover:bg-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={isResolving}
                    className="bg-red-600 text-white px-4 py-2 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isResolving ? 'Resolving...' : 'Resolve Dispute'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

