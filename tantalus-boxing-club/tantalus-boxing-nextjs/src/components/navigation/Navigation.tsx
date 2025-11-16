'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { signOut } from '@/lib/actions/auth'

export function Navigation() {
  const pathname = usePathname()

  const navigation = [
    { name: 'Dashboard', href: '/dashboard' },
    { name: 'Matchmaking', href: '/matchmaking' },
    { name: 'Tournaments', href: '/tournaments' },
    { name: 'Rankings', href: '/rankings' },
    { name: 'Fight Record', href: '/record-entry' },
    { name: 'Media Hub', href: '/media' },
    { name: 'Training', href: '/training' },
    { name: 'Analytics', href: '/analytics' },
    { name: 'Disputes', href: '/disputes' },
    { name: 'Rules', href: '/rules' },
    { name: 'Admin', href: '/admin' },
    { name: 'Monitoring', href: '/admin/monitoring' },
  ]

  const isActive = (href: string) => pathname === href

  return (
    <nav className="bg-white shadow-lg">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex">
            <div className="flex-shrink-0 flex items-center">
              <Link href="/dashboard" className="text-xl font-bold text-red-600">
                TBC
              </Link>
            </div>
            <div className="hidden sm:ml-6 sm:flex sm:space-x-8">
              {navigation.map((item) => (
                <Link
                  key={item.name}
                  href={item.href}
                  className={`inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium ${
                    isActive(item.href)
                      ? 'border-red-500 text-gray-900'
                      : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700'
                  }`}
                >
                  {item.name}
                </Link>
              ))}
            </div>
          </div>
          <div className="flex items-center">
            <form action={signOut}>
              <button
                type="submit"
                className="bg-red-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors"
              >
                Sign Out
              </button>
            </form>
          </div>
        </div>
      </div>
    </nav>
  )
}
