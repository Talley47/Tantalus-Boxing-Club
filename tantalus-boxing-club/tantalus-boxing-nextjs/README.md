# Tantalus Boxing Club - Next.js Production App

A production-ready virtual boxing league platform built with Next.js 15, Supabase, and modern web technologies.

## 🚀 Features

- **Authentication**: Secure user registration and login with Supabase Auth
- **Fighter Profiles**: Complete fighter management with physical stats and records
- **Matchmaking**: AI-powered fighter matching system
- **Tournaments**: Tournament creation and management
- **Real-time Updates**: Live notifications and updates
- **Media Hub**: Video uploads and social media integration
- **Analytics**: Comprehensive dashboards and reporting
- **Admin Panel**: Full administrative controls
- **Mobile Responsive**: Optimized for all devices

## 🛠 Tech Stack

- **Framework**: Next.js 15 (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Backend**: Supabase (Auth + Database + Storage + Real-time)
- **Deployment**: Vercel
- **Observability**: Sentry + PostHog
- **Rate Limiting**: Upstash Redis
- **Background Jobs**: Upstash QStash + Vercel Cron
- **Testing**: Vitest + Playwright

## 📋 Prerequisites

- Node.js 18+ 
- npm or yarn
- Supabase account
- Vercel account (for deployment)

## 🚀 Quick Start

### 1. Clone and Install

```bash
git clone <repository-url>
cd tantalus-boxing-nextjs
npm install
```

### 2. Environment Setup

```bash
cp env.example .env.local
```

Edit `.env.local` with your actual credentials:

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
```

### 3. Database Setup

1. Go to your Supabase dashboard
2. Navigate to SQL Editor
3. Copy and run the contents of `database/schema-fixed.sql`
4. Verify tables are created in Table Editor

### 4. Development Server

```bash
npm run dev
```

Visit [http://localhost:3000](http://localhost:3000)

## 📁 Project Structure

```
src/
├── app/                    # Next.js App Router pages
│   ├── (auth)/            # Authentication pages
│   ├── dashboard/          # Dashboard pages
│   ├── admin/             # Admin pages
│   └── api/               # API routes
├── components/            # Reusable UI components
├── lib/                   # Utilities and configurations
│   ├── supabase/          # Supabase client setup
│   ├── actions/           # Server actions
│   ├── validations/       # Zod schemas
│   └── rate-limit.ts      # Rate limiting
└── types/                 # TypeScript type definitions
```

## 🔧 Configuration

### Supabase Setup

1. Create a new Supabase project
2. Get your project URL and anon key from Settings → API
3. Set up Row Level Security (RLS) policies
4. Configure storage buckets for media uploads

### Rate Limiting

Configure Upstash Redis for rate limiting:

```env
UPSTASH_REDIS_REST_URL=https://your-redis-url.upstash.io
UPSTASH_REDIS_REST_TOKEN=your-redis-token
```

### Error Tracking

Set up Sentry for error tracking:

```bash
npx @sentry/wizard@latest -i nextjs
```

### Analytics

Configure PostHog for analytics:

```env
NEXT_PUBLIC_POSTHOG_KEY=your-posthog-key
NEXT_PUBLIC_POSTHOG_HOST=https://app.posthog.com
```

## 🚀 Deployment

### Vercel Deployment

1. Connect your GitHub repository to Vercel
2. Configure environment variables in Vercel dashboard
3. Deploy automatically on push to main branch

### Environment Variables

Set these in your Vercel project settings:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `UPSTASH_REDIS_REST_URL`
- `UPSTASH_REDIS_REST_TOKEN`
- `QSTASH_TOKEN`
- `SENTRY_DSN`
- `NEXT_PUBLIC_POSTHOG_KEY`

## 🧪 Testing

### Unit Tests

```bash
npm run test
```

### E2E Tests

```bash
npm run test:e2e
```

## 📊 Monitoring

- **Errors**: Sentry dashboard
- **Analytics**: PostHog dashboard
- **Performance**: Vercel Analytics
- **Database**: Supabase dashboard

## 🔒 Security

- Row Level Security (RLS) policies in Supabase
- Rate limiting on all API endpoints
- Input validation with Zod schemas
- CSRF protection
- Secure headers via middleware

## 📈 Performance

- Server Components for optimal performance
- Image optimization with Next.js Image
- Edge caching with Vercel
- Database query optimization
- Bundle size optimization

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For support, email support@tantalusboxing.com or create an issue in the repository.

---

**Built with ❤️ by TBC Promotions**