'use client'

import { useRouter, useSearchParams } from 'next/navigation'
import { useState } from 'react'

export function RankingsFilters() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [filters, setFilters] = useState({
    weightClass: searchParams.get('weightClass') || '',
    tier: searchParams.get('tier') || '',
  })

  const handleFilterChange = (key: string, value: string) => {
    const newFilters = { ...filters, [key]: value }
    setFilters(newFilters)
    
    const params = new URLSearchParams()
    if (newFilters.weightClass) params.set('weightClass', newFilters.weightClass)
    if (newFilters.tier) params.set('tier', newFilters.tier)
    
    router.push(`/rankings?${params.toString()}`)
  }

  const clearFilters = () => {
    setFilters({ weightClass: '', tier: '' })
    router.push('/rankings')
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
    <div className="space-y-6">
      <div>
        <label htmlFor="weightClass" className="block text-sm font-medium text-gray-700 mb-2">
          Weight Class
        </label>
        <select
          id="weightClass"
          value={filters.weightClass}
          onChange={(e) => handleFilterChange('weightClass', e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
        >
          <option value="">All Weight Classes</option>
          {weightClasses.map(weightClass => (
            <option key={weightClass} value={weightClass}>{weightClass}</option>
          ))}
        </select>
      </div>

      <div>
        <label htmlFor="tier" className="block text-sm font-medium text-gray-700 mb-2">
          Tier
        </label>
        <select
          id="tier"
          value={filters.tier}
          onChange={(e) => handleFilterChange('tier', e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
        >
          <option value="">All Tiers</option>
          {tiers.map(tier => (
            <option key={tier} value={tier}>{tier}</option>
          ))}
        </select>
      </div>

      <button
        onClick={clearFilters}
        className="w-full bg-gray-100 text-gray-700 py-2 px-4 rounded-md hover:bg-gray-200 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition-colors"
      >
        Clear Filters
      </button>
    </div>
  )
}

