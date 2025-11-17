'use client'

import { useState } from 'react'
import { uploadMediaAsset, scheduleInterview } from '@/lib/actions/media'
import { MediaAsset, Interview, FighterProfile } from '@/types'

interface MediaHubProps {
  mediaAssets: MediaAsset[]
  interviews: Interview[]
  fighterProfile: FighterProfile
}

export function MediaHub({ mediaAssets, interviews, fighterProfile }: MediaHubProps) {
  const [activeTab, setActiveTab] = useState('highlights')
  const [isUploading, setIsUploading] = useState(false)
  const [uploadMessage, setUploadMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  const handleMediaUpload = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setIsUploading(true)
    setUploadMessage(null)

    const formData = new FormData(e.currentTarget)
    const result = await uploadMediaAsset(formData)

    if (result?.error) {
      setUploadMessage({ type: 'error', text: result.error })
    } else if (result?.success) {
      setUploadMessage({ type: 'success', text: result.message })
      e.currentTarget.reset()
      // Refresh the page to show new media
      window.location.reload()
    }

    setIsUploading(false)
  }

  const handleInterviewSchedule = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setIsUploading(true)
    setUploadMessage(null)

    const formData = new FormData(e.currentTarget)
    const result = await scheduleInterview(formData)

    if (result?.error) {
      setUploadMessage({ type: 'error', text: result.error })
    } else if (result?.success) {
      setUploadMessage({ type: 'success', text: result.message })
      e.currentTarget.reset()
      // Refresh the page to show new interview
      window.location.reload()
    }

    setIsUploading(false)
  }

  const categories = [
    { id: 'highlights', name: 'Highlights', icon: '🎯' },
    { id: 'training', name: 'Training', icon: '💪' },
    { id: 'interview', name: 'Interviews', icon: '🎤' },
    { id: 'promo', name: 'Promo', icon: '📢' },
  ]

  const filteredAssets = mediaAssets.filter(asset => asset.category === activeTab)

  return (
    <div className="space-y-8">
      {/* Upload Section */}
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-semibold text-gray-900 mb-6">Upload Media</h2>
        
        {uploadMessage && (
          <div className={`p-4 rounded-md mb-6 ${
            uploadMessage.type === 'success' 
              ? 'bg-green-50 text-green-800 border border-green-200' 
              : 'bg-red-50 text-red-800 border border-red-200'
          }`}>
            {uploadMessage.text}
          </div>
        )}

        <form onSubmit={handleMediaUpload} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label htmlFor="title" className="block text-sm font-medium text-gray-700 mb-2">
                Title
              </label>
              <input
                id="title"
                name="title"
                type="text"
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                placeholder="Enter media title"
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
                <option value="highlight">Highlight</option>
                <option value="training">Training</option>
                <option value="interview">Interview</option>
                <option value="promo">Promo</option>
              </select>
            </div>
          </div>

          <div>
            <label htmlFor="description" className="block text-sm font-medium text-gray-700 mb-2">
              Description (Optional)
            </label>
            <textarea
              id="description"
              name="description"
              rows={3}
              className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
              placeholder="Enter media description"
            />
          </div>

          <div>
            <label htmlFor="file" className="block text-sm font-medium text-gray-700 mb-2">
              Media File
            </label>
            <input
              id="file"
              name="file"
              type="file"
              accept="image/*,video/*"
              required
              className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
            />
          </div>

          <button
            type="submit"
            disabled={isUploading}
            className="w-full bg-red-600 text-white py-2 px-4 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isUploading ? 'Uploading...' : 'Upload Media'}
          </button>
        </form>
      </div>

      {/* Media Gallery */}
      <div className="bg-white rounded-lg shadow p-6">
        <div className="flex space-x-1 mb-6">
          {categories.map((category) => (
            <button
              key={category.id}
              onClick={() => setActiveTab(category.id)}
              className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                activeTab === category.id
                  ? 'bg-red-100 text-red-700'
                  : 'text-gray-500 hover:text-gray-700 hover:bg-gray-100'
              }`}
            >
              {category.icon} {category.name}
            </button>
          ))}
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredAssets.map((asset) => (
            <div key={asset.id} className="border border-gray-200 rounded-lg overflow-hidden">
              {asset.file_type === 'video' ? (
                <video
                  src={asset.file_url}
                  controls
                  className="w-full h-48 object-cover"
                />
              ) : (
                <img
                  src={asset.file_url}
                  alt={asset.title}
                  className="w-full h-48 object-cover"
                />
              )}
              <div className="p-4">
                <h3 className="text-sm font-medium text-gray-900 mb-2">{asset.title}</h3>
                {asset.description && (
                  <p className="text-sm text-gray-500 mb-2">{asset.description}</p>
                )}
                <div className="flex justify-between items-center text-xs text-gray-400">
                  <span>{new Date(asset.created_at).toLocaleDateString()}</span>
                </div>
              </div>
            </div>
          ))}
        </div>

        {filteredAssets.length === 0 && (
          <div className="text-center py-8">
            <div className="text-gray-400 mb-4">
              <svg className="mx-auto h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">No {categories.find(c => c.id === activeTab)?.name} Found</h3>
            <p className="text-gray-500">Upload some media to get started.</p>
          </div>
        )}
      </div>

      {/* Interview Scheduling */}
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-semibold text-gray-900 mb-6">Schedule Interview</h2>
        
        <form onSubmit={handleInterviewSchedule} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label htmlFor="interviewer" className="block text-sm font-medium text-gray-700 mb-2">
                Interviewer
              </label>
              <input
                id="interviewer"
                name="interviewer"
                type="text"
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                placeholder="Enter interviewer name"
              />
            </div>

            <div>
              <label htmlFor="title" className="block text-sm font-medium text-gray-700 mb-2">
                Interview Title
              </label>
              <input
                id="title"
                name="title"
                type="text"
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                placeholder="Enter interview title"
              />
            </div>

            <div>
              <label htmlFor="scheduledDate" className="block text-sm font-medium text-gray-700 mb-2">
                Scheduled Date
              </label>
              <input
                id="scheduledDate"
                name="scheduledDate"
                type="datetime-local"
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
              />
            </div>

            <div>
              <label htmlFor="durationMinutes" className="block text-sm font-medium text-gray-700 mb-2">
                Duration (minutes)
              </label>
              <input
                id="durationMinutes"
                name="durationMinutes"
                type="number"
                min="15"
                max="120"
                required
                defaultValue="30"
                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
              />
            </div>
          </div>

          <div>
            <label htmlFor="description" className="block text-sm font-medium text-gray-700 mb-2">
              Description (Optional)
            </label>
            <textarea
              id="description"
              name="description"
              rows={3}
              className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
              placeholder="Enter interview description"
            />
          </div>

          <button
            type="submit"
            disabled={isUploading}
            className="w-full bg-red-600 text-white py-2 px-4 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isUploading ? 'Scheduling...' : 'Schedule Interview'}
          </button>
        </form>
      </div>

      {/* Upcoming Interviews */}
      {interviews.length > 0 && (
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-6">Upcoming Interviews</h2>
          
          <div className="space-y-4">
            {interviews.map((interview) => (
              <div key={interview.id} className="border border-gray-200 rounded-lg p-4">
                <div className="flex justify-between items-start">
                  <div>
                    <h3 className="text-sm font-medium text-gray-900">{interview.title}</h3>
                    <p className="text-sm text-gray-500">with {interview.interviewer}</p>
                    <p className="text-sm text-gray-500">
                      {new Date(interview.scheduled_date).toLocaleString()}
                    </p>
                  </div>
                  <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                    interview.status === 'scheduled' 
                      ? 'bg-blue-100 text-blue-800'
                      : interview.status === 'completed'
                      ? 'bg-green-100 text-green-800'
                      : 'bg-red-100 text-red-800'
                  }`}>
                    {interview.status}
                  </span>
                </div>
                {interview.description && (
                  <p className="text-sm text-gray-600 mt-2">{interview.description}</p>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

