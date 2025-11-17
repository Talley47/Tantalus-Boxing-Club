import Link from 'next/link'

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-red-900 to-gray-900">
      <div className="min-h-screen flex items-center justify-center px-4">
        <div className="max-w-4xl w-full text-center">
          {/* Logo/Title */}
          <div className="mb-8">
            <h1 className="text-6xl md:text-8xl font-bold text-white mb-4">
              <span className="text-red-600">TANTALUS</span>
              <br />
              <span className="text-white">BOXING CLUB</span>
            </h1>
            <p className="text-xl md:text-2xl text-gray-300 font-medium">
              The Ultimate Virtual Boxing League Platform
            </p>
          </div>

          {/* Features */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
            <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20">
              <div className="text-4xl mb-3">🥊</div>
              <h3 className="text-white font-semibold mb-2">Compete</h3>
              <p className="text-gray-300 text-sm">
                Join tournaments and climb the rankings
              </p>
            </div>
            <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20">
              <div className="text-4xl mb-3">🏆</div>
              <h3 className="text-white font-semibold mb-2">Champion</h3>
              <p className="text-gray-300 text-sm">
                Build your legacy and earn titles
              </p>
            </div>
            <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20">
              <div className="text-4xl mb-3">💪</div>
              <h3 className="text-white font-semibold mb-2">Train</h3>
              <p className="text-gray-300 text-sm">
                Join training camps and improve skills
              </p>
            </div>
          </div>

          {/* CTA Buttons */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
            <Link
              href="/login"
              className="bg-red-600 text-white px-8 py-4 rounded-lg font-semibold text-lg hover:bg-red-700 transition-colors shadow-lg hover:shadow-xl transform hover:scale-105 transition-transform w-full sm:w-auto"
            >
              Login
            </Link>
            <Link
              href="/register"
              className="bg-white text-red-600 px-8 py-4 rounded-lg font-semibold text-lg hover:bg-gray-100 transition-colors shadow-lg hover:shadow-xl transform hover:scale-105 transition-transform w-full sm:w-auto"
            >
              Create Account
            </Link>
            <Link
              href="/rules"
              className="bg-gray-800 text-white px-8 py-4 rounded-lg font-semibold text-lg hover:bg-gray-900 transition-colors shadow-lg hover:shadow-xl transform hover:scale-105 transition-transform w-full sm:w-auto"
            >
              Rules & Guidelines
            </Link>
          </div>

          {/* Rules & Guidelines Section */}
          <div className="mt-16 bg-white/10 backdrop-blur-sm rounded-lg p-8 border border-white/20 max-w-5xl mx-auto">
            <div className="text-center mb-6">
              <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">
                Rules & Guidelines
              </h2>
              <p className="text-gray-300 text-lg">
                Creative Fighter League - Official Rules
              </p>
            </div>
            
            <div className="bg-white/5 rounded-lg p-6 mb-6">
              <h3 className="text-xl font-semibold text-white mb-4">Quick Overview</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-gray-300 text-sm">
                <div>
                  <p className="font-semibold text-white mb-2">🏆 Tier System</p>
                  <p>Fighters are ranked across multiple tiers from Novice to Elite</p>
                </div>
                <div>
                  <p className="font-semibold text-white mb-2">📊 Points System</p>
                  <p>Earn points through wins, with bonuses for different victory methods</p>
                </div>
                <div>
                  <p className="font-semibold text-white mb-2">🥊 Matchmaking</p>
                  <p>Fair matchups based on tier, weight class, and skill level</p>
                </div>
                <div>
                  <p className="font-semibold text-white mb-2">⚖️ Code of Conduct</p>
                  <p>Respect, sportsmanship, and fair play are mandatory</p>
                </div>
              </div>
            </div>

            <div className="text-center">
              <Link
                href="/rules"
                className="inline-block bg-red-600 text-white px-8 py-3 rounded-lg font-semibold text-lg hover:bg-red-700 transition-colors shadow-lg hover:shadow-xl transform hover:scale-105 transition-transform"
              >
                View Full Rules & Guidelines →
              </Link>
            </div>
          </div>

          {/* Footer */}
          <div className="mt-16 text-gray-400 text-sm">
            <p>Powered by TBC Promotions</p>
          </div>
        </div>
      </div>
    </div>
  )
}
