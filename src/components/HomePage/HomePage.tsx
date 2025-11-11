import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Avatar,
  Chip,
  LinearProgress,
  Alert,
  Badge,
  IconButton,
  Tabs,
  Tab,
  Container,
  Stack,
  Divider,
} from '@mui/material';
import {
  EmojiEvents,
  TrendingUp,
  Schedule,
  People,
  Notifications,
  LocationOn,
  Announcement,
  Article,
  Refresh,
  SportsMma,
  FitnessCenter,
  CalendarToday,
} from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { HomePageService, Fighter, ScheduledFight } from '../../services/homePageService';
import { useRealtime } from '../../contexts/RealtimeContext';
import { TournamentService } from '../../services/tournamentService';
import { NewsService, NewsItem } from '../../services/newsService';
import { trainingCampService } from '../../services/trainingCampService';
import { calloutService } from '../../services/calloutService';
import { supabase } from '../../services/supabase';
import NotificationBell from '../Shared/NotificationBell';
import { getTimezoneLabel } from '../../utils/timezones';
// Import FB cover Undisputed.png directly from src folder
import homePageBackground from '../../FB cover Undisputed.png';
// Import Logo1.png
import logo1 from '../../Logo1.png';

// Debug log
console.log('HomePage background image path:', homePageBackground);
console.log('HomePage background type:', typeof homePageBackground);

// Tab Panel Component
interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`simple-tabpanel-${index}`}
      aria-labelledby={`simple-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ p: 3 }}>{children}</Box>}
    </div>
  );
}

// Component to handle image loading errors (CORS, etc.)
const ImageWithFallback: React.FC<{ src: string; alt: string }> = ({ src, alt }) => {
  const [imageError, setImageError] = useState(false);

  return (
    <Box
      sx={{
        width: '100%',
        height: '200px',
        borderRadius: '8px',
        overflow: 'hidden',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        bgcolor: 'background.default',
      }}
    >
      {!imageError ? (
        <img
          src={src}
          alt={alt}
          onError={() => {
            // Silently handle CORS errors for external images (e.g., Facebook)
            // The placeholder will be shown instead
            setImageError(true);
          }}
          style={{
            width: '100%',
            height: '100%',
            objectFit: 'cover',
          }}
        />
      ) : (
        <Box
          sx={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            p: 2,
            color: 'text.secondary',
          }}
        >
          <Typography variant="caption" align="center">
            Image unavailable
          </Typography>
          <Typography variant="caption" align="center" sx={{ mt: 0.5 }}>
            (External link blocked)
          </Typography>
        </Box>
      )}
    </Box>
  );
};

const HomePage: React.FC = () => {
  const { fighterProfile, isAdmin } = useAuth();
  const navigate = useNavigate();
  const [tabValue, setTabValue] = useState(0);
  const [topFighters, setTopFighters] = useState<Fighter[]>([]);
  const [scheduledFights, setScheduledFights] = useState<ScheduledFight[]>([]);
  const [newsItems, setNewsItems] = useState<NewsItem[]>([]);
  const [activeTournaments, setActiveTournaments] = useState(0);
  const [trainingCamps, setTrainingCamps] = useState<Array<{
    id: string;
    inviter: any;
    invitee: any;
    startedAt: string;
    expiresAt: string;
    message: string | null;
  }>>([]);
  const [scheduledCallouts, setScheduledCallouts] = useState<Array<{
    id: string;
    scheduled_fight_id: string;
    caller: any;
    target: any;
    scheduled_date: string;
    weight_class: string;
    status: string;
    message: string | null;
  }>>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      setError(null);

      // Create promises with individual timeouts to prevent hanging
      const createTimeoutPromise = <T,>(promise: Promise<T>, timeoutMs: number = 10000, serviceName: string = 'Unknown'): Promise<T> => {
        return Promise.race([
          promise,
          new Promise<T>((_, reject) => 
            setTimeout(() => reject(new Error(`Request timeout for ${serviceName}`)), timeoutMs)
          )
        ]).catch((e: any) => {
          // Only log timeouts in development mode, and use warn instead of error
          if (process.env.NODE_ENV === 'development' && e.message?.includes('timeout')) {
            console.warn(`⏱️ ${serviceName} request timed out after ${timeoutMs}ms (non-critical)`);
          } else if (!e.message?.includes('timeout')) {
            console.error(`❌ ${serviceName} request failed:`, e);
          }
          return [] as T;
        });
      };

      // Load data using Promise.allSettled so individual failures don't block others
      const results = await Promise.allSettled([
        createTimeoutPromise(HomePageService.getTopFighters(30), 15000, 'Top Fighters'),
        createTimeoutPromise(HomePageService.getScheduledFights(10), 15000, 'Scheduled Fights'),
        createTimeoutPromise(NewsService.getNewsItems(20), 15000, 'News Items'),
        createTimeoutPromise(TournamentService.getTournaments('In Progress'), 15000, 'Tournaments'),
        createTimeoutPromise(trainingCampService.getAllActiveTrainingCamps(), 20000, 'Training Camps'), // Training camps might take longer
        createTimeoutPromise(calloutService.getScheduledCallouts(), 15000, 'Scheduled Callouts')
      ]);

      // Extract results, defaulting to empty arrays on failure
      const fighters = results[0].status === 'fulfilled' ? results[0].value : [];
      const fights = results[1].status === 'fulfilled' ? results[1].value : [];
      const news = results[2].status === 'fulfilled' ? results[2].value : [];
      const tournaments = results[3].status === 'fulfilled' ? results[3].value : [];
      const camps = results[4].status === 'fulfilled' ? results[4].value : [];
      const callouts = results[5].status === 'fulfilled' ? results[5].value : [];

      setTopFighters(fighters || []);
      setScheduledFights(fights || []);
      setNewsItems(news || []);
      setActiveTournaments(tournaments?.length || 0);
      // Map training camps to the expected format
      setTrainingCamps((camps || []).map(camp => ({
        id: camp.id,
        inviter: camp.inviter,
        invitee: camp.invitee,
        startedAt: camp.started_at || camp.created_at,
        expiresAt: camp.expires_at,
        message: camp.message || null
      })));
      // Set scheduled callouts
      setScheduledCallouts(callouts || []);

      // Log any failures for debugging
      results.forEach((result, index) => {
        if (result.status === 'rejected') {
          const serviceNames = ['fighters', 'fights', 'news', 'tournaments', 'training camps', 'callouts'];
          console.warn(`Failed to load ${serviceNames[index]}:`, result.reason);
        }
      });

    } catch (error: any) {
      console.error('Error loading dashboard data:', error);
      setError('Some data failed to load. Showing available data.');
      // Don't clear existing data - let what loaded successfully remain
    } finally {
      setLoading(false);
    }
  };

  const { subscribeToFightRecords, subscribeToFighterProfiles, subscribeToScheduledFights, subscribeToRankings } = useRealtime();

  useEffect(() => {
    // Load initial data
    loadDashboardData();

    // Set up real-time subscriptions for fight records, fighter profiles, scheduled fights, and rankings
    const unsubscribeFightRecords = subscribeToFightRecords((payload) => {
      console.log('Fight record changed:', payload);
      // Reload dashboard data when fight records change
      loadDashboardData();
    });

    const unsubscribeFighterProfiles = subscribeToFighterProfiles((payload) => {
      console.log('Fighter profile changed:', payload);
      // Reload dashboard data when profiles change (affects top fighters, points, tier, etc.)
      // Check if points, tier, or weight_class changed - these affect rankings
      const significantChange = 
        payload.old?.points !== payload.new?.points ||
        payload.old?.tier !== payload.new?.tier ||
        payload.old?.weight_class !== payload.new?.weight_class ||
        payload.old?.wins !== payload.new?.wins ||
        payload.old?.losses !== payload.new?.losses ||
        payload.old?.draws !== payload.new?.draws;
      
      if (significantChange) {
        console.log('Significant fighter profile change detected - reloading dashboard:', {
          points: `${payload.old?.points} → ${payload.new?.points}`,
          tier: `${payload.old?.tier} → ${payload.new?.tier}`,
          weight_class: `${payload.old?.weight_class} → ${payload.new?.weight_class}`
        });
        loadDashboardData();
      } else {
        // Still reload for other changes (name, physical info, etc.)
        loadDashboardData();
      }
    });

    const unsubscribeScheduledFights = subscribeToScheduledFights((payload) => {
      console.log('Scheduled fight changed:', payload);
      // Reload scheduled fights
      loadDashboardData();
    });

    const unsubscribeRankings = subscribeToRankings((payload) => {
      console.log('Rankings changed:', payload);
      // Reload top fighters when rankings change
      loadDashboardData();
    });

    // Subscribe to news changes for real-time updates
    const newsChannel = supabase
      .channel('home_news_updates')
      .on('postgres_changes',
        { event: '*', schema: 'public', table: 'news_announcements' },
        () => {
          console.log('News updated - reloading...');
          loadDashboardData();
        }
      )
      .subscribe();

    // Subscribe to training camp changes for real-time updates
    const trainingCampChannel = supabase
      .channel('home_training_camp_updates')
      .on('postgres_changes',
        { event: '*', schema: 'public', table: 'training_camp_invitations' },
        () => {
          console.log('Training camp updated - reloading...');
          loadDashboardData();
        }
      )
      .subscribe();

    // Subscribe to callout changes for real-time updates
    const calloutChannel = supabase
      .channel('home_callout_updates')
      .on('postgres_changes',
        { event: '*', schema: 'public', table: 'callout_requests' },
        () => {
          console.log('Callout updated - reloading...');
          loadDashboardData();
        }
      )
      .subscribe();

    // Cleanup subscriptions on unmount
    return () => {
      unsubscribeFightRecords();
      unsubscribeFighterProfiles();
      unsubscribeScheduledFights();
      unsubscribeRankings();
      supabase.removeChannel(newsChannel);
      supabase.removeChannel(trainingCampChannel);
      supabase.removeChannel(calloutChannel);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  const formatDate = (dateString: string) => {
    if (!dateString) return 'Unknown date';
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const formatDateTime = (dateString: string | null | undefined) => {
    if (!dateString) return 'Unknown date';
    try {
      const date = new Date(dateString);
      if (isNaN(date.getTime())) {
        console.error('Invalid date string:', dateString);
        return 'Invalid date';
      }
      return date.toLocaleString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: 'numeric',
        minute: '2-digit',
        hour12: true,
      });
    } catch (error) {
      console.error('Error formatting date:', error, dateString);
      return 'Invalid date';
    }
  };

  const formatTime = (timeString: string | null | undefined) => {
    if (!timeString) return 'TBD';
    try {
      // Handle time string formats (HH:MM:SS or HH:MM)
      if (timeString.includes(':')) {
        const parts = timeString.split(':');
        const hours = parseInt(parts[0], 10);
        const minutes = parseInt(parts[1], 10);
        if (isNaN(hours) || isNaN(minutes)) return 'TBD';
        const date = new Date();
        date.setHours(hours, minutes, 0, 0);
        return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: true });
      }
      // Handle ISO timestamp format
      const date = new Date(`2000-01-01T${timeString}`);
      if (isNaN(date.getTime())) return 'TBD';
      return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: true });
    } catch {
      return 'TBD';
    }
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <LinearProgress sx={{ width: '100%' }} />
      </Box>
    );
  }

  return (
    <>
      <Box
        component="div"
        sx={{
          backgroundImage: homePageBackground ? `url("${homePageBackground}")` : 'url("/FB cover Undisputed.png")',
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          backgroundRepeat: 'no-repeat',
          backgroundAttachment: 'fixed',
          minHeight: '100vh',
          width: '100vw',
          position: 'fixed',
          top: 0,
          left: 0,
          zIndex: -1,
          display: 'block',
        }}
      />
      <Container 
        maxWidth="xl" 
        sx={{ 
          py: 4,
          position: 'relative',
          zIndex: 1,
          backgroundColor: 'rgba(0, 0, 0, 0.2)',
          minHeight: '100vh'
        }}
      >
        {/* Content */}
        <Box>
          {/* Header Section */}
          <Box mb={4}>
            <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
              <Box display="flex" alignItems="center" gap={2}>
                <Box
                  component="img"
                  src={logo1}
                  alt="Tantalus Boxing League Logo"
                  sx={{
                    height: { xs: 60, md: 80 },
                    width: 'auto',
                    objectFit: 'contain',
                  }}
                />
                <Box>
                  <Typography variant="h3" gutterBottom sx={{ fontWeight: 'bold', color: 'white', textShadow: '2px 2px 4px rgba(0,0,0,0.8)' }}>
                    Tantalus Boxing League
                  </Typography>
                  <Typography variant="h6" sx={{ color: 'white', textShadow: '1px 1px 2px rgba(0,0,0,0.8)' }}>
                    Welcome back, {fighterProfile?.name || (isAdmin ? 'Admin' : 'Fighter')}!
                  </Typography>
                </Box>
              </Box>
              <Box display="flex" gap={2} alignItems="center">
                <NotificationBell />
                <IconButton onClick={loadDashboardData} color="primary" sx={{ color: 'white' }}>
                  <Refresh />
                </IconButton>
                {isAdmin && (
                  <Button
                    variant="contained"
                    startIcon={<Notifications />}
                    onClick={() => navigate('/admin')}
                  >
                    Admin Panel
                  </Button>
                )}
              </Box>
            </Box>
            
            {error && (
              <Alert severity="error" sx={{ mb: 3 }}>
                {error}
              </Alert>
            )}
          </Box>

          {/* Quick Stats */}
          <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 3, mb: 4 }}>
            <Box sx={{ flex: { xs: '1 1 100%', sm: '1 1 calc(50% - 12px)', md: '1 1 calc(25% - 18px)' }, minWidth: { xs: '100%', sm: 'calc(50% - 12px)', md: 'calc(25% - 18px)' } }}>
              <Card sx={{ height: '100%', background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' }}>
                <CardContent sx={{ color: 'white' }}>
                  <Box display="flex" alignItems="center" mb={2}>
                    <People sx={{ mr: 1, fontSize: 30 }} />
                    <Typography variant="h6">Total Fighters</Typography>
                  </Box>
                  <Typography variant="h3" sx={{ fontWeight: 'bold' }}>
                    {topFighters.length}
                  </Typography>
                </CardContent>
              </Card>
            </Box>
            <Box sx={{ flex: { xs: '1 1 100%', sm: '1 1 calc(50% - 12px)', md: '1 1 calc(25% - 18px)' }, minWidth: { xs: '100%', sm: 'calc(50% - 12px)', md: 'calc(25% - 18px)' } }}>
              <Card sx={{ height: '100%', background: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)' }}>
                <CardContent sx={{ color: 'white' }}>
                  <Box display="flex" alignItems="center" mb={2}>
                    <Schedule sx={{ mr: 1, fontSize: 30 }} />
                    <Typography variant="h6">Scheduled Fights</Typography>
                  </Box>
                  <Typography variant="h3" sx={{ fontWeight: 'bold' }}>
                    {scheduledFights.length}
                  </Typography>
                </CardContent>
              </Card>
            </Box>
            <Box sx={{ flex: { xs: '1 1 100%', sm: '1 1 calc(50% - 12px)', md: '1 1 calc(25% - 18px)' }, minWidth: { xs: '100%', sm: 'calc(50% - 12px)', md: 'calc(25% - 18px)' } }}>
              <Card sx={{ height: '100%', background: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)' }}>
                <CardContent sx={{ color: 'white' }}>
                  <Box display="flex" alignItems="center" mb={2}>
                    <EmojiEvents sx={{ mr: 1, fontSize: 30 }} />
                    <Typography variant="h6">Active Tournaments</Typography>
                  </Box>
                  <Typography variant="h3" sx={{ fontWeight: 'bold' }}>
                    {activeTournaments}
                  </Typography>
                </CardContent>
              </Card>
            </Box>
            <Box sx={{ flex: { xs: '1 1 100%', sm: '1 1 calc(50% - 12px)', md: '1 1 calc(25% - 18px)' }, minWidth: { xs: '100%', sm: 'calc(50% - 12px)', md: 'calc(25% - 18px)' } }}>
              <Card sx={{ height: '100%', background: 'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)' }}>
                <CardContent sx={{ color: 'white' }}>
                  <Box display="flex" alignItems="center" mb={2}>
                    <TrendingUp sx={{ mr: 1, fontSize: 30 }} />
                    <Typography variant="h6">League Activity</Typography>
                  </Box>
                  <Typography variant="h3" sx={{ fontWeight: 'bold' }}>
                    {topFighters.length > 0 ? Math.round((topFighters.filter(f => f.points > 0).length / topFighters.length) * 100) : 0}%
                  </Typography>
                </CardContent>
              </Card>
            </Box>
          </Box>

          {/* Main Content Tabs */}
          <Card sx={{ backgroundColor: 'rgba(255, 255, 255, 0.95)' }}>
            <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
              <Tabs 
                value={tabValue} 
                onChange={handleTabChange} 
                aria-label="homepage tabs"
                sx={{ '& .MuiTab-root': { color: 'white', textShadow: '1px 1px 2px rgba(0,0,0,0.8)' } }}
              >
                <Tab label="Top Fighters" />
                <Tab label="Scheduled Fights" />
                <Tab label="Training Camps" />
                <Tab label="Scheduled Rematches" />
                <Tab label="News & Announcements" />
              </Tabs>
            </Box>

            {/* Top Fighters Tab */}
            <TabPanel value={tabValue} index={0}>
              <Typography variant="h5" gutterBottom sx={{ mb: 3 }}>
                League Rankings - Top 30 Fighters
              </Typography>
              {topFighters.length === 0 ? (
                <Alert severity="info">
                  No fighters found. Register to join the league!
                </Alert>
              ) : (
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2 }}>
                  {topFighters.map((fighter, index) => (
                    <Box key={fighter.id} sx={{ flex: { xs: '1 1 100%', sm: '1 1 calc(50% - 8px)', md: '1 1 calc(33.333% - 11px)', lg: '1 1 calc(25% - 12px)' }, minWidth: { xs: '100%', sm: 'calc(50% - 8px)', md: 'calc(33.333% - 11px)', lg: 'calc(25% - 12px)' } }}>
                      <Card
                        sx={{
                          height: '100%',
                          background: index < 3 
                            ? 'linear-gradient(135deg, #ffd700 0%, #ffed4e 100%)'
                            : 'linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%)',
                          border: index < 3 ? '2px solid #ffd700' : '1px solid #dee2e6'
                        }}
                      >
                        <CardContent>
                          <Box display="flex" alignItems="center" mb={2}>
                            <Badge
                              badgeContent={index + 1}
                              color={index < 3 ? 'warning' : 'default'}
                              sx={{ mr: 2 }}
                            >
                              <Avatar
                                sx={{
                                  width: 50,
                                  height: 50,
                                  background: 'linear-gradient(45deg, #2196F3 30%, #21CBF3 90%)'
                                }}
                              >
                                {fighter.name.charAt(0)}
                              </Avatar>
                            </Badge>
                            <Box>
                              <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                                {fighter.name}
                              </Typography>
                              <Typography variant="body2" color="text.secondary">
                                @{fighter.handle}
                              </Typography>
                            </Box>
                          </Box>
                          <Box display="flex" justifyContent="space-between" mb={1}>
                            <Typography variant="body2">
                              <strong>{fighter.points}</strong> points
                            </Typography>
                            <Chip 
                              label={fighter.tier} 
                              size="small" 
                              color={fighter.tier === 'Diamond' ? 'primary' : 'default'}
                            />
                          </Box>
                          <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                            {fighter.weight_class} • {fighter.wins}W-{fighter.losses}L-{fighter.draws}D
                          </Typography>
                          
                          {/* Physical Information - Always Display (matches Fighter Profile format) */}
                          <Box sx={{ mt: 2, pt: 2, borderTop: '1px solid rgba(0,0,0,0.1)' }}>
                            <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 'bold', display: 'block', mb: 1 }}>
                              Physical Information
                            </Typography>
                            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.5 }}>
                              {/* Height - match Fighter Profile format exactly: {(fighterProfile as any).height_feet || 0}'{(fighterProfile as any).height_inches || 0}" */}
                              <Typography variant="caption" color="text.secondary">
                                <strong>Height:</strong> {fighter.height_feet || 0}'{fighter.height_inches || 0}"
                              </Typography>
                              
                              {/* Weight - match Fighter Profile format exactly: {fighterProfile.weight} lbs */}
                              <Typography variant="caption" color="text.secondary">
                                <strong>Weight:</strong> {fighter.weight || 0} lbs
                              </Typography>
                              
                              {/* Reach - match Fighter Profile format exactly: {fighterProfile.reach}" */}
                              <Typography variant="caption" color="text.secondary">
                                <strong>Reach:</strong> {fighter.reach || 0}"
                              </Typography>
                              
                              {/* Stance - match Fighter Profile format exactly: textTransform="capitalize" */}
                              <Typography variant="caption" color="text.secondary">
                                <strong>Stance:</strong> {fighter.stance ? (fighter.stance.charAt(0).toUpperCase() + fighter.stance.slice(1).toLowerCase()) : 'Not set'}
                              </Typography>
                              
                              {/* Hometown - match Fighter Profile format exactly */}
                              {fighter.hometown ? (
                                <Typography variant="caption" color="text.secondary">
                                  <strong>Hometown:</strong> {fighter.hometown}
                                </Typography>
                              ) : (
                                <Typography variant="caption" color="text.disabled">
                                  <strong>Hometown:</strong> Not set
                                </Typography>
                              )}
                              
                              {/* Trainer - match Fighter Profile format exactly */}
                              {fighter.trainer ? (
                                <Typography variant="caption" color="text.secondary">
                                  <strong>Trainer:</strong> {fighter.trainer}
                                </Typography>
                              ) : (
                                <Typography variant="caption" color="text.disabled">
                                  <strong>Trainer:</strong> Not set
                                </Typography>
                              )}
                              
                              {/* Gym - match Fighter Profile format exactly */}
                              {fighter.gym ? (
                                <Typography variant="caption" color="text.secondary">
                                  <strong>Gym:</strong> {fighter.gym}
                                </Typography>
                              ) : (
                                <Typography variant="caption" color="text.disabled">
                                  <strong>Gym:</strong> Not set
                                </Typography>
                              )}
                              
                              {/* Platform - match Fighter Profile format exactly */}
                              {fighter.platform ? (
                                <Typography variant="caption" color="text.secondary">
                                  <strong>Platform:</strong> {fighter.platform === 'PSN' ? 'PlayStation/PSN' : 
                                                               fighter.platform === 'Xbox' ? 'Xbox' : 
                                                               fighter.platform === 'PC' ? 'Steam/PC' : 
                                                               fighter.platform}
                                </Typography>
                              ) : (
                                <Typography variant="caption" color="text.disabled">
                                  <strong>Platform:</strong> Not set
                                </Typography>
                              )}
                              
                              {/* Timezone - match Fighter Profile format exactly */}
                              {fighter.timezone ? (
                                <Typography variant="caption" color="text.secondary">
                                  <strong>Timezone:</strong> {getTimezoneLabel(fighter.timezone)}
                                </Typography>
                              ) : (
                                <Typography variant="caption" color="text.disabled">
                                  <strong>Timezone:</strong> Not set
                                </Typography>
                              )}
                              
                              {/* Birthday - match Fighter Profile format exactly */}
                              {fighter.birthday ? (
                                <Typography variant="caption" color="text.secondary">
                                  <strong>Birthday:</strong> {(() => {
                                    try {
                                      // Parse date string manually to avoid timezone issues
                                      let dateStr: string;
                                      if (typeof fighter.birthday === 'string') {
                                        dateStr = fighter.birthday.split('T')[0];
                                      } else if (fighter.birthday && typeof fighter.birthday === 'object' && 'toISOString' in fighter.birthday) {
                                        // Handle Date object
                                        dateStr = (fighter.birthday as Date).toISOString().split('T')[0];
                                      } else {
                                        dateStr = String(fighter.birthday || '');
                                      }
                                      
                                      // Handle YYYY-MM-DD format
                                      const parts = dateStr.split('-');
                                      if (parts.length === 3) {
                                        const year = parseInt(parts[0], 10);
                                        const month = parseInt(parts[1], 10) - 1; // Month is 0-indexed
                                        const day = parseInt(parts[2], 10);
                                        const date = new Date(year, month, day);
                                        
                                        if (isNaN(date.getTime())) return 'Invalid date';
                                        return date.toLocaleDateString('en-US', { 
                                          year: 'numeric', 
                                          month: 'long', 
                                          day: 'numeric' 
                                        });
                                      }
                                      
                                      // Fallback to standard parsing
                                      const date = new Date(dateStr);
                                      if (isNaN(date.getTime())) return 'Invalid date';
                                      return date.toLocaleDateString('en-US', { 
                                        year: 'numeric', 
                                        month: 'long', 
                                        day: 'numeric' 
                                      });
                                    } catch {
                                      return 'Invalid date';
                                    }
                                  })()}
                                </Typography>
                              ) : (
                                <Typography variant="caption" color="text.disabled">
                                  <strong>Birthday:</strong> Not set
                                </Typography>
                              )}
                            </Box>
                          </Box>
                        </CardContent>
                      </Card>
                    </Box>
                  ))}
                </Box>
              )}
            </TabPanel>

            {/* Scheduled Fights Tab */}
            <TabPanel value={tabValue} index={1}>
              <Typography variant="h5" gutterBottom sx={{ mb: 3 }}>
                Scheduled Mandatory Fights
              </Typography>
              {scheduledFights.length === 0 ? (
                <Alert severity="info">
                  No scheduled fights at the moment. Check back later!
                </Alert>
              ) : (
                <Stack spacing={2}>
                  {scheduledFights.map((fight) => (
                    <Card key={fight.id} sx={{ p: 2 }}>
                      <CardContent>
                        <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                          <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                            {fight.fighter1?.name || 'TBD'} vs {fight.fighter2?.name || 'TBD'}
                          </Typography>
                          <Chip label={fight.status} color="primary" />
                        </Box>
                        <Box display="flex" alignItems="center" gap={2} mb={1}>
                          <Box display="flex" alignItems="center">
                            <Schedule sx={{ mr: 1, fontSize: 16 }} />
                            <Typography variant="body2">
                              {fight.scheduled_time ? formatTime(fight.scheduled_time) : 'TBD'}
                            </Typography>
                          </Box>
                          <Box display="flex" alignItems="center">
                            <LocationOn sx={{ mr: 1, fontSize: 16 }} />
                            <Typography variant="body2">{fight.venue}</Typography>
                          </Box>
                        </Box>
                        <Typography variant="body2" color="text.secondary">
                          {fight.weight_class} • {fight.timezone ? getTimezoneLabel(fight.timezone) : 'UTC'}
                        </Typography>
                      </CardContent>
                    </Card>
                  ))}
                </Stack>
              )}
            </TabPanel>

            {/* Training Camps Tab */}
            <TabPanel value={tabValue} index={2}>
              <Typography variant="h5" gutterBottom sx={{ mb: 3 }}>
                League Active Training Camps
              </Typography>
              {trainingCamps.length === 0 ? (
                <Alert severity="info">
                  No active training camps in the league at the moment. Go to Matchmaking → Training Camp to send invitations!
                </Alert>
              ) : (
                <Stack spacing={3}>
                  {trainingCamps.map((camp) => {
                    const expiresAt = new Date(camp.expiresAt);
                    const now = new Date();
                    const hoursRemaining = Math.max(0, Math.floor((expiresAt.getTime() - now.getTime()) / (1000 * 60 * 60)));
                    const daysRemaining = Math.floor(hoursRemaining / 24);
                    const hoursInDay = hoursRemaining % 24;

                    return (
                      <Card key={camp.id} sx={{ p: 2 }}>
                        <CardContent>
                          <Box display="flex" alignItems="center" mb={2} gap={2}>
                            <FitnessCenter sx={{ color: 'primary.main', fontSize: 30 }} />
                            <Box flex={1}>
                              <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                                {camp.inviter?.name || 'Unknown Fighter'} & {camp.invitee?.name || 'Unknown Fighter'}
                              </Typography>
                              <Typography variant="body2" color="text.secondary">
                                Training Camp • Started: {formatDateTime(camp.startedAt)}
                              </Typography>
                            </Box>
                            <Chip 
                              label={`${daysRemaining}d ${hoursInDay}h remaining`}
                              color={hoursRemaining < 24 ? 'error' : hoursRemaining < 48 ? 'warning' : 'success'}
                              size="small"
                            />
                          </Box>
                          
                          <Divider sx={{ my: 2 }} />
                          
                          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 2 }}>
                            {/* Inviter */}
                            <Card variant="outlined" sx={{ p: 1.5 }}>
                              <Box display="flex" alignItems="center" gap={1}>
                                <Avatar
                                  sx={{
                                    width: 40,
                                    height: 40,
                                    background: 'linear-gradient(45deg, #2196F3 30%, #21CBF3 90%)'
                                  }}
                                >
                                  {camp.inviter?.name?.charAt(0) || '?'}
                                </Avatar>
                                <Box flex={1}>
                                  <Typography variant="body1" sx={{ fontWeight: 'bold' }}>
                                    {camp.inviter?.name || 'Unknown Fighter'}
                                  </Typography>
                                  <Typography variant="caption" color="text.secondary">
                                    @{camp.inviter?.handle || 'unknown'} • {camp.inviter?.tier || 'Amateur'} • {camp.inviter?.points || 0} pts
                                  </Typography>
                                </Box>
                              </Box>
                            </Card>

                            {/* Invitee */}
                            <Card variant="outlined" sx={{ p: 1.5 }}>
                              <Box display="flex" alignItems="center" gap={1}>
                                <Avatar
                                  sx={{
                                    width: 40,
                                    height: 40,
                                    background: 'linear-gradient(45deg, #4CAF50 30%, #8BC34A 90%)'
                                  }}
                                >
                                  {camp.invitee?.name?.charAt(0) || '?'}
                                </Avatar>
                                <Box flex={1}>
                                  <Typography variant="body1" sx={{ fontWeight: 'bold' }}>
                                    {camp.invitee?.name || 'Unknown Fighter'}
                                  </Typography>
                                  <Typography variant="caption" color="text.secondary">
                                    @{camp.invitee?.handle || 'unknown'} • {camp.invitee?.tier || 'Amateur'} • {camp.invitee?.points || 0} pts
                                  </Typography>
                                </Box>
                              </Box>
                            </Card>
                          </Box>
                          
                          {camp.message && (
                            <Box mt={2}>
                              <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic' }}>
                                "{camp.message}"
                              </Typography>
                            </Box>
                          )}
                          
                          <Box mt={2} display="flex" alignItems="center" gap={1}>
                            <Schedule sx={{ fontSize: 16, color: 'text.secondary' }} />
                            <Typography variant="caption" color="text.secondary">
                              Expires: {formatDateTime(camp.expiresAt)}
                            </Typography>
                          </Box>
                        </CardContent>
                      </Card>
                    );
                  })}
                </Stack>
              )}
            </TabPanel>

            {/* Scheduled Rematches Tab */}
            <TabPanel value={tabValue} index={3}>
              <Typography variant="h5" gutterBottom sx={{ mb: 3 }}>
                Scheduled Rematches
              </Typography>
              {scheduledCallouts.length === 0 ? (
                <Alert severity="info">
                  No scheduled rematches at the moment. Go to Matchmaking → Rematches to request rematches with fighters you've fought before!
                </Alert>
              ) : (
                <Stack spacing={3}>
                  {scheduledCallouts.map((callout) => (
                    <Card key={callout.id} sx={{ p: 2, borderLeft: '4px solid', borderLeftColor: 'error.main' }}>
                      <CardContent>
                        <Box display="flex" alignItems="center" mb={2} gap={2}>
                          <SportsMma sx={{ color: 'error.main', fontSize: 30 }} />
                          <Box flex={1}>
                            <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                              {callout.caller?.name || 'Unknown Fighter'} vs {callout.target?.name || 'Unknown Fighter'}
                            </Typography>
                            <Typography variant="body2" color="text.secondary">
                              Rematch • {callout.weight_class}
                            </Typography>
                          </Box>
                          <Chip 
                            label="Scheduled"
                            color="error"
                            size="small"
                          />
                        </Box>
                        
                        <Divider sx={{ my: 2 }} />
                        
                        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 2 }}>
                          {/* Caller */}
                          <Card variant="outlined" sx={{ p: 1.5 }}>
                            <Box display="flex" alignItems="center" gap={1}>
                              <Avatar
                                sx={{
                                  width: 40,
                                  height: 40,
                                  background: 'linear-gradient(45deg, #f44336 30%, #e91e63 90%)'
                                }}
                              >
                                {callout.caller?.name?.charAt(0) || '?'}
                              </Avatar>
                              <Box flex={1}>
                                <Typography variant="body1" sx={{ fontWeight: 'bold' }}>
                                  {callout.caller?.name || 'Unknown Fighter'}
                                </Typography>
                                <Typography variant="caption" color="text.secondary">
                                  @{callout.caller?.handle || 'unknown'} • {callout.caller?.tier || 'Amateur'} • {callout.caller?.points || 0} pts
                                </Typography>
                              </Box>
                            </Box>
                          </Card>

                          {/* Target */}
                          <Card variant="outlined" sx={{ p: 1.5 }}>
                            <Box display="flex" alignItems="center" gap={1}>
                              <Avatar
                                sx={{
                                  width: 40,
                                  height: 40,
                                  background: 'linear-gradient(45deg, #ff9800 30%, #ff5722 90%)'
                                }}
                              >
                                {callout.target?.name?.charAt(0) || '?'}
                              </Avatar>
                              <Box flex={1}>
                                <Typography variant="body1" sx={{ fontWeight: 'bold' }}>
                                  {callout.target?.name || 'Unknown Fighter'}
                                </Typography>
                                <Typography variant="caption" color="text.secondary">
                                  @{callout.target?.handle || 'unknown'} • {callout.target?.tier || 'Amateur'} • {callout.target?.points || 0} pts
                                </Typography>
                              </Box>
                            </Box>
                          </Card>
                        </Box>
                        
                        {callout.message && (
                          <Box mt={2}>
                            <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic' }}>
                              "{callout.message}"
                            </Typography>
                          </Box>
                        )}
                        
                        <Box mt={2} display="flex" alignItems="center" gap={1}>
                          <Schedule sx={{ fontSize: 16, color: 'text.secondary' }} />
                          <Typography variant="caption" color="text.secondary">
                            Scheduled: {callout.scheduled_date ? formatDateTime(callout.scheduled_date) : 'TBD'}
                          </Typography>
                        </Box>
                      </CardContent>
                    </Card>
                  ))}
                </Stack>
              )}
            </TabPanel>

            {/* News & Announcements Tab */}
            <TabPanel value={tabValue} index={4}>
              <Typography variant="h5" gutterBottom sx={{ mb: 3 }}>
                Latest News & Announcements
              </Typography>
              {newsItems.length === 0 ? (
                <Alert severity="info">
                  No news or announcements at the moment.
                </Alert>
              ) : (
                <Stack spacing={2}>
                  {newsItems.map((item) => (
                    <Card key={item.id}>
                      <CardContent>
                        <Box display="flex" alignItems="center" mb={2}>
                          {item.type === 'announcement' ? (
                            <Announcement sx={{ mr: 1, color: 'primary.main' }} />
                          ) : item.type === 'blog' ? (
                            <Article sx={{ mr: 1, color: 'secondary.main' }} />
                          ) : item.type === 'fight_result' ? (
                            <SportsMma sx={{ mr: 1, color: 'error.main' }} />
                          ) : (
                            <Article sx={{ mr: 1, color: 'info.main' }} />
                          )}
                          <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                            {item.title}
                          </Typography>
                          <Chip 
                            label={item.type.replace('_', ' ')} 
                            size="small" 
                            color={
                              item.type === 'fight_result' ? 'error' :
                              item.type === 'announcement' ? 'warning' :
                              item.type === 'blog' ? 'info' : 'default'
                            }
                            sx={{ ml: 1 }}
                          />
                          <Chip 
                            label={item.priority} 
                            size="small" 
                            color={item.priority === 'high' ? 'error' : item.priority === 'medium' ? 'warning' : 'default'}
                            sx={{ ml: 1 }}
                          />
                          {item.is_featured && (
                            <Chip 
                              label="Featured" 
                              size="small" 
                              color="primary"
                              sx={{ ml: 1 }}
                            />
                          )}
                        </Box>
                        
                        {/* Featured Image */}
                        {item.featured_image && (
                          <Box sx={{ mb: 2 }}>
                            <img
                              src={item.featured_image}
                              alt={item.title}
                              style={{
                                width: '100%',
                                maxHeight: '300px',
                                objectFit: 'cover',
                                borderRadius: '8px',
                              }}
                            />
                          </Box>
                        )}

                        {/* Content */}
                        <Typography 
                          variant="body1" 
                          sx={{ mb: 2, whiteSpace: 'pre-wrap' }}
                        >
                          {item.content}
                        </Typography>

                        {/* Images */}
                        {item.images && item.images.length > 0 && (
                          <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 2, mb: 2 }}>
                            {item.images.map((img, idx) => (
                              <ImageWithFallback key={idx} src={img} alt={`${item.title} - Image ${idx + 1}`} />
                            ))}
                          </Box>
                        )}

                        {/* Fight Results */}
                        {item.type === 'fight_result' && item.fight_results && item.fight_results.length > 0 && (
                          <Box sx={{ mb: 2, p: 2, bgcolor: 'background.default', borderRadius: 1 }}>
                            <Typography variant="subtitle2" gutterBottom>
                              Fight Results:
                            </Typography>
                            {item.fight_results.map((result, idx) => (
                              <Box key={idx} sx={{ mb: 1 }}>
                                <Typography variant="body2">
                                  <strong>{result.fighter1_name}</strong> vs <strong>{result.fighter2_name}</strong>
                                  {result.winner_name && (
                                    <> - Winner: <strong style={{ color: '#d32f2f' }}>{result.winner_name}</strong></>
                                  )}
                                  {result.result_method && ` (${result.result_method})`}
                                  {result.round && ` - Round ${result.round}`}
                                </Typography>
                              </Box>
                            ))}
                          </Box>
                        )}

                        {/* Tags */}
                        {item.tags && item.tags.length > 0 && (
                          <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap', mb: 2 }}>
                            {item.tags.map((tag, idx) => (
                              <Chip key={idx} label={tag} size="small" variant="outlined" />
                            ))}
                          </Box>
                        )}

                        <Box display="flex" justifyContent="space-between" alignItems="center">
                          <Box>
                            <Typography variant="caption" color="text.secondary">
                              By {item.author}
                              {item.author_title && ` - ${item.author_title}`}
                            </Typography>
                          </Box>
                          <Box display="flex" flexDirection="column" alignItems="flex-end">
                            <Typography variant="caption" color="text.secondary">
                              {item.published_at ? formatDateTime(item.published_at) : formatDateTime(item.created_at)}
                            </Typography>
                            {item.published_at && item.created_at && item.created_at !== item.published_at && (
                              <Typography variant="caption" color="text.secondary" sx={{ fontSize: '0.65rem', fontStyle: 'italic', mt: 0.5 }}>
                                Created: {formatDateTime(item.created_at)}
                              </Typography>
                            )}
                          </Box>
                        </Box>
                      </CardContent>
                    </Card>
                  ))}
                </Stack>
              )}
            </TabPanel>
          </Card>
        </Box>
      </Container>
    </>
  );
};

export default HomePage;