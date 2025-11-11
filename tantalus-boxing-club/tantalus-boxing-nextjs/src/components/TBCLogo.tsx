'use client'

import { useState } from 'react'

export function TBCLogo() {
  const [videoError, setVideoError] = useState(false)

  if (videoError) {
    return (
      <div className="text-4xl font-bold text-red-600">
        TBC
      </div>
    )
  }

  return (
    <div className="w-24 h-24 mx-auto">
      <video
        autoPlay
        loop
        muted
        playsInline
        className="w-full h-full object-contain"
        onError={() => setVideoError(true)}
      >
        <source src="/assets/intro.MP4" type="video/mp4" />
        Your browser does not support the video tag.
      </video>
    </div>
  )
}

