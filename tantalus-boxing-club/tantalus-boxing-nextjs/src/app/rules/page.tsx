import Link from 'next/link'

export default function RulesPage() {
  return (
    <div className="min-h-screen bg-gray-50 py-8 px-4">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="bg-gradient-to-r from-red-600 to-red-800 rounded-lg p-6 mb-6 text-white">
          <h1 className="text-4xl font-bold mb-2">
            Tantalus Boxing Club – Creative Fighter League
          </h1>
          <p className="text-xl opacity-90">
            Official Rules & Guidelines (v1.0)
          </p>
          <div className="flex flex-wrap gap-2 mt-4">
            <span className="bg-white/20 px-3 py-1 rounded-full text-sm">
              Last Updated: November 16, 2025
            </span>
            <span className="bg-white/20 px-3 py-1 rounded-full text-sm">
              Governing Body: Tantalus Boxing Club (TBC)
            </span>
            <span className="bg-white/20 px-3 py-1 rounded-full text-sm">
              League Name: Creative Fighter League (CFL)
            </span>
          </div>
        </div>

        {/* Table of Contents */}
        <div className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-2xl font-bold mb-4">Table of Contents</h2>
          <nav className="space-y-2">
            <Link href="#introduction" className="block text-blue-600 hover:text-blue-800">1. Introduction</Link>
            <Link href="#tier-system" className="block text-blue-600 hover:text-blue-800">2. Tier System</Link>
            <Link href="#points-system" className="block text-blue-600 hover:text-blue-800">3. Points System</Link>
            <Link href="#rankings-system" className="block text-blue-600 hover:text-blue-800">4. Rankings System</Link>
            <Link href="#matchmaking-rules" className="block text-blue-600 hover:text-blue-800">5. Matchmaking Rules</Link>
            <Link href="#tournament-rules" className="block text-blue-600 hover:text-blue-800">6. Tournament Rules</Link>
            <Link href="#training-camp-system" className="block text-blue-600 hover:text-blue-800">7. Training Camp System</Link>
            <Link href="#callout-rematch-system" className="block text-blue-600 hover:text-blue-800">8. Callout/Rematch System</Link>
            <Link href="#fight-scheduling-rules" className="block text-blue-600 hover:text-blue-800">9. Fight Scheduling Rules</Link>
            <Link href="#demotion-promotion-system" className="block text-blue-600 hover:text-blue-800">10. Demotion and Promotion System</Link>
            <Link href="#code-of-conduct" className="block text-blue-600 hover:text-blue-800">11. Code of Conduct</Link>
            <Link href="#general-guidelines" className="block text-blue-600 hover:text-blue-800">12. General Guidelines</Link>
          </nav>
        </div>

        {/* Introduction */}
        <section id="introduction" className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-3xl font-bold mb-4 text-red-600">Introduction</h2>
          <p className="text-gray-700 mb-4">
            Welcome to the <strong>Creative Fighter League</strong> - a competitive boxing league where fighters progress through tiers, compete in tournaments, and build their legacy through skill, dedication, and fair play.
          </p>
          <h3 className="text-xl font-semibold mb-2">Core Principles</h3>
          <ul className="list-disc list-inside space-y-2 text-gray-700">
            <li><strong>Fair Competition:</strong> All matches are based on skill, tier, and rankings</li>
            <li><strong>Progressive Advancement:</strong> Fighters start as Amateurs and work their way up to Elite</li>
            <li><strong>Respect and Sportsmanship:</strong> Treat all fighters with respect, both in and out of the ring</li>
            <li><strong>Transparency:</strong> All rankings, points, and match results are publicly visible</li>
          </ul>
        </section>

        {/* Tier System */}
        <section id="tier-system" className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-3xl font-bold mb-4 text-red-600">Tier System</h2>
          <p className="text-gray-700 mb-4">
            All fighters begin in the <strong>Amateur</strong> tier and progress through five tiers based on their performance and points.
          </p>
          <div className="overflow-x-auto">
            <table className="min-w-full border-collapse border border-gray-300">
              <thead>
                <tr className="bg-red-600 text-white">
                  <th className="border border-gray-300 px-4 py-2 text-left">Tier</th>
                  <th className="border border-gray-300 px-4 py-2 text-left">Points Range</th>
                  <th className="border border-gray-300 px-4 py-2 text-left">Benefits</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td className="border border-gray-300 px-4 py-2 font-semibold">Amateur</td>
                  <td className="border border-gray-300 px-4 py-2">0-29 points</td>
                  <td className="border border-gray-300 px-4 py-2">Basic training access, Local events</td>
                </tr>
                <tr className="bg-gray-50">
                  <td className="border border-gray-300 px-4 py-2 font-semibold">Semi-Pro</td>
                  <td className="border border-gray-300 px-4 py-2">30-69 points</td>
                  <td className="border border-gray-300 px-4 py-2">Advanced training, Regional events, Basic analytics</td>
                </tr>
                <tr>
                  <td className="border border-gray-300 px-4 py-2 font-semibold">Pro</td>
                  <td className="border border-gray-300 px-4 py-2">70-139 points</td>
                  <td className="border border-gray-300 px-4 py-2">Professional training, National events, Full analytics, Sponsorship opportunities</td>
                </tr>
                <tr className="bg-gray-50">
                  <td className="border border-gray-300 px-4 py-2 font-semibold">Contender</td>
                  <td className="border border-gray-300 px-4 py-2">140-279 points</td>
                  <td className="border border-gray-300 px-4 py-2">Elite training, Championship events, Advanced analytics, Media coverage, Title shots</td>
                </tr>
                <tr>
                  <td className="border border-gray-300 px-4 py-2 font-semibold">Elite</td>
                  <td className="border border-gray-300 px-4 py-2">280+ points</td>
                  <td className="border border-gray-300 px-4 py-2">World-class training, Global events, Premium analytics, Live streaming, Media interviews, Championship belts</td>
                </tr>
              </tbody>
            </table>
          </div>
          <div className="mt-4 space-y-2 text-gray-700">
            <p><strong>Tier Advancement:</strong> When your points reach the minimum threshold for the next tier, you are automatically promoted.</p>
            <p><strong>Tier Benefits:</strong> Higher tiers unlock better training opportunities, tournaments, and exclusive events.</p>
            <p><strong>Tier Lock:</strong> You cannot be demoted below your current tier based solely on points loss (see Demotion System).</p>
          </div>
        </section>

        {/* Points System */}
        <section id="points-system" className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-3xl font-bold mb-4 text-red-600">Points System</h2>
          <div className="space-y-4 text-gray-700">
            <div>
              <h3 className="text-xl font-semibold mb-2">Win Points</h3>
              <ul className="list-disc list-inside space-y-1">
                <li><strong>Decision Win:</strong> +5 points</li>
                <li><strong>TKO/KO Win:</strong> +8 points (bonus for finish)</li>
                <li><strong>Submission Win:</strong> +8 points</li>
              </ul>
            </div>
            <div>
              <h3 className="text-xl font-semibold mb-2">Loss Points</h3>
              <ul className="list-disc list-inside space-y-1">
                <li><strong>Decision Loss:</strong> -3 points</li>
                <li><strong>TKO/KO Loss:</strong> -3 points</li>
                <li><strong>Submission Loss:</strong> -3 points</li>
              </ul>
            </div>
            <div>
              <h3 className="text-xl font-semibold mb-2">Draw</h3>
              <p>No points awarded or deducted (0 points)</p>
            </div>
            <div>
              <h3 className="text-xl font-semibold mb-2">Bonus Points</h3>
              <ul className="list-disc list-inside space-y-1">
                <li>Tournament victories: Additional points based on tournament tier</li>
                <li>Upset victories: Bonus points for defeating higher-ranked opponents</li>
                <li>Streak bonuses: Bonus points for consecutive wins</li>
              </ul>
            </div>
          </div>
        </section>

        {/* Rankings System */}
        <section id="rankings-system" className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-3xl font-bold mb-4 text-red-600">Rankings System</h2>
          <div className="space-y-4 text-gray-700">
            <p>Rankings are determined by total points, with tiebreakers in the following order:</p>
            <ol className="list-decimal list-inside space-y-2">
              <li>Total Points (highest first)</li>
              <li>Win Percentage (highest first)</li>
              <li>Total Wins (highest first)</li>
              <li>Recent Performance (last 5 fights)</li>
              <li>Head-to-Head Record (if applicable)</li>
            </ol>
            <p>Rankings are updated in real-time after each fight result is recorded.</p>
          </div>
        </section>

        {/* Matchmaking Rules */}
        <section id="matchmaking-rules" className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-3xl font-bold mb-4 text-red-600">Matchmaking Rules</h2>
          <div className="space-y-4 text-gray-700">
            <p>Fighters can request matches through the matchmaking system. Matches are made based on:</p>
            <ul className="list-disc list-inside space-y-2">
              <li>Similar tier levels (within 1 tier difference preferred)</li>
              <li>Similar point totals (within 20 points preferred)</li>
              <li>Weight class compatibility</li>
              <li>Availability and scheduling preferences</li>
            </ul>
            <p>Both fighters must accept the match for it to be confirmed.</p>
          </div>
        </section>

        {/* Tournament Rules */}
        <section id="tournament-rules" className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-3xl font-bold mb-4 text-red-600">Tournament Rules</h2>
          <div className="space-y-4 text-gray-700">
            <p>Tournaments are organized by tier and weight class. Key rules:</p>
            <ul className="list-disc list-inside space-y-2">
              <li>Tournaments require a minimum of 4 participants</li>
              <li>Maximum of 64 participants per tournament</li>
              <li>Bracket-style elimination format</li>
              <li>Tournament winners receive bonus points and special recognition</li>
              <li>All tournament matches count toward regular rankings</li>
            </ul>
          </div>
        </section>

        {/* Training Camp System */}
        <section id="training-camp-system" className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-3xl font-bold mb-4 text-red-600">Training Camp System</h2>
          <div className="space-y-4 text-gray-700">
            <p>Fighters can join training camps to improve skills and connect with other fighters:</p>
            <ul className="list-disc list-inside space-y-2">
              <li>Training camps are organized by tier and location</li>
              <li>Regular training sessions improve fighter performance</li>
              <li>Training logs help track progress and dedication</li>
              <li>Active participation in training camps can unlock special opportunities</li>
            </ul>
          </div>
        </section>

        {/* Callout/Rematch System */}
        <section id="callout-rematch-system" className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-3xl font-bold mb-4 text-red-600">Callout/Rematch System</h2>
          <div className="space-y-4 text-gray-700">
            <p>Fighters can call out opponents or request rematches:</p>
            <ul className="list-disc list-inside space-y-2">
              <li>Callouts must be within reasonable tier/point differences</li>
              <li>Called-out fighters have 7 days to respond</li>
              <li>Rematches can be requested after a loss</li>
              <li>Both fighters must agree to the match</li>
            </ul>
          </div>
        </section>

        {/* Fight Scheduling Rules */}
        <section id="fight-scheduling-rules" className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-3xl font-bold mb-4 text-red-600">Fight Scheduling Rules</h2>
          <div className="space-y-4 text-gray-700">
            <ul className="list-disc list-inside space-y-2">
              <li>Fights must be scheduled at least 7 days in advance</li>
              <li>Both fighters must confirm the date and time</li>
              <li>Rescheduling requires mutual agreement</li>
              <li>No-shows result in automatic loss and point deduction</li>
              <li>Fight results must be submitted within 24 hours of completion</li>
            </ul>
          </div>
        </section>

        {/* Demotion and Promotion System */}
        <section id="demotion-promotion-system" className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-3xl font-bold mb-4 text-red-600">Demotion and Promotion System</h2>
          <div className="space-y-4 text-gray-700">
            <p><strong>Promotion:</strong> Automatic when points reach the next tier threshold.</p>
            <p><strong>Demotion:</strong> Can occur in the following circumstances:</p>
            <ul className="list-disc list-inside space-y-2">
              <li>Extended inactivity (no fights for 90+ days)</li>
              <li>Multiple consecutive losses (5+ losses in a row)</li>
              <li>Code of conduct violations</li>
              <li>Administrative decision</li>
            </ul>
            <p>Demotion is not automatic based solely on point loss - you maintain your tier until you reach the promotion threshold for the next tier down.</p>
          </div>
        </section>

        {/* Code of Conduct */}
        <section id="code-of-conduct" className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-3xl font-bold mb-4 text-red-600">Code of Conduct</h2>
          <div className="space-y-4 text-gray-700">
            <p>All fighters must adhere to the following code of conduct:</p>
            <ul className="list-disc list-inside space-y-2">
              <li><strong>Respect:</strong> Treat all fighters, staff, and community members with respect</li>
              <li><strong>Fair Play:</strong> No cheating, manipulation, or unsportsmanlike conduct</li>
              <li><strong>Honesty:</strong> Accurate reporting of fight results and records</li>
              <li><strong>Participation:</strong> Active engagement in the league and community</li>
              <li><strong>Professionalism:</strong> Maintain professional behavior in all interactions</li>
            </ul>
            <p className="mt-4"><strong>Violations:</strong> Code of conduct violations may result in warnings, point deductions, suspension, or permanent ban from the league.</p>
          </div>
        </section>

        {/* General Guidelines */}
        <section id="general-guidelines" className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-3xl font-bold mb-4 text-red-600">General Guidelines</h2>
          <div className="space-y-4 text-gray-700">
            <ul className="list-disc list-inside space-y-2">
              <li>All fight results must be verified and approved</li>
              <li>Disputes can be submitted through the dispute resolution system</li>
              <li>Regular participation is encouraged to maintain active status</li>
              <li>Community feedback and suggestions are welcome</li>
              <li>Rules may be updated - check the News feed for announcements</li>
            </ul>
          </div>
        </section>

        {/* Footer */}
        <div className="bg-white rounded-lg shadow-md p-6 text-center text-gray-600">
          <p>For questions or clarifications, contact league administrators or check the News feed for updates.</p>
          <div className="mt-4">
            <Link href="/" className="text-red-600 hover:text-red-800 font-semibold">
              ← Back to Home
            </Link>
          </div>
        </div>
      </div>
    </div>
  )
}

