import React, { useState, useEffect, useRef, useMemo, useCallback, memo } from 'react';
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
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  CircularProgress,
  Tooltip,
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
import { useNavigate, useLocation } from 'react-router-dom';
import { HomePageService, Fighter, ScheduledFight } from '../../services/homePageService';
import { useRealtime } from '../../contexts/RealtimeContext';
import { TournamentService } from '../../services/tournamentService';
import { NewsService, NewsItem } from '../../services/newsService';
import { trainingCampService } from '../../services/trainingCampService';
import { calloutService } from '../../services/calloutService';
import { supabase } from '../../services/supabase';
import NotificationBell from '../Shared/NotificationBell';
import EmojiReactions from '../News/EmojiReactions';
import { getTimezoneLabel } from '../../utils/timezones';
import { fighterSanctionService, SanctionFighter, SanctionUnlockInfo } from '../../services/fighterSanctionService';
import { notificationService } from '../../services/notificationService';
// Import TBC Homepage.png directly from src folder
import homePageBackground from '../../TBC Homepage.png';
// Import Logo1.png
import logo1 from '../../Logo1.png';
// Import sanction images
import tbcaImage from '../../TBCA Tantalus Boxing Club Amateur Association.png';
import tbfImage from '../../TBF Tantalus Boxing Federation.png';
import tbaImage from '../../TBA Tantalus Boxing Association.png';
import tboImage from '../../TBO Tantalus Boxing Organization.png';
import tbcImage from '../../TBC Tantalus Boxing Council.png';
import trmImage from '../../TRM Tantalus Ring Magazine.png';

// Debug log
console.log('HomePage background image path:', homePageBackground);
console.log('HomePage background type:', typeof homePageBackground);

// Utility function for formatting birthdays - extracted outside component to prevent recreation
const formatBirthday = (birthday: string | undefined): string => {
  if (!birthday) return 'Not set';
  try {
    const dateStr = typeof birthday === 'string' 
      ? birthday.split('T')[0] 
      : String(birthday);
    const parts = dateStr.split('-');
    if (parts.length === 3) {
      const year = parseInt(parts[0], 10);
      const month = parseInt(parts[1], 10) - 1;
      const day = parseInt(parts[2], 10);
      const date = new Date(year, month, day);
      if (isNaN(date.getTime())) return 'Not set';
      return date.toLocaleDateString('en-US', { 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric' 
      });
    }
    const date = new Date(dateStr);
    if (isNaN(date.getTime())) return 'Not set';
    return date.toLocaleDateString('en-US', { 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric' 
    });
  } catch {
    return 'Not set';
  }
};

// Tab Panel Component - Memoized for performance
interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

const TabPanel = memo(function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`simple-tabpanel-${index}`}
      aria-labelledby={`simple-tab-${index}`}
      {...other}
      style={{ display: value === index ? 'block' : 'none' }}
    >
      {value === index && <Box sx={{ p: 3, minHeight: '400px' }}>{children}</Box>}
    </div>
  );
});

// Component to handle image loading errors (CORS, etc.)
const ImageWithFallback: React.FC<{ src: string; alt: string; maxHeight?: string }> = ({ src, alt, maxHeight = '200px' }) => {
  const [imageError, setImageError] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const imgRef = useRef<HTMLImageElement>(null);

  // Check if URL is from Facebook or other blocked domains
  const isBlockedDomain = src.includes('facebook.com') || src.includes('fbcdn.net') || src.includes('fbid');

  // If it's a blocked domain, skip loading entirely
  useEffect(() => {
    if (isBlockedDomain) {
      setImageError(true);
      setIsLoading(false);
    }
  }, [isBlockedDomain]);

  const handleError = (e: React.SyntheticEvent<HTMLImageElement, Event>) => {
    // Silently handle CORS errors for external images (e.g., Facebook)
    // Prevent error from bubbling to console
    e.preventDefault();
    e.stopPropagation();
    
    // Suppress console errors for known blocked domains
    if (isBlockedDomain) {
      // These errors are expected and handled gracefully
      return;
    }
    
    setImageError(true);
    setIsLoading(false);
  };

  // Don't even attempt to load if it's a blocked domain
  if (isBlockedDomain) {
    return (
      <Box
        sx={{
          width: '100%',
          height: maxHeight,
          maxHeight: maxHeight,
          borderRadius: '8px',
          overflow: 'hidden',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          bgcolor: 'background.default',
          p: 2,
        }}
      >
        <Typography variant="caption" align="center" color="text.secondary">
          Image unavailable
        </Typography>
        <Typography variant="caption" align="center" sx={{ mt: 0.5, fontSize: '0.7rem' }}>
          (Facebook images cannot be embedded due to privacy restrictions)
        </Typography>
      </Box>
    );
  }

  return (
    <Box
      sx={{
        width: '100%',
        height: maxHeight,
        maxHeight: maxHeight,
        borderRadius: '8px',
        overflow: 'hidden',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        bgcolor: 'background.default',
        position: 'relative',
      }}
    >
      {!imageError ? (
        <img
          ref={imgRef}
          src={src}
          alt={alt}
          onError={handleError}
          onLoad={() => {
            setIsLoading(false);
          }}
          style={{
            width: '100%',
            height: '100%',
            objectFit: 'cover',
            display: isLoading ? 'none' : 'block',
          }}
          crossOrigin="anonymous"
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
            height: '100%',
          }}
        >
          <Typography variant="caption" align="center">
            Image unavailable
          </Typography>
        </Box>
      )}
      {isLoading && !imageError && (
        <Box
          sx={{
            position: 'absolute',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            width: '100%',
            height: '100%',
            bgcolor: 'background.default',
          }}
        >
          <Typography variant="caption" color="text.secondary">
            Loading...
          </Typography>
        </Box>
      )}
    </Box>
  );
};

const HomePage: React.FC = () => {
  const { fighterProfile, isAdmin, user, loading: authLoading } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [tabValue, setTabValue] = useState(0);
  
  // Check URL hash/query params to set initial tab (e.g., for notifications)
  // This runs on mount and whenever the location changes
  useEffect(() => {
    const hash = window.location.hash;
    const searchParams = new URLSearchParams(window.location.search);
    
    // Check for #news hash or ?tab=news query param
    if (hash === '#news' || searchParams.get('tab') === 'news') {
      setTabValue(4); // News & Announcements tab is index 4
      // Clear the hash/query param after setting tab
      if (hash === '#news') {
        window.history.replaceState(null, '', window.location.pathname);
      } else if (searchParams.get('tab') === 'news') {
        // Remove the query param but keep the pathname
        const newUrl = window.location.pathname;
        window.history.replaceState(null, '', newUrl);
      }
    }
  }, [location]); // Re-run when location changes
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
  const [sanctionSearch, setSanctionSearch] = useState('');
  const [sanctionSearchDebounced, setSanctionSearchDebounced] = useState('');
  const [sanctionTypeFilter, setSanctionTypeFilter] = useState<string>('');
  
  // Debounce search input to reduce input delay
  useEffect(() => {
    const timer = setTimeout(() => {
      setSanctionSearchDebounced(sanctionSearch);
    }, 300); // 300ms debounce delay
    
    return () => clearTimeout(timer);
  }, [sanctionSearch]);
  const [selectedSanction, setSelectedSanction] = useState<string | null>(null);
  const [sanctionFighters, setSanctionFighters] = useState<SanctionFighter[]>([]);
  const [loadingFighters, setLoadingFighters] = useState(false);
  const [joinedSanctions, setJoinedSanctions] = useState<Set<string>>(new Set());
  const [joiningSanction, setJoiningSanction] = useState<string | null>(null);
  const [sanctionStatuses, setSanctionStatuses] = useState<Map<string, SanctionUnlockInfo>>(new Map());

  // Memoize sanctions list and filtered results for performance (must be before any returns)
  const allSanctions = useMemo(() => [
    {
      acronym: 'TBCA',
      name: 'Tantalus Boxing Club Amateur Association',
      type: 'Association',
      description: 'Governing amateur bouts and club-level competitions under Tantalus rules. (Amateur: 0-29 pts)',
      image: tbcaImage,
    },
    {
      acronym: 'TBA',
      name: 'Tantalus Boxing Association',
      type: 'Association',
      description: 'Oversees regional events and standardized amateur rankings. (Semi-Pro: 30-69 pts)',
      image: tbaImage,
    },
    {
      acronym: 'TBO',
      name: 'Tantalus Boxing Organization',
      type: 'Organization',
      description: 'Professional-level sanctioning body for title fights and promotions. (Pro: 70-139 pts)',
      image: tboImage,
    },
    {
      acronym: 'TBF',
      name: 'Tantalus Boxing Federation',
      type: 'Federation',
      description: 'International liaison for cross-federation events and regulations. (Contender: 140-279 pts)',
      image: tbfImage,
    },
    {
      acronym: 'TBC',
      name: 'Tantalus Boxing Council',
      type: 'Council',
      description: 'Advisory council for rules, safety standards, and judging criteria. (Elite: 280+ pts)',
      image: tbcImage,
    },
    {
      acronym: 'TRM',
      name: 'Tantalus Ring Magazine',
      type: 'Magazine',
      description: 'Official rankings, features, and coverage of Tantalus-sanctioned bouts. (560+ pts)',
      image: trmImage,
    },
  ], []);

  const filteredSanctions = useMemo(() => {
    return allSanctions.filter((sanction) => {
      if (sanctionSearchDebounced) {
        const searchLower = sanctionSearchDebounced.toLowerCase();
        if (!sanction.acronym.toLowerCase().includes(searchLower) && 
            !sanction.name.toLowerCase().includes(searchLower)) {
          return false;
        }
      }
      if (sanctionTypeFilter && sanction.type !== sanctionTypeFilter) {
        return false;
      }
      return true;
    });
  }, [allSanctions, sanctionSearchDebounced, sanctionTypeFilter]);

  const fighterPoints = useMemo(() => fighterProfile?.points || 0, [fighterProfile?.points]);

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

  // Memoize handleTabChange to prevent unnecessary re-renders
  const handleTabChange = useCallback((event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  }, []);

  // Load joined sanctions and calculate statuses for current user
  useEffect(() => {
    const loadSanctionData = async () => {
      const userId = user?.id || fighterProfile?.user_id;
      
      // Enhanced debug logging (only in development)
      if (process.env.NODE_ENV === 'development') {
        console.log('Debug: Loading sanction data', {
          userId,
          user_id: user?.id,
          fighterProfile_user_id: fighterProfile?.user_id,
          fighterProfile_id: fighterProfile?.id,
          fighterProfile_points: fighterProfile?.points,
          hasFighterProfile: !!fighterProfile,
          authLoading,
          tabValue,
        });
      }
      
      // More defensive check - ensure we have both user ID and fighter profile
      if (userId && fighterProfile && !authLoading) {
        try {
          const sanctions = await fighterSanctionService.getSanctionsByFighter(userId);
          const joinedSet = new Set(sanctions);
          setJoinedSanctions(joinedSet);

          // Calculate status for each sanction
          const fighterPoints = fighterProfile.points || 0;
          
          if (process.env.NODE_ENV === 'development') {
            console.log('Debug: Fighter points:', fighterPoints, 'Joined sanctions:', Array.from(joinedSet));
          }
          
          const statusMap = new Map<string, SanctionUnlockInfo>();
          const sanctionAcronyms = ['TBCA', 'TBA', 'TBO', 'TBF', 'TBC', 'TRM'];
          
          let previousPendingSanction: string | null = null;
          
          sanctionAcronyms.forEach(acronym => {
            const status = fighterSanctionService.getSanctionStatus(acronym, fighterPoints);
            statusMap.set(acronym, status);
            
            if (process.env.NODE_ENV === 'development') {
              console.log(`Debug: Sanction ${acronym} status:`, {
                status: status.status,
                requiredPoints: status.requiredPoints,
                currentPoints: status.currentPoints,
                isJoined: joinedSet.has(acronym),
              });
            }
            
            // Check if this sanction just became pending (halfway through previous tier)
            if (status.status === 'pending' && !previousPendingSanction) {
              previousPendingSanction = acronym;
              // Check if we should send a notification (only once)
              checkAndNotifyPendingSanction(userId, acronym, status, 'pending');
            }
            
            // Check if this sanction just became active (unlocked) and fighter hasn't joined yet
            if (status.status === 'active' && !joinedSet.has(acronym)) {
              checkAndNotifyPendingSanction(userId, acronym, status, 'active');
            }
          });
          
          setSanctionStatuses(statusMap);
          
          if (process.env.NODE_ENV === 'development') {
            console.log('Debug: Sanction statuses set:', Array.from(statusMap.entries()));
          }
        } catch (error) {
          console.error('Error loading sanction data:', error);
        }
      } else {
        console.log('Debug: Cannot load sanction data - missing userId or fighterProfile', {
          userId: !!userId,
          hasFighterProfile: !!fighterProfile,
        });
      }
    };

    const checkAndNotifyPendingSanction = async (userId: string, sanctionAcronym: string, status: SanctionUnlockInfo, notificationType: 'pending' | 'active') => {
      try {
        const sanctionNames: { [key: string]: string } = {
          'TBCA': 'Tantalus Boxing Club Amateur Association',
          'TBA': 'Tantalus Boxing Association',
          'TBO': 'Tantalus Boxing Organization',
          'TBF': 'Tantalus Boxing Federation',
          'TBC': 'Tantalus Boxing Council',
          'TRM': 'Tantalus Ring Magazine',
        };

        // Check if we've already notified about this sanction in this state
        const notificationMessage = notificationType === 'pending'
          ? `You're halfway to unlocking ${sanctionNames[sanctionAcronym]}!`
          : `${sanctionNames[sanctionAcronym]} is now available!`;
        
        const { data: existingNotifications } = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('type', 'Sanction')
          .like('message', `%${sanctionAcronym}%`)
          .limit(1);

        // Only notify if:
        // 1. For pending: no existing notification for this sanction
        // 2. For active: no existing notification AND fighter hasn't joined yet
        const shouldNotify = !existingNotifications || existingNotifications.length === 0;
        
        if (shouldNotify) {
          const message = notificationType === 'pending'
            ? `You're halfway to unlocking ${sanctionNames[sanctionAcronym]}! Keep fighting to unlock this sanction at ${status.requiredPoints} points.`
            : `${sanctionNames[sanctionAcronym]} is now available! You can now join this sanction.`;
          
          const title = notificationType === 'pending'
            ? 'New Boxing Sanction Pending'
            : 'New Boxing Sanction Available';

          try {
            await notificationService.createNotification(
              userId,
              'Sanction',
              title,
              message,
              '/home?tab=sanctions'
            );
          } catch (notificationError: any) {
            // If the error is about the notification type not being allowed,
            // log a helpful message but don't break the app
            if (notificationError?.message?.includes('type') || notificationError?.code === '23514') {
              console.warn('Sanction notification type not yet added to database. Please run add-sanction-notification-type.sql in Supabase SQL Editor.');
            } else {
              console.error('Error creating sanction notification:', notificationError);
            }
          }
        }
      } catch (error) {
        console.error('Error checking/creating sanction notification:', error);
      }
    };

    // Load data when:
    // 1. Boxing Sanctions tab is open (tabValue === 5)
    // 2. Auth is not loading
    // 3. User and fighter profile are available
    if (tabValue === 5 && !authLoading) {
      if (user?.id && fighterProfile) {
        loadSanctionData();
      } else {
        // If tab is open but data isn't ready, log for debugging (only in development)
        if (process.env.NODE_ENV === 'development') {
          console.log('Debug: Tab open but waiting for user/fighter profile', {
            hasUser: !!user?.id,
            hasFighterProfile: !!fighterProfile,
            authLoading,
          });
        }
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user?.id, fighterProfile?.user_id, fighterProfile?.points, fighterProfile?.id, tabValue, authLoading]);

  // Handle joining a sanction - memoized with useCallback
  const handleJoinSanction = useCallback(async (sanctionAcronym: string) => {
    const userId = user?.id || fighterProfile?.user_id;
    
    if (!userId) {
      setError('You must be logged in to join a sanction. Please refresh the page if you are already logged in.');
      return;
    }

    setJoiningSanction(sanctionAcronym);
    try {
      await fighterSanctionService.joinSanction(sanctionAcronym, userId);
      setJoinedSanctions(prev => {
        const newSet = new Set(prev);
        newSet.add(sanctionAcronym);
        return newSet;
      });
      // Refresh fighters if dialog is open
      if (selectedSanction === sanctionAcronym) {
        await loadSanctionFighters(sanctionAcronym);
      }
      // Statuses don't need to be recalculated - they're based on points, not membership
    } catch (error: any) {
      console.error('Error joining sanction:', error);
      console.error('Error details:', {
        code: error.code,
        message: error.message,
        details: error.details,
        hint: error.hint,
      });
      
      const errorMessage = error.message || 'Failed to join sanction';
      
      // Provide specific error messages based on error type
      if (errorMessage.includes('Fighter profile not found')) {
        setError('Fighter profile not found. Please complete your fighter profile in "My Profile" first, then try joining again.');
      } else if (error.code === '42P01' || errorMessage.includes('does not exist')) {
        setError('The sanctions database table has not been set up yet. Please contact an administrator to run the database migration script: create-fighter-sanctions-table.sql');
      } else if (error.code === '42501' || errorMessage.includes('permission denied') || errorMessage.includes('policy')) {
        setError('Permission denied. The database permissions may not be set up correctly. Please contact an administrator.');
      } else if (error.code === '23505') {
        setError('You have already joined this sanction.');
      } else {
        setError(`Failed to join sanction: ${errorMessage}. If this persists, please contact an administrator.`);
      }
    } finally {
      setJoiningSanction(null);
    }
  }, [user?.id, fighterProfile?.user_id, selectedSanction]);

  // Handle leaving a sanction - memoized with useCallback
  const handleLeaveSanction = useCallback(async (sanctionAcronym: string) => {
    const userId = user?.id || fighterProfile?.user_id;
    if (!userId) {
      return;
    }

    setJoiningSanction(sanctionAcronym);
    try {
      await fighterSanctionService.leaveSanction(sanctionAcronym, userId);
      setJoinedSanctions(prev => {
        const newSet = new Set(prev);
        newSet.delete(sanctionAcronym);
        return newSet;
      });
      // Refresh fighters if dialog is open
      if (selectedSanction === sanctionAcronym) {
        await loadSanctionFighters(sanctionAcronym);
      }
    } catch (error: any) {
      setError(error.message || 'Failed to leave sanction');
    } finally {
      setJoiningSanction(null);
    }
  }, [user?.id, fighterProfile?.user_id, selectedSanction]);

  // Load fighters for a sanction - memoized with useCallback
  const loadSanctionFighters = useCallback(async (sanctionAcronym: string) => {
    setLoadingFighters(true);
    try {
      const fighters = await fighterSanctionService.getFightersBySanction(sanctionAcronym);
      setSanctionFighters(fighters);
    } catch (error: any) {
      console.error('Error loading sanction fighters:', error);
      setError(error.message || 'Failed to load fighters');
    } finally {
      setLoadingFighters(false);
    }
  }, []);

  // Handle opening sanction details dialog - memoized with useCallback
  const handleViewSanction = useCallback(async (sanctionAcronym: string) => {
    setSelectedSanction(sanctionAcronym);
    await loadSanctionFighters(sanctionAcronym);
  }, [loadSanctionFighters]);

  // Handle closing dialog - memoized with useCallback
  const handleCloseDialog = useCallback(() => {
    setSelectedSanction(null);
    setSanctionFighters([]);
  }, []);

  // Memoize fighter cards to prevent unnecessary re-renders
  const fighterCards = useMemo(() => {
    const rankMedals = ['🥇', '🥈', '🥉'];
    return topFighters.map((fighter, index) => {
      const isTopThree = index < 3;
      
      return (
        <Card
          key={fighter.id}
          sx={{
            height: '100%',
            display: 'flex',
            flexDirection: 'column',
            background: isTopThree
              ? 'linear-gradient(135deg, #ffd700 0%, #ffed4e 50%, #ffd700 100%)'
              : 'linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%)',
            border: isTopThree 
              ? '3px solid #ffd700' 
              : '2px solid rgba(0, 0, 0, 0.15)',
            borderRadius: 4,
            boxShadow: isTopThree
              ? `
                0 20px 60px rgba(255, 215, 0, 0.5),
                0 10px 30px rgba(255, 215, 0, 0.3),
                0 5px 15px rgba(255, 215, 0, 0.2),
                inset 0 1px 0 rgba(255, 255, 255, 0.6),
                inset 0 -1px 0 rgba(0, 0, 0, 0.1)
              `
              : `
                0 15px 45px rgba(0, 0, 0, 0.2),
                0 8px 20px rgba(0, 0, 0, 0.15),
                0 3px 10px rgba(0, 0, 0, 0.1),
                inset 0 1px 0 rgba(255, 255, 255, 0.8),
                inset 0 -1px 0 rgba(0, 0, 0, 0.05)
              `,
            transition: 'all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275)',
            transform: 'perspective(1000px) rotateX(0deg) translateZ(0)',
            position: 'relative',
            overflow: 'visible',
            '&::before': {
              content: '""',
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              borderRadius: 4,
              background: isTopThree
                ? 'linear-gradient(135deg, rgba(255, 255, 255, 0.3) 0%, transparent 50%, rgba(0, 0, 0, 0.1) 100%)'
                : 'linear-gradient(135deg, rgba(255, 255, 255, 0.5) 0%, transparent 50%, rgba(0, 0, 0, 0.05) 100%)',
              pointerEvents: 'none',
              zIndex: 1,
            },
            '&:hover': {
              transform: 'perspective(1000px) rotateX(-2deg) translateY(-8px) translateZ(20px)',
              boxShadow: isTopThree
                ? `
                  0 30px 80px rgba(255, 215, 0, 0.6),
                  0 15px 40px rgba(255, 215, 0, 0.4),
                  0 8px 20px rgba(255, 215, 0, 0.3),
                  inset 0 1px 0 rgba(255, 255, 255, 0.7),
                  inset 0 -1px 0 rgba(0, 0, 0, 0.15)
                `
                : `
                  0 25px 60px rgba(0, 0, 0, 0.3),
                  0 12px 30px rgba(0, 0, 0, 0.2),
                  0 5px 15px rgba(0, 0, 0, 0.15),
                  inset 0 1px 0 rgba(255, 255, 255, 0.9),
                  inset 0 -1px 0 rgba(0, 0, 0, 0.1)
                `,
            },
          }}
        >
          {/* Rank Badge with 3D Effect */}
          <Box
            sx={{
              position: 'absolute',
              top: -12,
              left: 16,
              zIndex: 3,
              transform: 'perspective(1000px) rotateX(5deg)',
            }}
          >
            <Chip
              icon={isTopThree ? <span style={{ fontSize: '20px' }}>{rankMedals[index]}</span> : undefined}
              label={`#${index + 1}`}
              sx={{
                height: isTopThree ? 36 : 32,
                fontWeight: 'bold',
                fontSize: isTopThree ? '0.95rem' : '0.875rem',
                background: isTopThree
                  ? 'linear-gradient(135deg, #ff6b6b 0%, #ee5a6f 100%)'
                  : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                color: 'white',
                boxShadow: `
                  0 8px 20px rgba(0, 0, 0, 0.4),
                  0 4px 10px rgba(0, 0, 0, 0.3),
                  inset 0 1px 0 rgba(255, 255, 255, 0.3),
                  inset 0 -1px 0 rgba(0, 0, 0, 0.2)
                `,
                border: '1px solid rgba(255, 255, 255, 0.2)',
                transition: 'all 0.3s ease',
                '&:hover': {
                  transform: 'translateY(-2px) scale(1.05)',
                  boxShadow: `
                    0 12px 30px rgba(0, 0, 0, 0.5),
                    0 6px 15px rgba(0, 0, 0, 0.4),
                    inset 0 1px 0 rgba(255, 255, 255, 0.4),
                    inset 0 -1px 0 rgba(0, 0, 0, 0.3)
                  `,
                },
                '& .MuiChip-label': {
                  px: isTopThree ? 2 : 1.5,
                },
              }}
            />
          </Box>

          <CardContent sx={{ 
            p: 3, 
            pt: isTopThree ? 4.5 : 4, 
            flexGrow: 1, 
            display: 'flex', 
            flexDirection: 'column',
            position: 'relative',
            zIndex: 2,
          }}>
            {/* Creative Fighter Image with 3D Effect */}
            {fighter.creative_fighter_image_url && (
              <Box 
                sx={{ 
                  mb: 2, 
                  display: 'flex', 
                  justifyContent: 'center',
                  alignItems: 'center',
                  borderRadius: 2,
                  overflow: 'visible',
                  bgcolor: 'rgba(0, 0, 0, 0.02)',
                  p: 1,
                  transform: 'perspective(1000px) rotateX(2deg)',
                  transition: 'transform 0.3s ease',
                  '&:hover': {
                    transform: 'perspective(1000px) rotateX(0deg) scale(1.02)',
                  },
                }}
              >
                <Box
                  component="img"
                  src={fighter.creative_fighter_image_url}
                  alt={`${fighter.name}'s Creative Fighter`}
                  sx={{
                    maxWidth: '100%',
                    maxHeight: '200px',
                    width: 'auto',
                    height: 'auto',
                    borderRadius: 2,
                    border: `3px solid ${isTopThree ? '#ffd700' : 'rgba(0, 0, 0, 0.15)'}`,
                    boxShadow: isTopThree 
                      ? `
                        0 12px 30px rgba(255, 215, 0, 0.4),
                        0 6px 15px rgba(255, 215, 0, 0.3),
                        0 3px 8px rgba(255, 215, 0, 0.2),
                        inset 0 1px 0 rgba(255, 255, 255, 0.5),
                        inset 0 -1px 0 rgba(0, 0, 0, 0.1)
                      `
                      : `
                        0 10px 25px rgba(0, 0, 0, 0.25),
                        0 5px 12px rgba(0, 0, 0, 0.15),
                        0 2px 6px rgba(0, 0, 0, 0.1),
                        inset 0 1px 0 rgba(255, 255, 255, 0.6),
                        inset 0 -1px 0 rgba(0, 0, 0, 0.05)
                      `,
                    objectFit: 'contain',
                    transition: 'all 0.3s ease',
                  }}
                />
              </Box>
            )}

            {/* Fighter Name and Handle */}
            <Box sx={{ mb: 2, textAlign: 'center' }}>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 1, mb: 0.5 }}>
                <Typography 
                  variant="h6" 
                  sx={{ 
                    fontWeight: 'bold',
                    color: isTopThree ? '#1a1a1a' : 'text.primary',
                    fontSize: '1.15rem',
                    lineHeight: 1.2,
                  }}
                >
                  {fighter.name}
                </Typography>
                {fighter.belts && fighter.belts.length > 0 && (
                  <Box display="flex" gap={0.5} alignItems="center">
                    {fighter.belts.map((belt) => (
                      <Box
                        key={belt.id}
                        component="img"
                        src={belt.belt_image_url}
                        alt="Championship Belt"
                        sx={{
                          width: 40,
                          height: 40,
                          objectFit: 'contain',
                          borderRadius: '4px',
                        }}
                      />
                    ))}
                  </Box>
                )}
              </Box>
              <Typography 
                variant="body2" 
                sx={{ 
                  color: isTopThree ? 'rgba(0, 0, 0, 0.7)' : 'text.secondary',
                  fontSize: '0.875rem',
                }}
              >
                @{fighter.handle}
              </Typography>
            </Box>

            {/* Stats Row */}
            <Box 
              sx={{ 
                display: 'flex', 
                justifyContent: 'space-between', 
                alignItems: 'center',
                mb: 2,
                p: 1.5,
                borderRadius: 1.5,
                bgcolor: isTopThree ? 'rgba(255, 255, 255, 0.6)' : 'rgba(0, 0, 0, 0.03)',
              }}
            >
              <Box>
                <Typography variant="caption" sx={{ display: 'block', color: isTopThree ? 'rgba(0, 0, 0, 0.7)' : 'text.secondary', fontSize: '0.7rem', mb: 0.25 }}>
                  Points
                </Typography>
                <Typography 
                  variant="h6" 
                  sx={{ 
                    fontWeight: 'bold',
                    color: isTopThree ? '#1a1a1a' : 'primary.main',
                    fontSize: '1.3rem',
                    lineHeight: 1,
                  }}
                >
                  {fighter.points}
                </Typography>
              </Box>
              <Chip 
                label={fighter.tier} 
                size="small" 
                sx={{
                  fontWeight: 'bold',
                  bgcolor: isTopThree ? 'rgba(255, 255, 255, 0.95)' : 'primary.main',
                  color: isTopThree ? 'primary.main' : 'white',
                  fontSize: '0.8rem',
                  height: 28,
                  px: 1,
                }}
              />
            </Box>

            {/* Record */}
            <Typography 
              variant="body2" 
              sx={{ 
                mb: 2.5,
                textAlign: 'center',
                color: isTopThree ? 'rgba(0, 0, 0, 0.8)' : 'text.secondary',
                fontWeight: 500,
                fontSize: '0.9rem',
              }}
            >
              {fighter.weight_class} • {fighter.wins}W-{fighter.losses}L-{fighter.draws}D
            </Typography>
            
            {/* Physical Information - Complete */}
            <Box 
              sx={{ 
                mt: 'auto',
                pt: 2, 
                borderTop: `2px solid ${isTopThree ? 'rgba(0, 0, 0, 0.2)' : 'rgba(0, 0, 0, 0.12)'}`,
              }}
            >
              <Typography 
                variant="subtitle2" 
                sx={{ 
                  fontWeight: 'bold', 
                  display: 'block', 
                  mb: 1.5,
                  color: isTopThree ? 'rgba(0, 0, 0, 0.9)' : 'text.primary',
                  fontSize: '0.85rem',
                  textTransform: 'uppercase',
                  letterSpacing: 0.5,
                }}
              >
                Physical Information
              </Typography>
              <Box 
                sx={{ 
                  display: 'flex',
                  flexDirection: 'column',
                  gap: 0.75,
                }}
              >
                <Typography variant="body2" sx={{ color: isTopThree ? 'rgba(0, 0, 0, 0.8)' : 'text.secondary', fontSize: '0.8rem' }}>
                  <strong>Height:</strong> {fighter.height_feet || 0}'{fighter.height_inches || 0}"
                </Typography>
                <Typography variant="body2" sx={{ color: isTopThree ? 'rgba(0, 0, 0, 0.8)' : 'text.secondary', fontSize: '0.8rem' }}>
                  <strong>Weight:</strong> {fighter.weight || 0} lbs
                </Typography>
                <Typography variant="body2" sx={{ color: isTopThree ? 'rgba(0, 0, 0, 0.8)' : 'text.secondary', fontSize: '0.8rem' }}>
                  <strong>Reach:</strong> {fighter.reach || 0}"
                </Typography>
                <Typography variant="body2" sx={{ color: isTopThree ? 'rgba(0, 0, 0, 0.8)' : 'text.secondary', fontSize: '0.8rem' }}>
                  <strong>Stance:</strong> {fighter.stance ? (fighter.stance.charAt(0).toUpperCase() + fighter.stance.slice(1).toLowerCase()) : 'Not set'}
                </Typography>
                {fighter.hometown && (
                  <Typography variant="body2" sx={{ color: isTopThree ? 'rgba(0, 0, 0, 0.8)' : 'text.secondary', fontSize: '0.8rem' }}>
                    <strong>Hometown:</strong> {fighter.hometown}
                  </Typography>
                )}
                {fighter.trainer && (
                  <Typography variant="body2" sx={{ color: isTopThree ? 'rgba(0, 0, 0, 0.8)' : 'text.secondary', fontSize: '0.8rem' }}>
                    <strong>Trainer:</strong> {fighter.trainer}
                  </Typography>
                )}
                {fighter.gym && (
                  <Typography variant="body2" sx={{ color: isTopThree ? 'rgba(0, 0, 0, 0.8)' : 'text.secondary', fontSize: '0.8rem' }}>
                    <strong>Gym:</strong> {fighter.gym}
                  </Typography>
                )}
                {fighter.platform && (
                  <Typography variant="body2" sx={{ color: isTopThree ? 'rgba(0, 0, 0, 0.8)' : 'text.secondary', fontSize: '0.8rem' }}>
                    <strong>Platform:</strong> {fighter.platform === 'PSN' ? 'PlayStation/PSN' : fighter.platform === 'Xbox' ? 'Xbox' : fighter.platform === 'PC' ? 'Steam/PC' : fighter.platform}
                  </Typography>
                )}
                {fighter.timezone && (
                  <Typography variant="body2" sx={{ color: isTopThree ? 'rgba(0, 0, 0, 0.8)' : 'text.secondary', fontSize: '0.8rem' }}>
                    <strong>Timezone:</strong> {getTimezoneLabel(fighter.timezone)}
                  </Typography>
                )}
                {fighter.birthday && (
                  <Typography variant="body2" sx={{ color: isTopThree ? 'rgba(0, 0, 0, 0.8)' : 'text.secondary', fontSize: '0.8rem' }}>
                    <strong>Birthday:</strong> {formatBirthday(fighter.birthday)}
                  </Typography>
                )}
              </Box>
            </Box>
          </CardContent>
        </Card>
      );
    });
  }, [topFighters]);

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
          backgroundImage: homePageBackground ? `url("${homePageBackground}")` : 'url("/TBC Homepage.png")',
          backgroundSize: '100% 100%',
          backgroundPosition: 'center center',
          backgroundRepeat: 'no-repeat',
          backgroundAttachment: 'fixed',
          height: '100vh',
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
                  alt="Tantalus Boxing Club Logo"
                  sx={{
                    height: { xs: 60, md: 80 },
                    width: 'auto',
                    objectFit: 'contain',
                  }}
                />
                <Box>
                  <Typography variant="h3" gutterBottom sx={{ fontWeight: 'bold', color: 'white', textShadow: '2px 2px 4px rgba(0,0,0,0.8)' }}>
                    Tantalus Boxing Club
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
                    <Typography variant="h6">Club Activity</Typography>
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
                <Tab label="Top Fighters" value={0} />
                <Tab label="Scheduled Fights" value={1} />
                <Tab label="Training Camps" value={2} />
                <Tab label="Scheduled Rematches" value={3} />
                <Tab label="News & Announcements" value={4} />
                <Tab label="Boxing Sanctions" value={5} />
              </Tabs>
            </Box>

            {/* Top Fighters Tab */}
            <TabPanel value={tabValue} index={0}>
              <Box sx={{ mb: 4 }}>
                <Typography 
                  variant="h4" 
                  gutterBottom 
                  sx={{ 
                    fontWeight: 'bold',
                    mb: 1,
                    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                    WebkitBackgroundClip: 'text',
                    WebkitTextFillColor: 'transparent',
                  }}
                >
                  Club Rankings
                </Typography>
                <Typography variant="h6" color="text.secondary" sx={{ mb: 3 }}>
                  Top 30 Fighters
                </Typography>
              </Box>
              {topFighters.length === 0 ? (
                <Alert severity="info" sx={{ borderRadius: 2 }}>
                  No fighters found. Register to join the club!
                </Alert>
              ) : (
                <Box sx={{ 
                  display: 'grid',
                  gridTemplateColumns: {
                    xs: '1fr',
                    sm: 'repeat(2, 1fr)',
                    md: 'repeat(2, 1fr)',
                    lg: 'repeat(3, 1fr)',
                    xl: 'repeat(3, 1fr)'
                  },
                  gap: 3,
                }}>
                  {fighterCards}
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
                Club Active Training Camps
              </Typography>
              {trainingCamps.length === 0 ? (
                <Alert severity="info">
                  No active training camps in the club at the moment. Go to Matchmaking → Training Camp to send invitations!
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
                            <ImageWithFallback 
                              src={item.featured_image} 
                              alt={item.title}
                              maxHeight="300px"
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

                        {/* Emoji Reactions */}
                        <EmojiReactions newsId={item.id} />

                        <Box display="flex" justifyContent="space-between" alignItems="center" sx={{ mt: 2 }}>
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

            {/* Boxing Sanctions Tab */}
            <TabPanel value={tabValue} index={5}>
              <Box sx={{ mb: 4 }}>
                {/* Error Display */}
                {error && (
                  <Alert 
                    severity="error" 
                    sx={{ mb: 3 }}
                    onClose={() => setError(null)}
                  >
                    {error}
                  </Alert>
                )}
                
                {/* Enhanced Header */}
                <Box
                  sx={{
                    background: 'linear-gradient(135deg, rgba(255, 75, 75, 0.2) 0%, rgba(255, 75, 75, 0.1) 100%)',
                    borderRadius: 3,
                    p: { xs: 2.5, sm: 3, md: 4 },
                    mb: 4,
                    border: '2px solid rgba(255, 75, 75, 0.4)',
                    boxShadow: '0 6px 24px rgba(255, 75, 75, 0.2), 0 2px 8px rgba(0, 0, 0, 0.1)',
                    width: '100%',
                    position: 'relative',
                    overflow: 'hidden',
                    '&::before': {
                      content: '""',
                      position: 'absolute',
                      top: 0,
                      left: 0,
                      right: 0,
                      height: '4px',
                      background: 'linear-gradient(90deg, #ff4b4b 0%, #ff6666 50%, #ff4b4b 100%)',
                    },
                  }}
                >
                  <Box 
                    display="flex" 
                    alignItems="center" 
                    gap={{ xs: 2, sm: 3, md: 4 }}
                    flexWrap={{ xs: 'wrap', sm: 'nowrap' }}
                    sx={{ width: '100%', position: 'relative', zIndex: 1 }}
                  >
                    <Box
                      sx={{
                        width: { xs: 60, sm: 72, md: 80 },
                        height: { xs: 60, sm: 72, md: 80 },
                        minWidth: { xs: 60, sm: 72, md: 80 },
                        borderRadius: '50%',
                        background: 'linear-gradient(135deg, #ff4b4b 0%, #ff6666 100%)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontWeight: 900,
                        letterSpacing: '0.2em',
                        textTransform: 'uppercase',
                        fontSize: { xs: '0.9rem', sm: '1.1rem', md: '1.3rem' },
                        color: '#fff',
                        boxShadow: '0 6px 20px rgba(255, 75, 75, 0.6), inset 0 2px 4px rgba(255, 255, 255, 0.3)',
                        flexShrink: 0,
                        border: '3px solid rgba(255, 255, 255, 0.4)',
                      }}
                    >
                      TBC
                    </Box>
                    <Box flex={1} minWidth={0} sx={{ width: '100%' }}>
                      <Typography 
                        variant="h4" 
                        component="h2"
                        sx={{ 
                          fontWeight: 900, 
                          mb: 0.5,
                          fontSize: { xs: '1.5rem', sm: '2rem', md: '2.5rem' },
                          color: '#ff4b4b',
                          lineHeight: 1.1,
                          wordBreak: 'break-word',
                          textShadow: '0 2px 8px rgba(255, 75, 75, 0.3), 0 1px 3px rgba(0, 0, 0, 0.2)',
                          letterSpacing: '-0.02em',
                        }}
                      >
                        Tantalus Boxing Club
                      </Typography>
                      <Typography 
                        variant="h6" 
                        component="h3"
                        sx={{ 
                          color: 'rgba(0, 0, 0, 0.75)',
                          fontWeight: 700,
                          letterSpacing: '0.08em',
                          fontSize: { xs: '1rem', sm: '1.15rem', md: '1.35rem' },
                          wordBreak: 'break-word',
                          lineHeight: 1.4,
                          mt: 0.75,
                          textTransform: 'uppercase',
                        }}
                      >
                        Boxing Sanctions Management Panel
                      </Typography>
                    </Box>
                  </Box>
                </Box>

                {/* Enhanced Filters */}
                <Box 
                  sx={{ 
                    display: 'flex', 
                    justifyContent: 'space-between', 
                    gap: 2, 
                    mb: 4,
                    flexWrap: 'wrap',
                    p: 2,
                    background: 'rgba(255, 255, 255, 0.02)',
                    borderRadius: 2,
                    border: '1px solid rgba(255, 255, 255, 0.05)',
                  }}
                >
                  <TextField
                    id="sanction-search-input"
                    name="sanction-search"
                    label="Search Sanctions"
                    placeholder="Search by name or acronym…"
                    value={sanctionSearch}
                    onChange={(e) => setSanctionSearch(e.target.value)}
                    size="small"
                    sx={{ 
                      flex: 1,
                      minWidth: 200,
                      '& .MuiOutlinedInput-root': {
                        borderRadius: '12px',
                        backgroundColor: 'rgba(255, 255, 255, 0.05)',
                        '&:hover': {
                          backgroundColor: 'rgba(255, 255, 255, 0.08)',
                        },
                        '&.Mui-focused': {
                          backgroundColor: 'rgba(255, 255, 255, 0.1)',
                          borderColor: '#ff4b4b',
                        },
                      },
                      '& .MuiOutlinedInput-input': {
                        color: '#f5f5f5',
                      },
                      '& .MuiInputLabel-root': {
                        color: 'text.secondary',
                      },
                    }}
                  />
                  <FormControl 
                    size="small" 
                    sx={{ 
                      minWidth: 180,
                      '& .MuiOutlinedInput-root': {
                        borderRadius: '12px',
                        backgroundColor: 'rgba(255, 255, 255, 0.05)',
                        '&:hover': {
                          backgroundColor: 'rgba(255, 255, 255, 0.08)',
                        },
                        '&.Mui-focused': {
                          backgroundColor: 'rgba(255, 255, 255, 0.1)',
                        },
                      },
                    }}
                  >
                    <InputLabel id="sanction-type-label" sx={{ color: 'text.secondary' }}>Type</InputLabel>
                    <Select
                      id="sanction-type-select"
                      name="sanction-type"
                      labelId="sanction-type-label"
                      value={sanctionTypeFilter}
                      label="Type"
                      onChange={(e) => setSanctionTypeFilter(e.target.value)}
                      sx={{
                        borderRadius: '12px',
                        color: '#f5f5f5',
                      }}
                    >
                      <MenuItem value="">All Types</MenuItem>
                      <MenuItem value="Association">Association</MenuItem>
                      <MenuItem value="Organization">Organization</MenuItem>
                      <MenuItem value="Federation">Federation</MenuItem>
                      <MenuItem value="Council">Council</MenuItem>
                      <MenuItem value="Magazine">Magazine</MenuItem>
                    </Select>
                  </FormControl>
                </Box>

                {/* Sanctions Grid */}
                {!user?.id || authLoading ? (
                  <Alert severity="info" sx={{ mb: 2 }}>
                    Please log in to view boxing sanctions.
                  </Alert>
                ) : !fighterProfile ? (
                  <Alert severity="info" sx={{ mb: 2 }}>
                    Please complete your fighter profile to view and join boxing sanctions.
                  </Alert>
                ) : (
                <Box
                  sx={{
                    display: 'grid',
                    gridTemplateColumns: {
                      xs: '1fr',
                      sm: 'repeat(2, 1fr)',
                      md: 'repeat(2, 1fr)',
                      lg: 'repeat(3, 1fr)',
                    },
                    gap: 2.5,
                  }}
                >
                  {filteredSanctions.map((sanction) => {
                      // Get status for this sanction - use memoized calculation
                      const statusInfo = sanctionStatuses.get(sanction.acronym) || 
                        fighterSanctionService.getSanctionStatus(sanction.acronym, fighterPoints);
                      
                      // Pre-calculate derived values once (optimized)
                      const { status } = statusInfo;
                      const statusColor = status === 'active' ? '#22c55e' : status === 'pending' ? '#f59e0b' : '#6b7280';
                      const statusLabel = status === 'active' ? 'Active' : status === 'pending' ? 'Pending' : 'Locked';
                      const isLocked = status === 'locked';
                      const isPending = status === 'pending';
                      const isJoined = joinedSanctions.has(sanction.acronym);
                      const isJoining = joiningSanction === sanction.acronym;
                      
                      return (
                      <Card
                        key={sanction.acronym}
                        sx={{
                          background: 'linear-gradient(135deg, rgba(19, 19, 31, 0.95) 0%, rgba(5, 5, 9, 0.95) 100%)',
                          borderRadius: 3,
                          border: `1px solid ${isLocked ? 'rgba(107, 114, 128, 0.3)' : 'rgba(255, 255, 255, 0.1)'}`,
                          p: 3,
                          display: 'flex',
                          flexDirection: 'column',
                          gap: 2,
                          boxShadow: '0 8px 32px rgba(0, 0, 0, 0.4)',
                          transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                          position: 'relative',
                          overflow: 'hidden',
                          opacity: isLocked ? 0.6 : 1,
                          '&::before': {
                            content: '""',
                            position: 'absolute',
                            top: 0,
                            left: 0,
                            right: 0,
                            height: '4px',
                            background: `linear-gradient(90deg, ${statusColor} 0%, transparent 100%)`,
                            opacity: isLocked ? 0 : 1,
                            transition: 'opacity 0.3s ease',
                          },
                          '&:hover': {
                            borderColor: statusColor,
                            transform: isLocked ? 'none' : 'translateY(-8px)',
                            boxShadow: isLocked ? '0 8px 32px rgba(0, 0, 0, 0.4)' : `0 12px 40px rgba(0, 0, 0, 0.6), 0 0 20px ${statusColor}40`,
                            '&::before': {
                              opacity: isLocked ? 0 : 1,
                            },
                          },
                        }}
                      >
                        {/* Header with Acronym and Status */}
                        <Box display="flex" justifyContent="space-between" alignItems="flex-start" mb={1}>
                          <Box>
                            <Typography
                              variant="h4"
                              sx={{
                                fontWeight: 900,
                                letterSpacing: '0.15em',
                                textTransform: 'uppercase',
                                background: `linear-gradient(135deg, ${statusColor} 0%, #fff 100%)`,
                                WebkitBackgroundClip: 'text',
                                WebkitTextFillColor: 'transparent',
                                backgroundClip: 'text',
                                fontSize: '2rem',
                                lineHeight: 1,
                                mb: 0.5,
                              }}
                            >
                              {sanction.acronym}
                            </Typography>
                            <Chip
                              label={statusLabel}
                              size="small"
                              sx={{
                                fontSize: '0.65rem',
                                textTransform: 'uppercase',
                                letterSpacing: '0.15em',
                                height: 22,
                                backgroundColor: `${statusColor}20`,
                                color: statusColor,
                                border: `1px solid ${statusColor}40`,
                                fontWeight: 700,
                                px: 1,
                              }}
                            />
                          </Box>
                        </Box>

                        {/* Image */}
                        {sanction.image && (
                          <Box
                            sx={{
                              width: '100%',
                              maxHeight: '140px',
                              display: 'flex',
                              justifyContent: 'center',
                              alignItems: 'center',
                              my: 1,
                              backgroundColor: 'transparent',
                              borderRadius: 2,
                              overflow: 'hidden',
                            }}
                          >
                            <Box
                              component="img"
                              src={sanction.image}
                              alt={sanction.name}
                              sx={{
                                width: '100%',
                                height: 'auto',
                                maxHeight: '140px',
                                objectFit: 'contain',
                                backgroundColor: 'transparent',
                                filter: 'drop-shadow(0 4px 8px rgba(0, 0, 0, 0.3))',
                                transition: 'transform 0.3s ease',
                                '&:hover': {
                                  transform: 'scale(1.05)',
                                },
                              }}
                            />
                          </Box>
                        )}

                        {/* Sanction Name */}
                        <Typography
                          variant="h6"
                          sx={{
                            fontWeight: 700,
                            color: '#fff',
                            fontSize: '1.1rem',
                            lineHeight: 1.3,
                            mb: 0.5,
                          }}
                        >
                          {sanction.name}
                        </Typography>

                        {/* Type Badge */}
                        <Box display="flex" alignItems="center" gap={1} mb={1}>
                          <Typography
                            variant="caption"
                            sx={{
                              color: 'rgba(255, 255, 255, 0.6)',
                              fontSize: '0.75rem',
                              textTransform: 'uppercase',
                              letterSpacing: '0.1em',
                              fontWeight: 600,
                            }}
                          >
                            Type:
                          </Typography>
                          <Chip
                            label={sanction.type}
                            size="small"
                            sx={{
                              fontSize: '0.7rem',
                              height: 20,
                              backgroundColor: 'rgba(255, 255, 255, 0.1)',
                              color: '#fff',
                              fontWeight: 600,
                            }}
                          />
                        </Box>

                        {/* Description */}
                        <Typography
                          variant="body2"
                          sx={{
                            color: 'rgba(255, 255, 255, 0.7)',
                            fontSize: '0.875rem',
                            lineHeight: 1.6,
                            mb: 1,
                            flex: 1,
                          }}
                        >
                          {sanction.description}
                        </Typography>
                        
                        {/* Points Requirement */}
                        {isLocked && (
                          <Typography
                            variant="caption"
                            sx={{
                              color: '#f59e0b',
                              fontSize: '0.75rem',
                              fontWeight: 600,
                              mb: 1,
                            }}
                          >
                            Requires {statusInfo.requiredPoints} points (You have {statusInfo.currentPoints})
                          </Typography>
                        )}
                        {isPending && (
                          <Typography
                            variant="caption"
                            sx={{
                              color: '#f59e0b',
                              fontSize: '0.75rem',
                              fontWeight: 600,
                              mb: 1,
                            }}
                          >
                            Unlocks at {statusInfo.requiredPoints} points (You have {statusInfo.currentPoints})
                          </Typography>
                        )}
                        
                        {/* Action Buttons */}
                        <Box display="flex" gap={1.5} mt="auto" pt={2} borderTop="1px solid rgba(255, 255, 255, 0.1)">
                          {joinedSanctions.has(sanction.acronym) ? (
                            <>
                              <Button
                                variant="outlined"
                                onClick={() => handleViewSanction(sanction.acronym)}
                                fullWidth
                                aria-label={`View fighters in ${sanction.name}`}
                                sx={{
                                  borderRadius: '12px',
                                  borderColor: statusColor,
                                  color: statusColor,
                                  fontSize: '0.875rem',
                                  fontWeight: 700,
                                  letterSpacing: '0.05em',
                                  textTransform: 'uppercase',
                                  px: 2,
                                  py: 1.25,
                                  borderWidth: 2,
                                  transition: 'all 0.2s ease',
                                  '&:hover': {
                                    borderColor: statusColor,
                                    backgroundColor: `${statusColor}15`,
                                    borderWidth: 2,
                                    transform: 'translateY(-2px)',
                                    boxShadow: `0 4px 12px ${statusColor}30`,
                                  },
                                }}
                              >
                                View Fighters
                              </Button>
                              <Button
                                variant="contained"
                                onClick={() => handleLeaveSanction(sanction.acronym)}
                                disabled={isJoining}
                                aria-label={`Leave ${sanction.name}`}
                                sx={{
                                  borderRadius: '12px',
                                  background: 'linear-gradient(135deg, #6b7280 0%, #9ca3af 100%)',
                                  color: '#fff',
                                  fontSize: '0.875rem',
                                  fontWeight: 700,
                                  letterSpacing: '0.05em',
                                  textTransform: 'uppercase',
                                  px: 2,
                                  py: 1.25,
                                  minWidth: 100,
                                  boxShadow: '0 4px 12px rgba(107, 114, 128, 0.3)',
                                  transition: 'all 0.2s ease',
                                  '&:hover': {
                                    background: 'linear-gradient(135deg, #9ca3af 0%, #d1d5db 100%)',
                                    transform: 'translateY(-2px)',
                                    boxShadow: '0 6px 16px rgba(107, 114, 128, 0.4)',
                                  },
                                  '&:disabled': {
                                    background: 'rgba(107, 114, 128, 0.5)',
                                  },
                                }}
                              >
                                {isJoining ? 'Leaving...' : 'Leave'}
                              </Button>
                            </>
                          ) : (
                            <Tooltip 
                              title={
                                !(user?.id || fighterProfile?.user_id) 
                                  ? 'Please log in to join a sanction' 
                                  : isLocked
                                    ? `This sanction requires ${statusInfo.requiredPoints} points. You currently have ${statusInfo.currentPoints} points.`
                                  : isPending
                                    ? `This sanction will unlock at ${statusInfo.requiredPoints} points. You currently have ${statusInfo.currentPoints} points.`
                                  : joiningSanction === sanction.acronym 
                                    ? 'Joining...' 
                                    : ''
                              }
                              arrow
                            >
                              <span style={{ width: '100%' }}>
                                <Button
                                  variant="contained"
                                  onClick={() => handleJoinSanction(sanction.acronym)}
                                  disabled={authLoading || isJoining || !(user?.id || fighterProfile?.user_id) || isLocked}
                                  aria-label={`Join ${sanction.name}`}
                                  fullWidth
                                  sx={{
                                borderRadius: '12px',
                                background: isLocked 
                                  ? 'linear-gradient(135deg, #6b7280 0%, #4b5563 100%)'
                                  : `linear-gradient(135deg, ${statusColor} 0%, ${statusColor}dd 100%)`,
                                color: '#fff',
                                fontSize: '0.875rem',
                                fontWeight: 700,
                                letterSpacing: '0.05em',
                                textTransform: 'uppercase',
                                px: 2,
                                py: 1.5,
                                boxShadow: isLocked ? 'none' : `0 4px 16px ${statusColor}40`,
                                transition: 'all 0.2s ease',
                                '&:hover': {
                                  background: isLocked 
                                    ? 'linear-gradient(135deg, #6b7280 0%, #4b5563 100%)'
                                    : `linear-gradient(135deg, ${statusColor}dd 0%, ${statusColor} 100%)`,
                                  transform: isLocked ? 'none' : 'translateY(-2px)',
                                  boxShadow: isLocked ? 'none' : `0 6px 20px ${statusColor}60`,
                                },
                                '&:disabled': {
                                  background: 'rgba(107, 114, 128, 0.3)',
                                  boxShadow: 'none',
                                  cursor: 'not-allowed',
                                },
                              }}
                            >
                                  {isJoining 
                                    ? 'Joining...' 
                                    : isLocked 
                                      ? 'Locked' 
                                      : isPending
                                        ? 'Pending'
                                        : 'Join'}
                                </Button>
                              </span>
                            </Tooltip>
                          )}
                        </Box>
                      </Card>
                      );
                    })}
                </Box>
                )}
              </Box>
            </TabPanel>
          </Card>

          {/* Sanction Fighters Dialog */}
          <Dialog
            open={selectedSanction !== null}
            onClose={handleCloseDialog}
            maxWidth="md"
            fullWidth
          >
            <DialogTitle>
              <Box display="flex" alignItems="center" gap={2}>
                <Typography variant="h5" sx={{ fontWeight: 'bold' }}>
                  {selectedSanction && [
                    { acronym: 'TBCA', name: 'Tantalus Boxing Club Amateur Association' },
                    { acronym: 'TBA', name: 'Tantalus Boxing Association' },
                    { acronym: 'TBO', name: 'Tantalus Boxing Organization' },
                    { acronym: 'TBF', name: 'Tantalus Boxing Federation' },
                    { acronym: 'TBC', name: 'Tantalus Boxing Council' },
                    { acronym: 'TRM', name: 'Tantalus Ring Magazine' },
                  ].find(s => s.acronym === selectedSanction)?.name}
                </Typography>
                <Chip
                  label={`${sanctionFighters.length} Fighter${sanctionFighters.length !== 1 ? 's' : ''}`}
                  size="small"
                  color="primary"
                />
              </Box>
            </DialogTitle>
            <DialogContent>
              {loadingFighters ? (
                <Box display="flex" justifyContent="center" p={4}>
                  <CircularProgress />
                </Box>
              ) : sanctionFighters.length === 0 ? (
                <Alert severity="info">
                  No fighters have joined this sanction yet.
                </Alert>
              ) : (
                <TableContainer component={Paper} variant="outlined">
                  <Table>
                    <TableHead>
                      <TableRow>
                        <TableCell sx={{ fontWeight: 'bold' }}>Rank</TableCell>
                        <TableCell sx={{ fontWeight: 'bold' }}>Fighter</TableCell>
                        <TableCell sx={{ fontWeight: 'bold' }}>Tier</TableCell>
                        <TableCell sx={{ fontWeight: 'bold' }} align="right">Points</TableCell>
                        <TableCell sx={{ fontWeight: 'bold' }} align="right">Record</TableCell>
                        <TableCell sx={{ fontWeight: 'bold' }} align="right">Demotions</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {sanctionFighters.map((fighter) => (
                        <TableRow
                          key={fighter.id}
                          sx={{
                            '&:hover': { backgroundColor: 'action.hover' },
                            cursor: 'pointer',
                          }}
                          onClick={() => navigate(`/fighter/${fighter.user_id}`)}
                        >
                          <TableCell>
                            <Typography variant="h6" sx={{ fontWeight: 'bold', color: fighter.rank === 1 ? '#ffd700' : 'inherit' }}>
                              #{fighter.rank}
                            </Typography>
                          </TableCell>
                          <TableCell>
                            <Box>
                              <Typography variant="body1" sx={{ fontWeight: 600 }}>
                                {fighter.name}
                              </Typography>
                              <Typography variant="caption" color="text.secondary">
                                @{fighter.handle}
                              </Typography>
                            </Box>
                          </TableCell>
                          <TableCell>
                            <Chip
                              label={fighter.tier}
                              size="small"
                              color={
                                fighter.tier === 'Elite' ? 'error' :
                                fighter.tier === 'Contender' ? 'warning' :
                                fighter.tier === 'Pro' ? 'info' :
                                fighter.tier === 'Semi-Pro' ? 'success' : 'default'
                              }
                            />
                          </TableCell>
                          <TableCell align="right">
                            <Typography variant="body1" sx={{ fontWeight: 600 }}>
                              {fighter.points}
                            </Typography>
                          </TableCell>
                          <TableCell align="right">
                            <Typography variant="body2">
                              {fighter.wins}-{fighter.losses}-{fighter.draws}
                            </Typography>
                          </TableCell>
                          <TableCell align="right">
                            <Typography variant="body2" color={(fighter.demotions || 0) > 0 ? 'error' : 'text.secondary'}>
                              {fighter.demotions || 0}
                            </Typography>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>
              )}
            </DialogContent>
            <DialogActions>
              <Button onClick={handleCloseDialog}>Close</Button>
            </DialogActions>
          </Dialog>
        </Box>
      </Container>
    </>
  );
};

export default HomePage;