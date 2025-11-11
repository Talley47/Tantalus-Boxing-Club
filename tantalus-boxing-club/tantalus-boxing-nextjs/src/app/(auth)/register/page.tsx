'use client'

import { useState } from 'react'
import { signUp, createFighterProfile } from '@/lib/actions/auth'
import { TBCLogo } from '@/components/TBCLogo'

export default function RegisterPage() {
  const [step, setStep] = useState(1)
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    confirmPassword: '',
    fullName: '',
    fighterName: '',
    birthday: '',
    hometown: '',
    stance: 'Orthodox',
    heightFeet: 5,
    heightInches: 8,
    reach: 70,
    weight: 150,
    weightClass: 'Welterweight',
    trainer: '',
    gym: '',
  })

  const handleAccountSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    const result = await signUp(new FormData(e.target as HTMLFormElement))
    
    if (result?.error) {
      alert(result.error)
      return
    }
    
    if (result?.success) {
      setStep(2)
    }
  }

  const handleFighterSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    const formDataObj = new FormData()
    
    Object.entries(formData).forEach(([key, value]) => {
      if (key.startsWith('fighter') || key === 'birthday' || key === 'hometown' || 
          key === 'stance' || key === 'heightFeet' || key === 'heightInches' || 
          key === 'reach' || key === 'weight' || key === 'weightClass' || 
          key === 'trainer' || key === 'gym') {
        formDataObj.append(key, value.toString())
      }
    })
    
    await createFighterProfile(formDataObj)
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

  return (
    <div className="min-h-screen relative flex items-center justify-center">
      {/* Background Video */}
      <video
        autoPlay
        loop
        muted
        playsInline
        className="absolute inset-0 w-full h-full object-cover"
      >
        <source src="/assets/AdobeStock_429519159.mov" type="video/quicktime" />
        Your browser does not support the video tag.
      </video>
      
      {/* Overlay */}
      <div className="absolute inset-0 bg-black/50" />
      
      {/* Content */}
      <div className="relative z-10 w-full max-w-2xl mx-auto p-6">
        <div className="bg-white/95 backdrop-blur-sm rounded-lg shadow-xl p-8">
          {/* Logo */}
          <div className="text-center mb-8">
            <TBCLogo />
            <p className="text-sm text-gray-600 mt-2">Powered By TBC Promotions</p>
          </div>
          
          {/* Title */}
          <h1 className="text-3xl font-bold text-red-600 text-center mb-8">
            Tantalus Boxing Club
          </h1>
          
          {/* Progress Indicator */}
          <div className="flex justify-center mb-8">
            <div className="flex space-x-4">
              <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                step >= 1 ? 'bg-red-600 text-white' : 'bg-gray-300 text-gray-600'
              }`}>
                1
              </div>
              <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                step >= 2 ? 'bg-red-600 text-white' : 'bg-gray-300 text-gray-600'
              }`}>
                2
              </div>
            </div>
          </div>
          
          {/* Step 1: Account Information */}
          {step === 1 && (
            <form onSubmit={handleAccountSubmit} className="space-y-6">
              <h2 className="text-2xl font-semibold text-gray-900 mb-6">Account Information</h2>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label htmlFor="fullName" className="block text-sm font-medium text-gray-700 mb-2">
                    Full Name
                  </label>
                  <input
                    id="fullName"
                    name="fullName"
                    type="text"
                    required
                    value={formData.fullName}
                    onChange={(e) => setFormData({...formData, fullName: e.target.value})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                    placeholder="Enter your full name"
                  />
                </div>
                
                <div>
                  <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                    Email Address
                  </label>
                  <input
                    id="email"
                    name="email"
                    type="email"
                    required
                    value={formData.email}
                    onChange={(e) => setFormData({...formData, email: e.target.value})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                    placeholder="Enter your email"
                  />
                </div>
                
                <div>
                  <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-2">
                    Password
                  </label>
                  <input
                    id="password"
                    name="password"
                    type="password"
                    required
                    value={formData.password}
                    onChange={(e) => setFormData({...formData, password: e.target.value})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                    placeholder="Enter your password"
                  />
                </div>
                
                <div>
                  <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700 mb-2">
                    Confirm Password
                  </label>
                  <input
                    id="confirmPassword"
                    name="confirmPassword"
                    type="password"
                    required
                    value={formData.confirmPassword}
                    onChange={(e) => setFormData({...formData, confirmPassword: e.target.value})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                    placeholder="Confirm your password"
                  />
                </div>
              </div>
              
              <button
                type="submit"
                className="w-full bg-red-600 text-white py-2 px-4 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors"
              >
                Create Account
              </button>
            </form>
          )}
          
          {/* Step 2: Fighter Profile */}
          {step === 2 && (
            <form onSubmit={handleFighterSubmit} className="space-y-6">
              <h2 className="text-2xl font-semibold text-gray-900 mb-6">Fighter Profile</h2>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label htmlFor="fighterName" className="block text-sm font-medium text-gray-700 mb-2">
                    Fighter Name
                  </label>
                  <input
                    id="fighterName"
                    name="fighterName"
                    type="text"
                    required
                    value={formData.fighterName}
                    onChange={(e) => setFormData({...formData, fighterName: e.target.value})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                    placeholder="Enter your fighter name"
                  />
                </div>
                
                <div>
                  <label htmlFor="birthday" className="block text-sm font-medium text-gray-700 mb-2">
                    Birthday
                  </label>
                  <input
                    id="birthday"
                    name="birthday"
                    type="date"
                    required
                    value={formData.birthday}
                    onChange={(e) => setFormData({...formData, birthday: e.target.value})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                  />
                </div>
                
                <div>
                  <label htmlFor="hometown" className="block text-sm font-medium text-gray-700 mb-2">
                    Hometown
                  </label>
                  <input
                    id="hometown"
                    name="hometown"
                    type="text"
                    required
                    value={formData.hometown}
                    onChange={(e) => setFormData({...formData, hometown: e.target.value})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                    placeholder="Enter your hometown"
                  />
                </div>
                
                <div>
                  <label htmlFor="stance" className="block text-sm font-medium text-gray-700 mb-2">
                    Stance
                  </label>
                  <select
                    id="stance"
                    name="stance"
                    required
                    value={formData.stance}
                    onChange={(e) => setFormData({...formData, stance: e.target.value})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                  >
                    <option value="Orthodox">Orthodox</option>
                    <option value="Southpaw">Southpaw</option>
                    <option value="Switch">Switch</option>
                  </select>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Height (Feet & Inches)
                  </label>
                  <div className="flex space-x-2">
                    <select
                      name="heightFeet"
                      value={formData.heightFeet}
                      onChange={(e) => setFormData({...formData, heightFeet: parseInt(e.target.value)})}
                      className="flex-1 px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                    >
                      {[4, 5, 6, 7].map(feet => (
                        <option key={feet} value={feet}>{feet}'</option>
                      ))}
                    </select>
                    <select
                      name="heightInches"
                      value={formData.heightInches}
                      onChange={(e) => setFormData({...formData, heightInches: parseInt(e.target.value)})}
                      className="flex-1 px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                    >
                      {[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map(inches => (
                        <option key={inches} value={inches}>{inches}"</option>
                      ))}
                    </select>
                  </div>
                </div>
                
                <div>
                  <label htmlFor="reach" className="block text-sm font-medium text-gray-700 mb-2">
                    Reach (Inches)
                  </label>
                  <input
                    id="reach"
                    name="reach"
                    type="number"
                    min="50"
                    max="90"
                    required
                    value={formData.reach}
                    onChange={(e) => setFormData({...formData, reach: parseInt(e.target.value)})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                    placeholder="Enter reach in inches"
                  />
                </div>
                
                <div>
                  <label htmlFor="weight" className="block text-sm font-medium text-gray-700 mb-2">
                    Weight (Pounds)
                  </label>
                  <input
                    id="weight"
                    name="weight"
                    type="number"
                    min="100"
                    max="400"
                    required
                    value={formData.weight}
                    onChange={(e) => setFormData({...formData, weight: parseInt(e.target.value)})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                    placeholder="Enter weight in pounds"
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
                    value={formData.weightClass}
                    onChange={(e) => setFormData({...formData, weightClass: e.target.value})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                  >
                    {weightClasses.map(weightClass => (
                      <option key={weightClass} value={weightClass}>{weightClass}</option>
                    ))}
                  </select>
                </div>
                
                <div>
                  <label htmlFor="trainer" className="block text-sm font-medium text-gray-700 mb-2">
                    Trainer (Optional)
                  </label>
                  <input
                    id="trainer"
                    name="trainer"
                    type="text"
                    value={formData.trainer}
                    onChange={(e) => setFormData({...formData, trainer: e.target.value})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                    placeholder="Enter trainer name"
                  />
                </div>
                
                <div>
                  <label htmlFor="gym" className="block text-sm font-medium text-gray-700 mb-2">
                    Gym/Team (Optional)
                  </label>
                  <input
                    id="gym"
                    name="gym"
                    type="text"
                    value={formData.gym}
                    onChange={(e) => setFormData({...formData, gym: e.target.value})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                    placeholder="Enter gym or team name"
                  />
                </div>
              </div>
              
              <button
                type="submit"
                className="w-full bg-red-600 text-white py-2 px-4 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors"
              >
                Create Fighter Profile
              </button>
            </form>
          )}
          
          {/* Login Link */}
          <div className="mt-6 text-center">
            <p className="text-sm text-gray-600">
              Already have an account?{' '}
              <a 
                href="/login" 
                className="text-red-600 hover:text-red-700 font-medium"
              >
                Sign in here
              </a>
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}

