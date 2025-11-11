import { render, screen } from '@testing-library/react'

vi.mock('next/navigation', () => ({
  usePathname: () => '/',
}))

vi.mock('@/lib/actions/auth', () => ({
  signOut: vi.fn(async () => ({ success: true })),
}))

import { Navigation } from './Navigation'

describe('Navigation', () => {
  it('renders primary nav items', () => {
    render(<Navigation />)
    expect(screen.getByText('Dashboard')).toBeInTheDocument()
    expect(screen.getByText('Matchmaking')).toBeInTheDocument()
    expect(screen.getByText('Tournaments')).toBeInTheDocument()
  })
})


