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

          {/* Footer */}
          <div className="mt-16 text-gray-400 text-sm">
            <p>Powered by TBC Promotions</p>
          </div>
        </div>
      </div>
    </div>
  )
}
