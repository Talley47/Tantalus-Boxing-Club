import { NextResponse, type NextRequest } from 'next/server'
import { createMiddlewareClient } from '@supabase/auth-helpers-nextjs'
import { rateLimit, authRateLimit, uploadRateLimit, adminRateLimit } from '@/lib/rate-limit'

export async function middleware(request: NextRequest) {
  const response = NextResponse.next()
  const supabase = createMiddlewareClient({ req: request, res: response })

  const { data: { user } } = await supabase.auth.getUser()
  const pathname = request.nextUrl.pathname

  // Get client IP for rate limiting
  const ip = request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() || 
             request.headers.get('x-real-ip') || 
             '127.0.0.1'
  
  // Apply different rate limits based on route with error handling
  let rateLimitResult
  try {
    if (pathname.startsWith('/api/auth')) {
      rateLimitResult = await authRateLimit.limit(`auth:${ip}`)
    } else if (pathname.startsWith('/api/upload') || pathname.includes('upload')) {
      rateLimitResult = await uploadRateLimit.limit(`upload:${ip}`)
    } else if (pathname.startsWith('/admin')) {
      rateLimitResult = await adminRateLimit.limit(`admin:${ip}`)
    } else {
      rateLimitResult = await rateLimit.limit(`api:${ip}`)
    }
  } catch (error) {
    // If rate limiting fails, log error but allow request to proceed
    console.error('Rate limiting error in middleware:', error)
    // Create a fallback result that allows the request
    rateLimitResult = {
      success: true,
      limit: 1000,
      remaining: 999,
      reset: Date.now() + 60000,
    }
  }

  // Set rate limit headers
  response.headers.set('X-RateLimit-Limit', rateLimitResult.limit.toString())
  response.headers.set('X-RateLimit-Remaining', rateLimitResult.remaining.toString())
  response.headers.set('X-RateLimit-Reset', rateLimitResult.reset.toString())

  if (!rateLimitResult.success) {
    return new NextResponse('Too Many Requests', { 
      status: 429,
      headers: {
        'Retry-After': Math.ceil((rateLimitResult.reset - Date.now()) / 1000).toString()
      }
    })
  }

  // Security headers
  response.headers.set('X-Frame-Options', 'DENY')
  response.headers.set('X-Content-Type-Options', 'nosniff')
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin')
  response.headers.set('X-XSS-Protection', '1; mode=block')
  
  // Content Security Policy
  const csp = [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://vercel.live https://*.vercel.live https://*.vercel-insights.com https://*.supabase.co",
    "script-src-elem 'self' 'unsafe-inline' https://*.supabase.co https://vercel.live https://*.vercel.live https://*.vercel-insights.com",
    "script-src-attr 'self' 'unsafe-inline'",
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
    "font-src 'self' https://fonts.gstatic.com",
    "img-src 'self' data: https: blob:",
    "media-src 'self' data: https: blob:",
    "connect-src 'self' https://*.supabase.co wss://*.supabase.co https://*.upstash.io https://vercel.live https://*.vercel.live https://*.vercel-insights.com",
    "frame-src 'self' https://vercel.live https://*.vercel.live https://*.supabase.co",
    "frame-ancestors 'none'",
    "worker-src 'self' blob:",
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self'"
  ].join('; ')
  
  response.headers.set('Content-Security-Policy', csp)

  // Protected routes that require authentication
  const protectedRoutes = [
    '/dashboard',
    '/matchmaking', 
    '/tournaments',
    '/rankings',
    '/record-entry',
    '/media',
    '/training',
    '/analytics',
    '/disputes'
  ]

  // Admin routes that require admin role
  const adminRoutes = ['/admin']

  // Check if route requires authentication
  const requiresAuth = protectedRoutes.some(route => pathname.startsWith(route))
  const requiresAdmin = adminRoutes.some(route => pathname.startsWith(route))

  if (requiresAuth && !user) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  if (requiresAdmin) {
    if (!user) {
      return NextResponse.redirect(new URL('/login', request.url))
    }
    
    // Check if user is admin
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()
    
    if (profile?.role !== 'admin') {
      return NextResponse.redirect(new URL('/dashboard', request.url))
    }
  }

  // Redirect authenticated users away from auth pages
  if (user && (pathname.startsWith('/login') || pathname.startsWith('/register'))) {
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }

  return response
}

export const config = {
  matcher: [
    '/((?!api|_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
