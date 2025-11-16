import React, { useState, useEffect, useCallback } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Chip,
  Button,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  IconButton,
  Alert,
  Divider,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Avatar,
  MenuItem,
  CircularProgress,
  FormControl,
  InputLabel,
  Select,
} from '@mui/material';
import {
  Edit,
  Save,
  Cancel,
  Add,
  SportsMma,
  EmojiEvents,
  TrendingUp,
  CalendarToday,
  Person,
  Height,
  Scale,
  LocationOn,
  Business,
  Link as LinkIcon,
  Delete,
  FitnessCenter,
  Notifications,
  CheckCircle,
  Cancel as CancelIcon,
  Schedule,
} from '@mui/icons-material';
import FormControlLabel from '@mui/material/FormControlLabel';
import Checkbox from '@mui/material/Checkbox';
import { useAuth } from '../../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { supabase, TABLES } from '../../services/supabase';
import { HomePageService, ScheduledFight } from '../../services/homePageService';
import { useRealtime } from '../../contexts/RealtimeContext';
import { TournamentService, Tournament } from '../../services/tournamentService';
import { disputeService } from '../../services/disputeService';
import DisputeResolution from '../DisputeResolution/DisputeResolution';
import { NewsService } from '../../services/newsService';
import { fightUrlSubmissionService } from '../../services/fightUrlSubmissionService';
import { FightUrlSubmission, CreateFightUrlSubmissionRequest } from '../../types';
import { smartMatchmakingService } from '../../services/smartMatchmakingService';
import { trainingCampService, TrainingCampInvitation } from '../../services/trainingCampService';
import { calloutService, CalloutRequest } from '../../services/calloutService';
import { 
  getAllowedWeightClasses, 
  isWeightClassAllowed, 
  getWeightClassDifference,
  WEIGHT_CLASS_ORDER 
} from '../../utils/weightClassUtils';
import { COMMON_TIMEZONES, getTimezoneLabel } from '../../utils/timezones';
import wbcBlack from '../../wbc-black.jpg';
// Import Logo1.png
import logo1 from '../../Logo1.png';

interface FightRecord {
  id: string;
  fighter_id: string;
  opponent_name: string;
  result: 'win' | 'loss' | 'draw';
  method: string;
  round?: number;
  date: string;
  weight_class: string;
}

// Normalize method input to match database constraint values
// Valid database values: 'UD', 'SD', 'MD', 'KO', 'TKO', 'Submission', 'DQ', 'No Contest', 'No Decision'
const normalizeMethod = (method: string): string => {
  if (!method || !method.trim()) {
    return 'UD'; // Default to UD if empty
  }
  
  const methodUpper = method.toUpperCase().trim();
  const methodLower = method.toLowerCase().trim();
  
  // Map common variations to standard values
  const methodMap: Record<string, string> = {
    // Knockout variations
    'KO': 'KO',
    'OK': 'KO', // Common typo: OK instead of KO
    'K.O.': 'KO',
    'K.O': 'KO',
    'KNOCKOUT': 'KO',
    'KNOCK OUT': 'KO',
    'KNOCK-OUT': 'KO',
    
    // TKO variations
    'TKO': 'TKO',
    'TK': 'TKO',
    'T.K.O.': 'TKO',
    'T.K.O': 'TKO',
    'TECHNICAL KO': 'TKO',
    'TECHNICAL KNOCKOUT': 'TKO',
    'TECHNICAL KNOCK OUT': 'TKO',
    'TECHNICAL KNOCK-OUT': 'TKO',
    
    // Decision variations
    'UD': 'UD',
    'UNANIMOUS': 'UD',
    'UNANIMOUS DECISION': 'UD',
    'DECISION': 'UD', // Default decision to UD
    'DECSISON': 'UD', // Typo: Decsison -> Decision -> UD
    'DECISON': 'UD', // Typo: Decison -> Decision -> UD
    'DESCISION': 'UD', // Typo: Descision -> Decision -> UD
    'DESICION': 'UD', // Typo: Desicion -> Decision -> UD (missing 'c')
    'DECISIO': 'UD', // Typo: Decisio -> Decision -> UD
    
    'SD': 'SD',
    'SPLIT': 'SD',
    'SPLIT DECISION': 'SD',
    'SPLIT DECSISON': 'SD', // Typo handling
    
    'MD': 'MD',
    'MAJORITY': 'MD',
    'MAJORITY DECISION': 'MD',
    'MAJORITY DECSISON': 'MD', // Typo handling
    
    // Other variations
    'SUBMISSION': 'Submission',
    'SUB': 'Submission',
    
    'DQ': 'DQ',
    'DISQUALIFICATION': 'DQ',
    
    'NC': 'No Contest',
    'NO CONTEST': 'No Contest',
    'NO DECISION': 'No Decision',
    'ND': 'No Decision',
  };
  
  // Check exact match first
  if (methodMap[methodUpper]) {
    return methodMap[methodUpper];
  }
  
  // Fuzzy matching for typos - check if method contains key phrases (case-insensitive)
  const methodNormalized = methodUpper.replace(/[^A-Z]/g, ''); // Remove non-letters for fuzzy matching
  
  // Check for decision-related typos (Decsison, Decison, Desicion, etc.)
  if (methodNormalized.includes('DECS') || methodNormalized.includes('DECIS') || methodNormalized.includes('DESCIS') || methodNormalized.includes('DESIC')) {
    // Check for specific decision types
    if (methodUpper.includes('SPLIT') || methodUpper.includes('SPLT')) {
      return 'SD';
    }
    if (methodUpper.includes('MAJORITY') || methodUpper.includes('MAJOR')) {
      return 'MD';
    }
    // Default to UD for any decision-related typo
    return 'UD';
  }
  
  // Check if method contains key phrases
  if (methodUpper.includes('UNANIMOUS') || methodUpper.includes('UNANIM')) return 'UD';
  if (methodUpper.includes('SPLIT') && (methodUpper.includes('DECISION') || methodUpper.includes('DECS') || methodUpper.includes('DECIS'))) return 'SD';
  if (methodUpper.includes('MAJORITY') && methodUpper.includes('DECISION')) return 'MD';
  if (methodUpper.includes('TECHNICAL') && methodUpper.includes('KNOCKOUT')) return 'TKO';
  if (methodUpper.includes('TECHNICAL') && methodUpper.includes('KO')) return 'TKO';
  if (methodUpper.includes('KNOCKOUT') && !methodUpper.includes('TECHNICAL')) return 'KO';
  if (methodUpper.includes('KNOCK-OUT') && !methodUpper.includes('TECHNICAL')) return 'KO';
  if (methodUpper.includes('DISQUALIFICATION')) return 'DQ';
  if (methodUpper.includes('NO CONTEST')) return 'No Contest';
  if (methodUpper.includes('NO DECISION')) return 'No Decision';
  if (methodUpper.includes('SUBMISSION')) return 'Submission';
  
  // Check for decision-related words (handles typos like "Decsison", "Decison", "Desicion", etc.)
  // This is a fallback in case the exact match or earlier fuzzy match didn't catch it
  if (methodUpper.includes('DECISION') || methodNormalized.includes('DECS') || methodNormalized.includes('DECIS') || methodNormalized.includes('DESCIS') || methodNormalized.includes('DESIC')) {
    if (methodUpper.includes('SPLIT') || methodUpper.includes('SPLT')) {
      return 'SD';
    }
    if (methodUpper.includes('MAJORITY') || methodUpper.includes('MAJOR')) {
      return 'MD';
    }
    // Default to UD for any decision-related word (including typos)
    return 'UD';
  }
  
  // Handle common typos: "OK" (typo for KO), but only if it's likely a typo (not part of another word)
  // Check if the entire method is just "OK" or similar
  if (methodUpper === 'OK' || methodUpper === 'O.K.' || methodUpper === 'O.K') {
    return 'KO'; // Assume "OK" is a typo for "KO"
  }
  
  // If no match found, validate against known constraints and provide helpful error
  const validMethods = ['UD', 'SD', 'MD', 'KO', 'TKO', 'Submission', 'DQ', 'No Contest', 'No Decision'];
  const methodTrimmed = method.trim();
  
  // Check if it's close to a valid method (case-insensitive)
  const closeMatch = validMethods.find(vm => vm.toUpperCase() === methodTrimmed.toUpperCase());
  if (closeMatch) {
    return closeMatch;
  }
  
  // If no match found, return as-is (will be caught by database constraint with a helpful error)
  // Log a warning to help debug
  console.warn(`Method "${method}" could not be normalized. Valid methods are: ${validMethods.join(', ')}`);
  return method.trim();
};

// Helper function to normalize weight class to match WEIGHT_CLASS_ORDER format
const normalizeWeightClass = (weightClass: string | undefined | null): string => {
  if (!weightClass) return '';
  // Find the matching weight class from WEIGHT_CLASS_ORDER (case-insensitive)
  const normalized = WEIGHT_CLASS_ORDER.find(
    wc => wc.toLowerCase() === weightClass.toLowerCase()
  );
  return normalized || weightClass; // Return normalized if found, otherwise return as-is
};

const FighterProfile: React.FC = () => {
  const { fighterProfile, updateFighterProfile, refreshFighterProfile, user } = useAuth();
  const navigate = useNavigate();
  const [isEditing, setIsEditing] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fightRecords, setFightRecords] = useState<FightRecord[]>([]);
  const [scheduledFights, setScheduledFights] = useState<ScheduledFight[]>([]);
  const [myTournaments, setMyTournaments] = useState<any[]>([]);
  const [rank, setRank] = useState<number | null>(null);
  const [addFightDialogOpen, setAddFightDialogOpen] = useState(false);
  const [fightRecordError, setFightRecordError] = useState<string | null>(null);
  const [disputeDialogOpen, setDisputeDialogOpen] = useState(false);
  const [selectedFightForDispute, setSelectedFightForDispute] = useState<ScheduledFight | null>(null);
  const [newDispute, setNewDispute] = useState({
    reason: '',
    fight_link: '',
    dispute_category: 'other' as 'cheating' | 'spamming' | 'exploits' | 'excessive_punches' | 'stamina_draining' | 'power_punches' | 'other',
    evidence_urls: [] as string[],
  });
  const [evidenceUrl, setEvidenceUrl] = useState('');
  const [submittingDispute, setSubmittingDispute] = useState(false);
  const [fightUrlSubmissions, setFightUrlSubmissions] = useState<FightUrlSubmission[]>([]);
  const [submissionDialogOpen, setSubmissionDialogOpen] = useState(false);
  const [submittingUrl, setSubmittingUrl] = useState(false);
  const [newSubmission, setNewSubmission] = useState<CreateFightUrlSubmissionRequest>({
    fight_url: '',
    event_type: 'Live Event',
    description: '',
  });
  const [selectedFightForSubmission, setSelectedFightForSubmission] = useState<ScheduledFight | null>(null);
  const [deleteSubmissionDialogOpen, setDeleteSubmissionDialogOpen] = useState(false);
  const [submissionToDelete, setSubmissionToDelete] = useState<string | null>(null);
  const [mandatoryFights, setMandatoryFights] = useState<any[]>([]);
  const [pendingFightRequests, setPendingFightRequests] = useState<any[]>([]);
  const [acceptingFight, setAcceptingFight] = useState<string | null>(null);
  const [denyingFight, setDenyingFight] = useState<string | null>(null);
  const [trainingCampInvitations, setTrainingCampInvitations] = useState<TrainingCampInvitation[]>([]);
  const [activeTrainingCamps, setActiveTrainingCamps] = useState<Array<{
    fighter: any;
    sparringPartners: Array<{
      partner: any;
      camp: TrainingCampInvitation;
    }>;
    startedAt: string;
    expiresAt: string;
  }>>([]);
  const [calloutRequests, setCalloutRequests] = useState<CalloutRequest[]>([]);
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
  const [acceptingInvitation, setAcceptingInvitation] = useState<string | null>(null);
  const [decliningInvitation, setDecliningInvitation] = useState<string | null>(null);
  const [acceptingCallout, setAcceptingCallout] = useState<string | null>(null);
  const [decliningCallout, setDecliningCallout] = useState<string | null>(null);
  const [newFightRecord, setNewFightRecord] = useState({
    opponent_name: '',
    result: 'win' as 'win' | 'loss' | 'draw',
    method: '',
    round: '',
    date: '',
    weight_class: normalizeWeightClass(fighterProfile?.weight_class) || '',
    is_tournament_win: false,
  });
  const [editForm, setEditForm] = useState({
    fighterName: fighterProfile?.name || '',
    height_feet: (fighterProfile as any)?.height_feet || 0,
    height_inches: (fighterProfile as any)?.height_inches || 0,
    weight: fighterProfile?.weight || 0,
    reach: fighterProfile?.reach || 0,
    stance: (fighterProfile as any)?.stance || 'orthodox',
    platform: (fighterProfile as any)?.platform || 'PC',
    timezone: (fighterProfile as any)?.timezone || Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC',
    hometown: fighterProfile?.hometown || '',
    trainer: fighterProfile?.trainer || '',
    gym: fighterProfile?.gym || '',
    birthday: (fighterProfile as any)?.birthday || '',
    weight_class: normalizeWeightClass(fighterProfile?.weight_class) || '',
  });

  const { subscribeToFightRecords, subscribeToScheduledFights, subscribeToFighterProfiles } = useRealtime();

  const loadFightRecords = useCallback(async () => {
    if (!fighterProfile?.user_id) return;
    try {
      const { data, error } = await supabase
        .from('fight_records')
        .select('*')
        .eq('fighter_id', fighterProfile.user_id)
        .order('date', { ascending: false });

      if (error) throw error;
      setFightRecords(data || []);
    } catch (error) {
      console.error('Error loading fight records:', error);
    }
  }, [fighterProfile?.user_id]);

  const loadScheduledFights = useCallback(async () => {
    if (!fighterProfile?.user_id) return;
    try {
      const allFights = await HomePageService.getScheduledFights(50, true); // Include pending fights
      const myFights = allFights.filter(
        (fight) =>
          fight.fighter1_id === fighterProfile.user_id ||
          fight.fighter2_id === fighterProfile.user_id
      );
      // Separate pending fights (mandatory fight requests) from scheduled fights
      const pending = myFights.filter(f => f.status === 'Pending');
      const scheduled = myFights.filter(f => f.status === 'Scheduled');
      // Separate mandatory fights from regular scheduled fights
      const mandatory = scheduled.filter(f => f.match_type === 'auto_mandatory');
      const regular = scheduled.filter(f => f.match_type !== 'auto_mandatory' || !f.match_type);
      setPendingFightRequests(pending);
      setScheduledFights(regular);
      setMandatoryFights(mandatory);
    } catch (error) {
      console.error('Error loading scheduled fights:', error);
    }
  }, [fighterProfile?.user_id]);

  const loadMandatoryFights = useCallback(async () => {
    if (!fighterProfile?.user_id) return;
    try {
      const fights = await smartMatchmakingService.getMandatoryFights(fighterProfile.user_id);
      setMandatoryFights(fights);
    } catch (error) {
      console.error('Error loading mandatory fights:', error);
    }
  }, [fighterProfile?.user_id]);

  const loadTrainingCampInvitations = useCallback(async () => {
    if (!fighterProfile?.user_id) return;
    try {
      const invitations = await trainingCampService.getPendingInvitations(fighterProfile.user_id);
      setTrainingCampInvitations(invitations);
    } catch (error) {
      console.error('Error loading training camp invitations:', error);
    }
  }, [fighterProfile?.user_id]);

  const loadActiveTrainingCamps = useCallback(async () => {
    if (!fighterProfile?.user_id) return;
    try {
      const allCamps = await trainingCampService.getTrainingCampsGroupedByFighter();
      // Filter to only show camps where the current fighter is involved
      const myCamps = allCamps.filter(camp => 
        camp.fighter?.user_id === fighterProfile?.user_id
      );
      setActiveTrainingCamps(myCamps);
    } catch (error) {
      console.error('Error loading active training camps:', error);
    }
  }, [fighterProfile?.user_id]);

  const loadCalloutRequests = useCallback(async () => {
    if (!fighterProfile?.user_id) return;
    try {
      const callouts = await calloutService.getPendingCallouts(fighterProfile.user_id);
      setCalloutRequests(callouts);
    } catch (error) {
      console.error('Error loading callout requests:', error);
    }
  }, [fighterProfile?.user_id]);

  const loadScheduledCallouts = useCallback(async () => {
    if (!fighterProfile?.user_id) return;
    try {
      const callouts = await calloutService.getScheduledCallouts(fighterProfile.user_id);
      setScheduledCallouts(callouts);
    } catch (error) {
      console.error('Error loading scheduled callouts:', error);
    }
  }, [fighterProfile?.user_id]);

  const loadRanking = useCallback(async () => {
    if (!fighterProfile?.user_id) return;
    try {
      const fighters = await HomePageService.getTopFighters(1000);
      const myIndex = fighters.findIndex((f) => f.id === fighterProfile.user_id);
      setRank(myIndex >= 0 ? myIndex + 1 : null);
    } catch (error) {
      console.error('Error loading ranking:', error);
    }
  }, [fighterProfile?.user_id]);

  const loadMyTournaments = useCallback(async () => {
    if (!fighterProfile?.id) return;
    try {
      // Get all tournaments where fighter is a participant
      const { data: participations, error } = await supabase
        .from(TABLES.TOURNAMENT_PARTICIPANTS)
        .select('tournament_id')
        .eq('fighter_id', fighterProfile.id);

      if (error) throw error;

      if (participations && participations.length > 0) {
        const tournamentIds = participations.map(p => p.tournament_id);
        const tournaments = await Promise.all(
          tournamentIds.map(id => TournamentService.getTournamentById(id))
        );
        setMyTournaments(tournaments.filter(t => t !== null) as Tournament[]);
      } else {
        setMyTournaments([]);
      }
    } catch (error) {
      console.error('Error loading my tournaments:', error);
    }
  }, [fighterProfile?.id]);

  const loadFightUrlSubmissions = useCallback(async () => {
    if (!fighterProfile?.id) return;
    try {
      const submissions = await fightUrlSubmissionService.getFighterSubmissions(fighterProfile.id);
      setFightUrlSubmissions(submissions);
    } catch (error) {
      console.error('Error loading fight URL submissions:', error);
    }
  }, [fighterProfile?.id]);

  useEffect(() => {
    if (fighterProfile?.user_id) {
      loadFightRecords();
      loadScheduledFights();
      loadMandatoryFights();
      loadRanking();
      loadMyTournaments();
      loadFightUrlSubmissions();
      loadTrainingCampInvitations();
      loadActiveTrainingCamps();
      loadCalloutRequests();
      loadScheduledCallouts();
      
      // Update edit form when fighter profile changes
      setEditForm({
        fighterName: fighterProfile?.name || '',
        height_feet: (fighterProfile as any)?.height_feet || 0,
        height_inches: (fighterProfile as any)?.height_inches || 0,
        weight: fighterProfile?.weight || 0,
        reach: fighterProfile?.reach || 0,
        stance: (fighterProfile as any)?.stance || 'orthodox',
        platform: (fighterProfile as any)?.platform || 'PC',
        timezone: (fighterProfile as any)?.timezone || Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC',
        hometown: fighterProfile?.hometown || '',
        trainer: fighterProfile?.trainer || '',
        gym: fighterProfile?.gym || '',
        birthday: (fighterProfile as any)?.birthday 
          ? (typeof (fighterProfile as any).birthday === 'string' 
              ? (fighterProfile as any).birthday.split('T')[0] 
              : new Date((fighterProfile as any).birthday).toISOString().split('T')[0])
          : '',
        weight_class: normalizeWeightClass(fighterProfile?.weight_class) || '',
      });
    }

    // Subscribe to real-time changes in fight_url_submissions table
    const channelName = `fight_url_submissions_changes_fighter_${fighterProfile?.id || 'default'}`;
    const submissionsChannel = supabase
      .channel(channelName)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'fight_url_submissions',
        },
        (payload) => {
          console.log('Fight URL submission changed (real-time) in FighterProfile:', payload);
          console.log('Event type:', payload.eventType);
          console.log('Full payload:', JSON.stringify(payload, null, 2));
          
          // For DELETE events, immediately filter out the deleted submission for instant UI update
          if (payload.eventType === 'DELETE') {
            const deletedId = payload.old?.id;
            const deletedFighterId = payload.old?.fighter_id;
            const deletedStatus = payload.old?.status;
            const currentFighterId = fighterProfile?.id;
            
            // Check if the deleted submission belongs to this fighter
            const belongsToFighter = currentFighterId && deletedFighterId === currentFighterId;
            
            if (deletedId && belongsToFighter) {
              setFightUrlSubmissions(prevSubmissions => {
                const filtered = prevSubmissions.filter(s => s.id !== deletedId);
                console.log('Fighter: Filtered out deleted submission ID:', deletedId, 'Remaining:', filtered.length);
                return filtered;
              });
            } else if ((deletedStatus === 'Approved' || deletedStatus === 'Rejected') && belongsToFighter) {
              // If we can't get the ID or it belongs to this fighter, filter by status (fallback for bulk deletes)
              console.log('Fighter: DELETE event received, filtering all approved/rejected submissions');
              setFightUrlSubmissions(prevSubmissions => {
                const filtered = prevSubmissions.filter(s => s.status !== 'Approved' && s.status !== 'Rejected');
                console.log('Fighter: Filtered out approved/rejected submissions. Remaining:', filtered.length);
                return filtered;
              });
            }
            
            // Always reload for DELETE events to ensure consistency
            setTimeout(() => {
              console.log('Fighter: Reloading submissions after DELETE event');
              loadFightUrlSubmissions();
            }, 100);
            
            setTimeout(() => {
              console.log('Fighter: Second reload after DELETE event');
              loadFightUrlSubmissions();
            }, 500);
            
            setTimeout(() => {
              console.log('Fighter: Third reload after DELETE event (final check)');
              loadFightUrlSubmissions();
            }, 1500);
          } else {
            // For other events (INSERT, UPDATE), reload after a short delay
            setTimeout(() => {
              console.log('Fighter: Reloading submissions after real-time event');
              loadFightUrlSubmissions();
            }, 200);
          }
        }
      )
      .subscribe();

    // Set up polling as a fallback (every 3 seconds) to catch deletions that real-time might miss
    const pollInterval = setInterval(() => {
      console.log('Fighter: Polling for submission updates...');
      if (fighterProfile?.id) {
        loadFightUrlSubmissions();
      }
    }, 3000);

    // Also reload when the window/tab regains focus (in case real-time events were missed)
    const handleFocus = () => {
      console.log('Fighter: Window regained focus, reloading submissions');
      if (fighterProfile?.id) {
        loadFightUrlSubmissions();
      }
    };
    window.addEventListener('focus', handleFocus);

    // Subscribe to real-time changes
    const unsubscribeScheduledFights = subscribeToScheduledFights((payload) => {
      console.log('Scheduled fight changed - reloading:', payload);
      // Reload scheduled fights in real-time (managed by Smart Matchmaking)
      if (fighterProfile?.user_id) {
        loadScheduledFights();
      }
    });

    const unsubscribeFightRecords = subscribeToFightRecords((payload) => {
      console.log('Fight record changed - reloading:', payload);
      // Reload fight records and stats
      if (fighterProfile?.user_id) {
        loadFightRecords();
        loadRanking();
      }
    });

    const unsubscribeFighterProfiles = subscribeToFighterProfiles((payload) => {
      console.log('Fighter profile changed:', payload);
      // Update if it's the current fighter's profile
      if (fighterProfile?.user_id && payload.new?.user_id === fighterProfile.user_id) {
        // Profile was updated (points, tier, weight_class, etc.), reload all data
        console.log('Fighter profile updated - refreshing all data:', {
          old: payload.old,
          new: payload.new,
          changes: {
            points: payload.old?.points !== payload.new?.points,
            tier: payload.old?.tier !== payload.new?.tier,
            weight_class: payload.old?.weight_class !== payload.new?.weight_class,
            wins: payload.old?.wins !== payload.new?.wins,
            losses: payload.old?.losses !== payload.new?.losses,
            draws: payload.old?.draws !== payload.new?.draws
          }
        });
        // Refresh the fighter profile from context
        refreshFighterProfile();
        // Reload all related data
        loadFightRecords();
        loadScheduledFights();
        loadRanking();
        loadMyTournaments();
      }
    });

    // Subscribe to tournament changes
    const tournamentChannel = supabase
      .channel('tournaments_changes')
      .on('postgres_changes', 
        { event: '*', schema: 'public', table: 'tournaments' },
        () => {
          loadMyTournaments();
        }
      )
      .on('postgres_changes',
        { event: '*', schema: 'public', table: 'tournament_participants' },
        () => {
          if (fighterProfile?.id) {
            loadMyTournaments();
          }
        }
      )
      .subscribe();

    // Subscribe to training camp changes
    // Reload invitations whenever any invitation changes (getPendingInvitations filters correctly)
    const trainingCampChannel = supabase
      .channel('fighter_training_camp_updates')
      .on('postgres_changes',
        { 
          event: '*', 
          schema: 'public', 
          table: 'training_camp_invitations'
        },
        (payload) => {
          console.log('Training camp invitation changed - reloading...', payload);
          if (fighterProfile?.user_id) {
            // Reload invitations - getPendingInvitations will filter to only show invitations for this fighter
            loadTrainingCampInvitations();
            // Also reload active camps in case an invitation was accepted
            loadActiveTrainingCamps();
          }
        }
      )
      .subscribe();

    // Subscribe to callout changes for real-time updates
    const calloutChannel = supabase
      .channel('fighter_callout_updates')
      .on('postgres_changes',
        { 
          event: '*', 
          schema: 'public', 
          table: 'callout_requests'
        },
        (payload) => {
          console.log('Callout request changed - reloading...', payload);
          if (fighterProfile?.user_id) {
            loadCalloutRequests();
            loadScheduledCallouts();
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(submissionsChannel);
      clearInterval(pollInterval);
      window.removeEventListener('focus', handleFocus);
      unsubscribeScheduledFights();
      unsubscribeFightRecords();
      unsubscribeFighterProfiles();
      supabase.removeChannel(tournamentChannel);
      supabase.removeChannel(trainingCampChannel);
      supabase.removeChannel(calloutChannel);
    };
  }, [
    fighterProfile,
    loadActiveTrainingCamps,
    loadCalloutRequests,
    loadFightRecords,
    loadFightUrlSubmissions,
    loadMandatoryFights,
    loadMyTournaments,
    loadRanking,
    loadScheduledCallouts,
    loadScheduledFights,
    loadTrainingCampInvitations,
    subscribeToFightRecords,
    subscribeToFighterProfiles,
    subscribeToScheduledFights,
  ]);

  const handleAcceptTrainingCamp = async (invitationId: string) => {
    if (!fighterProfile?.user_id) return;
    try {
      setAcceptingInvitation(invitationId);
      await trainingCampService.acceptInvitation(invitationId, fighterProfile.user_id);
      await loadTrainingCampInvitations();
      await loadActiveTrainingCamps();
      alert('Training camp invitation accepted! Your training camp has started.');
    } catch (error: any) {
      console.error('Error accepting training camp invitation:', error);
      alert('Failed to accept invitation: ' + (error.message || 'Unknown error'));
    } finally {
      setAcceptingInvitation(null);
    }
  };

  const handleDeclineTrainingCamp = async (invitationId: string) => {
    if (!fighterProfile?.user_id) return;
    try {
      setDecliningInvitation(invitationId);
      await trainingCampService.declineInvitation(invitationId, fighterProfile.user_id);
      await loadTrainingCampInvitations();
      alert('Training camp invitation declined.');
    } catch (error: any) {
      console.error('Error declining training camp invitation:', error);
      alert('Failed to decline invitation: ' + (error.message || 'Unknown error'));
    } finally {
      setDecliningInvitation(null);
    }
  };

  const handleAcceptCallout = async (calloutId: string) => {
    if (!fighterProfile?.user_id) return;
    try {
      setAcceptingCallout(calloutId);
      await calloutService.acceptCallout(calloutId, fighterProfile.user_id);
      await loadCalloutRequests();
      await loadScheduledCallouts();
      await loadScheduledFights();
      alert('Callout accepted! Fight has been scheduled.');
    } catch (error: any) {
      console.error('Error accepting callout:', error);
      alert('Failed to accept callout: ' + (error.message || 'Unknown error'));
    } finally {
      setAcceptingCallout(null);
    }
  };

  const handleDeclineCallout = async (calloutId: string) => {
    if (!fighterProfile?.user_id) return;
    try {
      setDecliningCallout(calloutId);
      await calloutService.declineCallout(calloutId, fighterProfile.user_id);
      await loadCalloutRequests();
      alert('Callout declined.');
    } catch (error: any) {
      console.error('Error declining callout:', error);
      alert('Failed to decline callout: ' + (error.message || 'Unknown error'));
    } finally {
      setDecliningCallout(null);
    }
  };

  const handleAcceptFightRequest = async (fightId: string) => {
    if (!fighterProfile?.user_id) return;
    try {
      setAcceptingFight(fightId);
      
      // Get the fight details to check if fighters have fought before
      const { data: fight, error: fightError } = await supabase
        .from('scheduled_fights')
        .select('fighter1_id, fighter2_id, match_type, created_at')
        .eq('id', fightId)
        .single();

      if (fightError || !fight) {
        throw new Error('Fight not found');
      }

      // Get current fighter profile ID
      const { data: currentFighter } = await supabase
        .from('fighter_profiles')
        .select('id')
        .eq('user_id', fighterProfile.user_id)
        .single();

      if (!currentFighter) {
        throw new Error('Fighter profile not found');
      }

      // For mandatory fights (match_type = 'manual'), check if fighters have fought before
      if (fight.match_type === 'manual') {
        const opponentId = fight.fighter1_id === currentFighter.id ? fight.fighter2_id : fight.fighter1_id;
        
        // Check for completed fights between these two fighters since the last weekly reset (7 days ago)
        const oneWeekAgo = new Date();
        oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

        const { data: previousFights, error: previousFightsError } = await supabase
          .from('scheduled_fights')
          .select('id, status, created_at')
          .or(`and(fighter1_id.eq.${currentFighter.id},fighter2_id.eq.${opponentId}),and(fighter1_id.eq.${opponentId},fighter2_id.eq.${currentFighter.id})`)
          .eq('status', 'Completed')
          .gte('created_at', oneWeekAgo.toISOString())
          .limit(1);

        if (previousFightsError) {
          console.error('Error checking previous fights:', previousFightsError);
        }

        if (previousFights && previousFights.length > 0) {
          alert('You cannot accept this mandatory fight request because you have already fought this opponent this week. Wait for the weekly reset or use the Callout system for a rematch.');
          return;
        }
      }

      // Update fight status to Scheduled
      const { error } = await supabase
        .from('scheduled_fights')
        .update({ status: 'Scheduled' })
        .eq('id', fightId);
      
      if (error) throw error;
      
      await loadScheduledFights();
      alert('Fight request accepted! The fight has been scheduled.');
    } catch (error: any) {
      console.error('Error accepting fight request:', error);
      alert('Failed to accept fight request: ' + (error.message || 'Unknown error'));
    } finally {
      setAcceptingFight(null);
    }
  };

  const handleDenyFightRequest = async (fightId: string) => {
    if (!fighterProfile?.user_id) return;
    try {
      setDenyingFight(fightId);
      // Update fight status to Cancelled
      const { error } = await supabase
        .from('scheduled_fights')
        .update({ status: 'Cancelled' })
        .eq('id', fightId);
      
      if (error) throw error;
      
      await loadScheduledFights();
      alert('Fight request denied.');
    } catch (error: any) {
      console.error('Error denying fight request:', error);
      alert('Failed to deny fight request: ' + (error.message || 'Unknown error'));
    } finally {
      setDenyingFight(null);
    }
  };


  const handleSubmitFightUrl = async () => {
    if (!fighterProfile?.id || !newSubmission.fight_url.trim()) return;
    
    try {
      setSubmittingUrl(true);
      await fightUrlSubmissionService.submitFightUrl(
        {
          ...newSubmission,
          scheduled_fight_id: selectedFightForSubmission?.id,
        },
        fighterProfile.id
      );
      setSubmissionDialogOpen(false);
      setNewSubmission({
        fight_url: '',
        event_type: 'Live Event',
        description: '',
      });
      setSelectedFightForSubmission(null);
      await loadFightUrlSubmissions();
      alert('Fight URL submitted successfully! Admin will review it.');
    } catch (error: any) {
      console.error('Error submitting fight URL:', error);
      alert('Failed to submit fight URL: ' + (error.message || 'Unknown error'));
    } finally {
      setSubmittingUrl(false);
    }
  };

  const handleDeleteSubmissionClick = (submissionId: string) => {
    setSubmissionToDelete(submissionId);
    setDeleteSubmissionDialogOpen(true);
  };

  const handleConfirmDeleteSubmission = async () => {
    if (!submissionToDelete) return;
    
    try {
      await fightUrlSubmissionService.deleteSubmission(submissionToDelete);
      await loadFightUrlSubmissions();
      setDeleteSubmissionDialogOpen(false);
      setSubmissionToDelete(null);
      alert('Submission deleted successfully.');
    } catch (error: any) {
      console.error('Error deleting submission:', error);
      alert('Failed to delete submission: ' + (error.message || 'Unknown error'));
    }
  };

  const handleSaveEdit = async () => {
    if (!fighterProfile) return;
    setLoading(true);
    setError(null);
    
    // Validate weight class change (if changed)
    if (editForm.weight_class !== fighterProfile?.weight_class) {
      const originalWeightClass = (fighterProfile as any)?.original_weight_class || fighterProfile?.weight_class;
      
      if (originalWeightClass && !isWeightClassAllowed(originalWeightClass, editForm.weight_class)) {
        const diff = getWeightClassDifference(originalWeightClass, editForm.weight_class);
        const allowed = getAllowedWeightClasses(originalWeightClass);
        setError(
          `Weight class change not allowed. You can only move ±3 weight classes from your original (${originalWeightClass}). ` +
          `Allowed classes: ${allowed.join(', ')}. Current change: ${Math.abs(diff)} classes ${diff > 0 ? 'up' : 'down'}.`
        );
        setLoading(false);
        return;
      }
    }
    
    try {
      await updateFighterProfile({
        name: editForm.fighterName,
        height_feet: editForm.height_feet,
        height_inches: editForm.height_inches,
        weight: editForm.weight,
        reach: editForm.reach,
        stance: editForm.stance,
        platform: editForm.platform,
        timezone: editForm.timezone,
        hometown: editForm.hometown,
        trainer: editForm.trainer,
        gym: editForm.gym,
        birthday: editForm.birthday,
        weight_class: editForm.weight_class,
      });
      setIsEditing(false);
    } catch (error) {
      console.error('Error updating profile:', error);
      setError('Failed to update profile. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleCancelEdit = () => {
    setEditForm({
      fighterName: fighterProfile?.name || '',
      height_feet: (fighterProfile as any)?.height_feet || 0,
      height_inches: (fighterProfile as any)?.height_inches || 0,
      weight: fighterProfile?.weight || 0,
      reach: fighterProfile?.reach || 0,
      stance: (fighterProfile as any)?.stance || 'orthodox',
      platform: (fighterProfile as any)?.platform || 'PC',
      timezone: (fighterProfile as any)?.timezone || Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC',
      hometown: fighterProfile?.hometown || '',
      trainer: fighterProfile?.trainer || '',
      gym: fighterProfile?.gym || '',
      birthday: (fighterProfile as any)?.birthday 
        ? (typeof (fighterProfile as any).birthday === 'string' 
            ? (fighterProfile as any).birthday.split('T')[0] 
            : new Date((fighterProfile as any).birthday).toISOString().split('T')[0])
        : '',
      weight_class: normalizeWeightClass(fighterProfile?.weight_class) || '',
    });
    setIsEditing(false);
  };

  const handleAddFightRecord = async () => {
    if (!fighterProfile?.user_id) {
      setFightRecordError('Fighter profile not found');
      return;
    }

    // Validate required fields
    if (!newFightRecord.opponent_name.trim()) {
      setFightRecordError('Opponent name is required');
      return;
    }
    if (!newFightRecord.method.trim()) {
      setFightRecordError('Method is required (e.g., KO, Decision, TKO)');
      return;
    }
    if (!newFightRecord.date) {
      setFightRecordError('Date is required');
      return;
    }

    setFightRecordError(null);
    setLoading(true);
    try {
      // Normalize method early so it's available for both points calculation and KO check
      const methodUpper = newFightRecord.method.trim().toUpperCase();
      
      // Calculate points based on result and method
      // REQUIREMENT: Win = +5, Loss = -3, Draw = 0, KO/TKO bonus = +3 (only for winners)
      let pointsEarned = 0;
      if (newFightRecord.result === 'win') {
        pointsEarned = 5;
        // KO/TKO bonus only applies to winners
        if (methodUpper === 'KO' || methodUpper === 'TKO') {
          pointsEarned += 3; // Total: 8 points for KO/TKO win
        }
      } else if (newFightRecord.result === 'loss') {
        pointsEarned = -3; // REQUIREMENT: Loss = -3 points
      } else if (newFightRecord.result === 'draw') {
        pointsEarned = 0;
      }

      // Capitalize result to match database constraint ('Win', 'Loss', 'Draw')
      const capitalizedResult = newFightRecord.result.charAt(0).toUpperCase() + newFightRecord.result.slice(1) as 'Win' | 'Loss' | 'Draw';

      // Normalize method to match database constraint
      const normalizedMethod = normalizeMethod(newFightRecord.method.trim());

      // Build fight record object - only include fields that exist in database
      const fightRecord: any = {
        fighter_id: fighterProfile.user_id,
        opponent_name: newFightRecord.opponent_name.trim(),
        result: capitalizedResult,
        method: normalizedMethod,
        date: newFightRecord.date,
        weight_class: newFightRecord.weight_class || fighterProfile.weight_class || 'Unknown',
        points_earned: pointsEarned,
      };
      
      // Add round if provided (some schemas require it, others allow null)
      if (newFightRecord.round && newFightRecord.round !== '') {
        const roundNum = parseInt(newFightRecord.round);
        if (!isNaN(roundNum) && roundNum > 0) {
          fightRecord.round = roundNum;
        }
      } else {
        // If round is required, default to 1
        fightRecord.round = 1;
      }
      
      // Only include is_tournament_win if column exists (will be caught by DB if it doesn't)
      // Try to include it but handle gracefully if column doesn't exist
      if (newFightRecord.is_tournament_win && newFightRecord.result === 'win') {
        fightRecord.is_tournament_win = true;
      }

      console.log('Inserting fight record:', fightRecord);

      const { error, data } = await supabase.from('fight_records').insert(fightRecord).select();
      if (error) {
        console.error('Supabase error details:', {
          message: error.message,
          code: error.code,
          details: error.details,
          hint: error.hint,
          fullError: error
        });
        console.error('Fight record being inserted:', JSON.stringify(fightRecord, null, 2));
        
        // Provide more detailed error message
        let errorMessage = 'Failed to add fight record. ';
        if (error.message) {
          errorMessage += error.message;
        } else if (error.code) {
          errorMessage += `Error code: ${error.code}`;
        } else {
          errorMessage += 'Unknown error occurred.';
        }
        
        if (error.details) {
          errorMessage += ` Details: ${error.details}`;
        }
        if (error.hint) {
          errorMessage += ` Hint: ${error.hint}`;
        }
        
        throw new Error(errorMessage);
      }

      console.log('Fight record inserted successfully:', data);

      // Auto-post fight result to News/Announcements (AI Mike Glove)
      try {
        const fighterName = fighterProfile.name || 'Fighter';
        const opponentName = newFightRecord.opponent_name.trim();
        const resultText = newFightRecord.result === 'win' ? 'defeated' : 
                          newFightRecord.result === 'loss' ? 'lost to' : 'drew with';
        const methodText = normalizedMethod;
        const roundText = newFightRecord.round ? ` in Round ${newFightRecord.round}` : '';
        const weightClassText = newFightRecord.weight_class || fighterProfile.weight_class || 'Unknown';
        
        const title = `${fighterName} ${resultText.charAt(0).toUpperCase() + resultText.slice(1)} ${opponentName} via ${methodText}${roundText}`;
        const content = `${fighterName} ${resultText} ${opponentName} via ${methodText}${roundText} in the ${weightClassText} division.`;
        
        await NewsService.createNewsItem({
          title,
          content,
          author: 'Mike Glove',
          author_title: 'TBC News Reporter',
          type: 'fight_result',
          priority: 'medium',
          tags: ['Fight Results', weightClassText, normalizedMethod],
          is_published: true,
          published_at: new Date().toISOString(),
        });
        
        console.log('Fight result auto-posted to News/Announcements');
      } catch (newsError) {
        // Don't fail the fight record creation if news posting fails
        console.warn('Failed to auto-post fight result to news:', newsError);
      }

      // Update fighter stats
      const wins = fighterProfile.wins + (newFightRecord.result === 'win' ? 1 : 0);
      const losses = fighterProfile.losses + (newFightRecord.result === 'loss' ? 1 : 0);
      const draws = fighterProfile.draws + (newFightRecord.result === 'draw' ? 1 : 0);
      const total = wins + losses + draws;
      const winPercentage = total > 0 ? (wins / total) * 100 : 0;
      
      // Check if it's a KO/TKO for knockouts stat (methodUpper already declared above)
      const isKO = (newFightRecord.result === 'win' && (methodUpper === 'KO' || methodUpper === 'TKO'));
      const currentKnockouts = (fighterProfile as any).knockouts || 0;
      const newKnockouts = isKO ? currentKnockouts + 1 : currentKnockouts;

      // Update fighter profile stats
      try {
        const updateData: any = {
          wins,
          losses,
          draws,
          points: (fighterProfile.points || 0) + pointsEarned,
        };
        
        // Add knockouts if column exists
        if ('knockouts' in fighterProfile || (fighterProfile as any).knockouts !== undefined) {
          updateData.knockouts = newKnockouts;
        }
        
        // Add win_percentage if column exists
        if ('win_percentage' in fighterProfile || (fighterProfile as any).win_percentage !== undefined) {
          updateData.win_percentage = parseFloat(winPercentage.toFixed(2));
        }
        
        await updateFighterProfile(updateData);
      } catch (updateError: any) {
        // If columns don't exist, try updating with minimal fields
        if (updateError?.message?.includes('knockouts') || 
            updateError?.message?.includes('win_percentage') ||
            updateError?.message?.includes('ko_percentage')) {
          console.warn('Some percentage columns not found. Please run add-percentage-columns.sql and add-knockouts-column.sql');
          await updateFighterProfile({
            wins,
            losses,
            draws,
            points: (fighterProfile.points || 0) + pointsEarned,
          });
        } else {
          throw updateError;
        }
      }

      setNewFightRecord({
        opponent_name: '',
        result: 'win',
        method: '',
        round: '',
        date: '',
        weight_class: normalizeWeightClass(fighterProfile.weight_class) || '',
        is_tournament_win: false,
      });
      setFightRecordError(null);
      setAddFightDialogOpen(false);
      
      // Reload fight records and refresh fighter profile to get updated points from database trigger
      await loadFightRecords();
      
      // Wait a moment for the database trigger to complete, then refresh fighter profile
      // The trigger updates points, wins, losses, etc. automatically
      setTimeout(async () => {
        await refreshFighterProfile();
        await loadRanking(); // Also refresh ranking
      }, 500); // Small delay to ensure trigger has completed
    } catch (error: any) {
      console.error('Error adding fight record:', error);
      setFightRecordError(error.message || 'Failed to add fight record. Please check the console for details.');
    } finally {
      setLoading(false);
    }
  };

  if (!fighterProfile) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  const totalFights = fighterProfile.wins + fighterProfile.losses + fighterProfile.draws;
  const winPercentage = totalFights > 0 ? ((fighterProfile.wins / totalFights) * 100).toFixed(1) : '0.0';
  const koPercentage = totalFights > 0 && (fighterProfile as any).knockouts
    ? (((fighterProfile as any).knockouts / totalFights) * 100).toFixed(1)
    : '0.0';

  return (
    <>
      {/* Full-screen background layer */}
      <Box
        sx={{
          position: 'fixed',
          top: 0,
          left: { xs: 0, sm: '240px' },
          right: 0,
          bottom: 0,
          width: { xs: '100%', sm: 'calc(100% - 240px)' },
          height: '100vh',
          backgroundImage: `url(${wbcBlack})`,
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          backgroundRepeat: 'no-repeat',
          zIndex: 0,
          '&::before': {
            content: '""',
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.4)',
          },
        }}
      />
      {/* Content layer */}
      <Box 
        sx={{ 
          position: 'relative',
          zIndex: 1,
          py: 4,
          m: -3,
          px: 3,
          minHeight: '100vh',
        }}
      >
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
              <Typography variant="h3" gutterBottom sx={{ fontWeight: 'bold', color: 'white' }}>
                {fighterProfile.name}
              </Typography>
              <Typography variant="h6" color="text.secondary">
                @{fighterProfile.handle}
              </Typography>
            </Box>
          </Box>
          <Chip
            label={fighterProfile.tier || 'Amateur'}
            color="primary"
            sx={{ fontSize: '1rem', padding: '8px 16px', height: 'auto' }}
          />
        </Box>
        <Divider />
      </Box>

      {/* Stats Cards */}
      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 3, mb: 4 }}>
        <Box sx={{ flex: { xs: '1 1 100%', sm: '1 1 calc(50% - 12px)', md: '1 1 calc(25% - 18px)' }, minWidth: { xs: '100%', sm: 'calc(50% - 12px)', md: 'calc(25% - 18px)' } }}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <EmojiEvents sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="body2" color="text.secondary">
                  Record
                </Typography>
              </Box>
              <Typography variant="h4" sx={{ fontWeight: 'bold' }}>
                {fighterProfile.wins}-{fighterProfile.losses}-{fighterProfile.draws}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {winPercentage}% Win Rate
              </Typography>
            </CardContent>
          </Card>
        </Box>
        <Box sx={{ flex: { xs: '1 1 100%', sm: '1 1 calc(50% - 12px)', md: '1 1 calc(25% - 18px)' }, minWidth: { xs: '100%', sm: 'calc(50% - 12px)', md: 'calc(25% - 18px)' } }}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <TrendingUp sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="body2" color="text.secondary">
                  Points
                </Typography>
              </Box>
              <Typography variant="h4" sx={{ fontWeight: 'bold' }}>
                {fighterProfile.points || 0}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {rank ? `Ranked #${rank}` : 'Unranked'}
              </Typography>
            </CardContent>
          </Card>
        </Box>
        <Box sx={{ flex: { xs: '1 1 100%', sm: '1 1 calc(50% - 12px)', md: '1 1 calc(25% - 18px)' }, minWidth: { xs: '100%', sm: 'calc(50% - 12px)', md: 'calc(25% - 18px)' } }}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <SportsMma sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="body2" color="text.secondary">
                  Knockouts
                </Typography>
              </Box>
              <Typography variant="h4" sx={{ fontWeight: 'bold' }}>
                {(fighterProfile as any).knockouts || 0}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {koPercentage}% KO Rate
              </Typography>
            </CardContent>
          </Card>
        </Box>
        <Box sx={{ flex: { xs: '1 1 100%', sm: '1 1 calc(50% - 12px)', md: '1 1 calc(25% - 18px)' }, minWidth: { xs: '100%', sm: 'calc(50% - 12px)', md: 'calc(25% - 18px)' } }}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <CalendarToday sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="body2" color="text.secondary">
                  Scheduled
                </Typography>
              </Box>
              <Typography variant="h4" sx={{ fontWeight: 'bold' }}>
                {scheduledFights.length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Upcoming Fights
              </Typography>
            </CardContent>
          </Card>
        </Box>
      </Box>

      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 3 }}>
        {/* Physical Information */}
        <Box sx={{ flex: { xs: '1 1 100%', md: '1 1 calc(50% - 12px)' }, minWidth: { xs: '100%', md: 'calc(50% - 12px)' } }}>
          <Card>
            <CardContent>
              <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
                <Typography variant="h5" sx={{ fontWeight: 'bold' }}>
                  Physical Information
                </Typography>
                {!isEditing && (
                  <IconButton onClick={() => setIsEditing(true)} color="primary">
                    <Edit />
                  </IconButton>
                )}
              </Box>
              
              {error && (
                <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
                  {error}
                </Alert>
              )}
              
              {/* Fighter Name - Prominently displayed at top */}
              {!isEditing && (
                <Box 
                  sx={{ 
                    mb: 3, 
                    p: 2, 
                    bgcolor: 'primary.main', 
                    borderRadius: 2,
                    color: 'white'
                  }}
                >
                  <Typography variant="body2" sx={{ opacity: 0.9, mb: 0.5 }}>
                    Fighter/Boxer Name
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 'bold' }}>
                    {fighterProfile?.name || 'Not set'}
                  </Typography>
                </Box>
              )}
              
              {isEditing ? (
                <Stack spacing={2}>
                  <TextField
                    label="Fighter/Boxer Name"
                    fullWidth
                    required
                    value={editForm.fighterName || fighterProfile?.name || ''}
                    onChange={(e) =>
                      setEditForm({ ...editForm, fighterName: e.target.value })
                    }
                    helperText="Your fighting name displayed across the platform"
                  />
                  <Box sx={{ display: 'flex', gap: 2 }}>
                    <TextField
                      label="Height (Feet)"
                      type="number"
                      sx={{ flex: 1 }}
                      value={editForm.height_feet || ''}
                      onChange={(e) => {
                        const value = e.target.value === '' ? 0 : parseInt(e.target.value) || 0;
                        setEditForm({ ...editForm, height_feet: value });
                      }}
                      inputProps={{ min: 3, max: 8 }}
                      helperText="Enter height in feet (3-8)"
                    />
                    <TextField
                      label="Height (Inches)"
                      type="number"
                      sx={{ flex: 1 }}
                      value={editForm.height_inches || ''}
                      onChange={(e) => {
                        const value = e.target.value === '' ? 0 : parseInt(e.target.value) || 0;
                        setEditForm({ ...editForm, height_inches: value });
                      }}
                      inputProps={{ min: 0, max: 11 }}
                      helperText="Enter inches (0-11)"
                    />
                  </Box>
                  <TextField
                    label="Weight (lbs)"
                    type="number"
                    fullWidth
                    value={editForm.weight || ''}
                    onChange={(e) => {
                      const value = e.target.value === '' ? 0 : parseInt(e.target.value) || 0;
                      setEditForm({ ...editForm, weight: value });
                    }}
                    inputProps={{ min: 80, max: 400 }}
                    helperText="Enter weight in pounds (80-400 lbs)"
                  />
                  <TextField
                    label="Reach (inches)"
                    type="number"
                    fullWidth
                    value={editForm.reach || ''}
                    onChange={(e) => {
                      const value = e.target.value === '' ? 0 : parseInt(e.target.value) || 0;
                      setEditForm({ ...editForm, reach: value });
                    }}
                    inputProps={{ min: 50, max: 100 }}
                    helperText="Enter reach in inches (50-100 inches)"
                  />
                  <TextField
                    label="Stance"
                    select
                    fullWidth
                    value={editForm.stance}
                    onChange={(e) => setEditForm({ ...editForm, stance: e.target.value })}
                    inputProps={{ 'aria-label': 'Stance' }}
                  >
                    <MenuItem value="orthodox">Orthodox</MenuItem>
                    <MenuItem value="southpaw">Southpaw</MenuItem>
                    <MenuItem value="switch">Switch</MenuItem>
                  </TextField>
                  <FormControl fullWidth>
                    <InputLabel id="platform-select-label">Platform</InputLabel>
                    <Select
                      label="Platform"
                      value={editForm.platform}
                      onChange={(e) => setEditForm({ ...editForm, platform: e.target.value })}
                      labelId="platform-select-label"
                      aria-labelledby="platform-select-label"
                    >
                      <MenuItem value="Xbox" aria-label="Xbox">Xbox</MenuItem>
                      <MenuItem value="PSN" aria-label="PlayStation/PSN">PlayStation/PSN</MenuItem>
                      <MenuItem value="PC" aria-label="Steam/PC">Steam/PC</MenuItem>
                    </Select>
                  </FormControl>
                  <FormControl fullWidth>
                    <InputLabel id="timezone-select-label">Timezone</InputLabel>
                    <Select
                      label="Timezone"
                      value={editForm.timezone}
                      onChange={(e) => setEditForm({ ...editForm, timezone: e.target.value })}
                      labelId="timezone-select-label"
                      aria-labelledby="timezone-select-label"
                    >
                      {COMMON_TIMEZONES.map((tz) => (
                        <MenuItem key={tz.value} value={tz.value} aria-label={tz.label}>
                          {tz.label}
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                  <TextField
                    label="Hometown"
                    fullWidth
                    value={editForm.hometown || ''}
                    onChange={(e) => setEditForm({ ...editForm, hometown: e.target.value })}
                    helperText="Enter your hometown (e.g., City, State/Country)"
                    placeholder="e.g., Las Vegas, NV"
                  />
                  <TextField
                    label="Trainer"
                    fullWidth
                    value={editForm.trainer || ''}
                    onChange={(e) => setEditForm({ ...editForm, trainer: e.target.value })}
                    helperText="Enter your coach or trainer's name"
                    placeholder="e.g., John Smith"
                  />
                  <TextField
                    label="Gym"
                    fullWidth
                    value={editForm.gym || ''}
                    onChange={(e) => setEditForm({ ...editForm, gym: e.target.value })}
                    helperText="Enter your gym or team name"
                    placeholder="e.g., Tantalus Boxing Club"
                  />
                  <TextField
                    label="Birthday"
                    type="date"
                    fullWidth
                    InputLabelProps={{ shrink: true }}
                    value={editForm.birthday || ''}
                    onChange={(e) => setEditForm({ ...editForm, birthday: e.target.value })}
                  />
                  <FormControl fullWidth>
                    <InputLabel id="weight-class-select-label">Weight Class</InputLabel>
                    <Select
                      label="Weight Class"
                      value={normalizeWeightClass(editForm.weight_class) || ''}
                      onChange={(e) => setEditForm({ ...editForm, weight_class: e.target.value })}
                      labelId="weight-class-select-label"
                      aria-labelledby="weight-class-select-label"
                    >
                      {(() => {
                        const originalWeightClass = (fighterProfile as any)?.original_weight_class || fighterProfile?.weight_class;
                        const allowedClasses = originalWeightClass 
                          ? getAllowedWeightClasses(originalWeightClass)
                          : WEIGHT_CLASS_ORDER;
                        
                        return WEIGHT_CLASS_ORDER.map((wc) => {
                          const isAllowed = allowedClasses.some(ac => ac.toLowerCase() === wc.toLowerCase());
                          const isOriginal = wc.toLowerCase() === originalWeightClass?.toLowerCase();
                          const isCurrent = wc.toLowerCase() === fighterProfile?.weight_class?.toLowerCase();
                          const displayText = `${wc}${isOriginal ? ' (Original)' : ''}${isCurrent && !isOriginal ? ' (Current)' : ''}${!isAllowed && originalWeightClass ? ' (Not Allowed - Exceeds ±3 limit)' : ''}`;
                          return (
                            <MenuItem 
                              key={wc} 
                              value={wc}
                              disabled={!isAllowed && !!originalWeightClass}
                              aria-label={displayText}
                            >
                              {wc}
                              {isOriginal && ' (Original)'}
                              {isCurrent && !isOriginal && ' (Current)'}
                              {!isAllowed && originalWeightClass && ' (Not Allowed - Exceeds ±3 limit)'}
                            </MenuItem>
                          );
                        });
                      })()}
                    </Select>
                    {(fighterProfile as any)?.original_weight_class && (
                      <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5, display: 'block' }}>
                        Original: {(fighterProfile as any).original_weight_class} • You can move up to 3 classes up or down
                      </Typography>
                    )}
                  </FormControl>
                  <Box display="flex" gap={2}>
                    <Button
                      variant="contained"
                      startIcon={<Save />}
                      onClick={handleSaveEdit}
                      disabled={loading}
                    >
                      Save
                    </Button>
                    <Button
                      variant="outlined"
                      startIcon={<Cancel />}
                      onClick={handleCancelEdit}
                      disabled={loading}
                    >
                      Cancel
                    </Button>
                  </Box>
                </Stack>
              ) : (
                <Stack spacing={2}>
                  <Box display="flex" alignItems="center">
                    <Height sx={{ mr: 2, color: 'text.secondary' }} />
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        Height
                      </Typography>
                      <Typography variant="body1">
                        {(fighterProfile as any).height_feet || 0}'{(fighterProfile as any).height_inches || 0}"
                      </Typography>
                    </Box>
                  </Box>
                  <Box display="flex" alignItems="center">
                    <Scale sx={{ mr: 2, color: 'text.secondary' }} />
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        Weight
                      </Typography>
                      <Typography variant="body1">{fighterProfile.weight} lbs</Typography>
                    </Box>
                  </Box>
                  <Box display="flex" alignItems="center">
                    <Person sx={{ mr: 2, color: 'text.secondary' }} />
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        Reach
                      </Typography>
                      <Typography variant="body1">{fighterProfile.reach}"</Typography>
                    </Box>
                  </Box>
                  <Box display="flex" alignItems="center">
                    <SportsMma sx={{ mr: 2, color: 'text.secondary' }} />
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        Stance
                      </Typography>
                      <Typography variant="body1" textTransform="capitalize">
                        {(fighterProfile as any).stance || 'orthodox'}
                      </Typography>
                    </Box>
                  </Box>
                  <Box display="flex" alignItems="center">
                    <SportsMma sx={{ mr: 2, color: 'text.secondary' }} />
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        Platform
                      </Typography>
                      <Typography variant="body1">
                        {(fighterProfile as any)?.platform === 'PSN' ? 'PlayStation/PSN' : 
                         (fighterProfile as any)?.platform === 'Xbox' ? 'Xbox' : 
                         (fighterProfile as any)?.platform === 'PC' ? 'Steam/PC' : 
                         (fighterProfile as any)?.platform || 'Not set'}
                      </Typography>
                    </Box>
                  </Box>
                  <Box display="flex" alignItems="center">
                    <LocationOn sx={{ mr: 2, color: 'text.secondary' }} />
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        Timezone
                      </Typography>
                      <Typography variant="body1">
                        {getTimezoneLabel((fighterProfile as any)?.timezone || 'UTC')}
                      </Typography>
                    </Box>
                  </Box>
                  <Box display="flex" alignItems="center">
                    <LocationOn sx={{ mr: 2, color: 'text.secondary' }} />
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        Hometown
                      </Typography>
                      <Typography variant="body1">{fighterProfile.hometown}</Typography>
                    </Box>
                  </Box>
                  {fighterProfile.trainer && (
                    <Box display="flex" alignItems="center">
                      <Person sx={{ mr: 2, color: 'text.secondary' }} />
                      <Box>
                        <Typography variant="body2" color="text.secondary">
                          Trainer
                        </Typography>
                        <Typography variant="body1">{fighterProfile.trainer}</Typography>
                      </Box>
                    </Box>
                  )}
                  {fighterProfile.gym && (
                    <Box display="flex" alignItems="center">
                      <Business sx={{ mr: 2, color: 'text.secondary' }} />
                      <Box>
                        <Typography variant="body2" color="text.secondary">
                          Gym
                        </Typography>
                        <Typography variant="body1">{fighterProfile.gym}</Typography>
                      </Box>
                    </Box>
                  )}
                  {(fighterProfile as any).birthday && (
                    <Box display="flex" alignItems="center">
                      <CalendarToday sx={{ mr: 2, color: 'text.secondary' }} />
                      <Box>
                        <Typography variant="body2" color="text.secondary">
                          Birthday
                        </Typography>
                        <Typography variant="body1">
                          {(() => {
                            const birthday = (fighterProfile as any).birthday;
                            if (!birthday) return 'Not set';
                            try {
                              // Parse date string manually to avoid timezone issues
                              let dateStr = typeof birthday === 'string' 
                                ? birthday.split('T')[0] 
                                : birthday instanceof Date 
                                  ? birthday.toISOString().split('T')[0]
                                  : String(birthday);
                              
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
                      </Box>
                    </Box>
                  )}
                </Stack>
              )}
            </CardContent>
          </Card>
        </Box>

        {/* Promoter Information */}
        <Box sx={{ flex: { xs: '1 1 100%', md: '1 1 calc(50% - 12px)' }, minWidth: { xs: '100%', md: 'calc(50% - 12px)' } }}>
          <Card>
            <CardContent>
              <Typography variant="h5" sx={{ fontWeight: 'bold', mb: 3 }}>
                Promoter
              </Typography>
              <Box display="flex" alignItems="center" p={3} sx={{ bgcolor: 'primary.main', borderRadius: 2 }}>
                <Avatar sx={{ width: 60, height: 60, bgcolor: 'white', color: 'primary.main', mr: 2 }}>
                  <Business />
                </Avatar>
                <Box>
                  <Typography variant="h5" sx={{ color: 'white', fontWeight: 'bold' }}>
                    TBC Promotions
                  </Typography>
                  <Typography variant="body2" sx={{ color: 'rgba(255,255,255,0.8)' }}>
                    Official Promoter
                  </Typography>
                </Box>
              </Box>
              <Box mt={3}>
                <Typography variant="body2" color="text.secondary">
                  Weight Class
                </Typography>
                <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                  {fighterProfile.weight_class}
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Box>

        {/* Fight Records */}
        <Box sx={{ flex: '1 1 100%', minWidth: '100%' }}>
          <Card>
            <CardContent>
              <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
                <Typography variant="h5" sx={{ fontWeight: 'bold' }}>
                  Fight Record
                </Typography>
                <Button
                  variant="contained"
                  startIcon={<Add />}
                  onClick={(e) => {
                    e.currentTarget.blur();
                    setAddFightDialogOpen(true);
                  }}
                >
                  Add Fight
                </Button>
              </Box>
              
              {fightRecords.length === 0 ? (
                <Alert severity="info">No fight records yet. Add your first fight!</Alert>
              ) : (
                <TableContainer component={Paper} variant="outlined">
                  <Table>
                    <TableHead>
                      <TableRow>
                        <TableCell>Date</TableCell>
                        <TableCell>Opponent</TableCell>
                        <TableCell>Result</TableCell>
                        <TableCell>Method</TableCell>
                        <TableCell>Round</TableCell>
                        <TableCell>Weight Class</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {fightRecords.map((record) => (
                        <TableRow key={record.id}>
                          <TableCell>
                            {new Date(record.date).toLocaleDateString()}
                          </TableCell>
                          <TableCell>{record.opponent_name}</TableCell>
                          <TableCell>
                            <Box display="flex" alignItems="center" gap={0.5}>
                              <Chip
                                label={record.result.toUpperCase()}
                                color={
                                  record.result?.toLowerCase() === 'win'
                                    ? 'success'
                                    : record.result?.toLowerCase() === 'loss'
                                    ? 'error'
                                    : 'default'
                                }
                                size="small"
                              />
                              {(record as any).is_tournament_win && (
                                <Chip
                                  label="Tournament"
                                  size="small"
                                  color="warning"
                                  icon={<EmojiEvents sx={{ fontSize: 14 }} />}
                                />
                              )}
                            </Box>
                          </TableCell>
                          <TableCell>{record.method}</TableCell>
                          <TableCell>{record.round || 'N/A'}</TableCell>
                          <TableCell>{record.weight_class}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>
              )}
            </CardContent>
          </Card>
        </Box>

        {/* HIDDEN: Mandatory Fights (Auto-Matched) */}
        {/* <Box sx={{ flex: '1 1 100%', minWidth: '100%', mt: 3 }}>
          <Card sx={{ border: '2px solid', borderColor: 'warning.main' }}>
            <CardContent>
              <Box display="flex" alignItems="center" gap={1} mb={3}>
                <Notifications sx={{ color: 'warning.main' }} />
                <Typography variant="h5" sx={{ fontWeight: 'bold' }}>
                  Mandatory Fights
                </Typography>
              </Box>
              <Alert severity="warning" sx={{ mb: 2 }}>
                These fights were automatically matched based on your rankings, weight class, tier, and points. 
                You must complete these fights. Go to Matchmaking → Smart Matchmaking to trigger automatic matching.
              </Alert>
              {mandatoryFights.length === 0 ? (
                <Alert severity="info">
                  No mandatory fights at the moment. Use the Smart Matchmaking system to get automatically matched with opponents.
                </Alert>
              ) : (
                <Stack spacing={2}>
                  {mandatoryFights.map((fight) => (
                    <Card key={fight.id} variant="outlined" sx={{ bgcolor: 'rgba(255, 152, 0, 0.1)' }}>
                      <CardContent>
                        <Box display="flex" justifyContent="space-between" alignItems="center">
                          <Box flex={1}>
                            <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                              {fight.fighter1?.name || 'TBD'} vs {fight.fighter2?.name || 'TBD'}
                            </Typography>
                            <Typography variant="body2" color="text.secondary" mt={1}>
                              {fight.scheduled_date ? new Date(fight.scheduled_date).toLocaleDateString() : 'TBD'} • {fight.weight_class}
                            </Typography>
                            {fight.match_score && (
                              <Chip 
                                label={`Match Score: ${fight.match_score}%`} 
                                size="small" 
                                color="warning" 
                                sx={{ mt: 1 }}
                              />
                            )}
                          </Box>
                          <Chip label="MANDATORY" color="warning" />
                        </Box>
                      </CardContent>
                    </Card>
                  ))}
                </Stack>
              )}
            </CardContent>
          </Card>
        </Box> */}

        {/* Training Camp Invitations */}
        <Box sx={{ flex: '1 1 100%', minWidth: '100%', mt: 3 }}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" gap={1} mb={3}>
                <FitnessCenter sx={{ color: 'primary.main' }} />
                <Typography variant="h5" sx={{ fontWeight: 'bold' }}>
                  Training Camp Invitations
                </Typography>
              </Box>
              <Alert severity="info" sx={{ mb: 2 }}>
                Training camps last 72 hours. You cannot start a training camp within 3 days of a scheduled fight. 
                Go to Matchmaking → Training Camp to send invitations to other fighters.
              </Alert>
              {trainingCampInvitations.length === 0 ? (
                <Alert severity="info">
                  No pending training camp invitations. Other fighters can invite you, or you can send invitations from the Matchmaking page.
                </Alert>
              ) : (
                <Stack spacing={2}>
                  {trainingCampInvitations.map((invitation) => (
                    <Card key={invitation.id} variant="outlined">
                      <CardContent>
                        <Box display="flex" justifyContent="space-between" alignItems="center">
                          <Box flex={1}>
                            <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                              {invitation.inviter?.name || 'Unknown Fighter'} invited you to a Training Camp
                            </Typography>
                            <Typography variant="body2" color="text.secondary" mt={1}>
                              Duration: 72 hours • Expires: {new Date(invitation.expires_at).toLocaleString()}
                            </Typography>
                            {invitation.message && (
                              <Typography variant="body2" sx={{ mt: 1, fontStyle: 'italic' }}>
                                "{invitation.message}"
                              </Typography>
                            )}
                          </Box>
                          <Box display="flex" gap={1}>
                            <Button
                              variant="contained"
                              color="success"
                              startIcon={acceptingInvitation === invitation.id ? <CircularProgress size={16} /> : <CheckCircle />}
                              onClick={() => handleAcceptTrainingCamp(invitation.id)}
                              disabled={acceptingInvitation === invitation.id || decliningInvitation === invitation.id}
                            >
                              Accept
                            </Button>
                            <Button
                              variant="outlined"
                              color="error"
                              startIcon={decliningInvitation === invitation.id ? <CircularProgress size={16} /> : <CancelIcon />}
                              onClick={() => handleDeclineTrainingCamp(invitation.id)}
                              disabled={acceptingInvitation === invitation.id || decliningInvitation === invitation.id}
                            >
                              Decline
                            </Button>
                          </Box>
                        </Box>
                      </CardContent>
                    </Card>
                  ))}
                </Stack>
              )}
            </CardContent>
          </Card>
        </Box>

        {/* Active Training Camps */}
        <Box sx={{ flex: '1 1 100%', minWidth: '100%', mt: 3 }}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" gap={1} mb={3}>
                <FitnessCenter sx={{ color: 'success.main' }} />
                <Typography variant="h5" sx={{ fontWeight: 'bold' }}>
                  My Active Training Camps
                </Typography>
              </Box>
              <Alert severity="info" sx={{ mb: 2 }}>
                Your active training camps with sparring partners. Training camps last 72 hours. Maximum of 3 sparring partners allowed.
              </Alert>
              {activeTrainingCamps.length === 0 ? (
                <Alert severity="info">
                  You don't have any active training camps. Accept an invitation or send one from the Matchmaking page.
                </Alert>
              ) : (
                <Stack spacing={3}>
                  {activeTrainingCamps.map((campGroup, index) => {
                    const expiresAt = new Date(campGroup.expiresAt);
                    const now = new Date();
                    const hoursRemaining = Math.max(0, Math.floor((expiresAt.getTime() - now.getTime()) / (1000 * 60 * 60)));
                    const daysRemaining = Math.floor(hoursRemaining / 24);
                    const hoursInDay = hoursRemaining % 24;

                    return (
                      <Card key={index} variant="outlined" sx={{ borderColor: 'success.main' }}>
                        <CardContent>
                          <Box display="flex" alignItems="center" mb={2}>
                            <Box flex={1}>
                              <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                                {campGroup.fighter?.name || 'Unknown Fighter'}
                              </Typography>
                              <Typography variant="body2" color="text.secondary">
                                @{campGroup.fighter?.handle || 'unknown'} • {campGroup.fighter?.tier || 'Amateur'} • {campGroup.fighter?.points || 0} pts
                              </Typography>
                            </Box>
                            <Chip 
                              label={`${daysRemaining}d ${hoursInDay}h remaining`}
                              color={hoursRemaining < 24 ? 'error' : hoursRemaining < 48 ? 'warning' : 'success'}
                              size="small"
                            />
                          </Box>
                          
                          <Divider sx={{ my: 2 }} />
                          
                          <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                            Sparring Partners ({campGroup.sparringPartners.length}/3):
                          </Typography>
                          
                          {campGroup.sparringPartners.length === 0 ? (
                            <Alert severity="info" sx={{ mt: 1 }}>
                              No sparring partners yet.
                            </Alert>
                          ) : (
                            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2, mt: 1 }}>
                              {campGroup.sparringPartners.map((sp, idx) => (
                                <Card 
                                  key={idx} 
                                  variant="outlined" 
                                  sx={{ 
                                    p: 1.5, 
                                    flex: { xs: '1 1 100%', sm: '1 1 calc(50% - 8px)', md: '1 1 calc(33.333% - 11px)' },
                                    minWidth: { xs: '100%', sm: 'calc(50% - 8px)', md: 'calc(33.333% - 11px)' }
                                  }}
                                >
                                  <Box display="flex" alignItems="center" gap={1}>
                                    <Avatar
                                      sx={{
                                        width: 40,
                                        height: 40,
                                        background: 'linear-gradient(45deg, #2196F3 30%, #21CBF3 90%)'
                                      }}
                                    >
                                      {sp.partner?.name?.charAt(0) || '?'}
                                    </Avatar>
                                    <Box flex={1}>
                                      <Typography variant="body1" sx={{ fontWeight: 'bold' }}>
                                        {sp.partner?.name || 'Unknown Fighter'}
                                      </Typography>
                                      <Typography variant="caption" color="text.secondary">
                                        @{sp.partner?.handle || 'unknown'} • {sp.partner?.tier || 'Amateur'} • {sp.partner?.points || 0} pts
                                      </Typography>
                                    </Box>
                                  </Box>
                                </Card>
                              ))}
                            </Box>
                          )}
                          
                          <Box mt={2} display="flex" alignItems="center" gap={1}>
                            <Schedule sx={{ fontSize: 16, color: 'text.secondary' }} />
                            <Typography variant="caption" color="text.secondary">
                              Started: {new Date(campGroup.startedAt).toLocaleString()} • Expires: {new Date(campGroup.expiresAt).toLocaleString()}
                            </Typography>
                          </Box>
                        </CardContent>
                      </Card>
                    );
                  })}
                </Stack>
              )}
            </CardContent>
          </Card>
        </Box>

        {/* Rematch Requests */}
        <Box sx={{ flex: '1 1 100%', minWidth: '100%', mt: 3 }}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" gap={1} mb={3}>
                <SportsMma sx={{ color: 'error.main' }} />
                <Typography variant="h5" sx={{ fontWeight: 'bold' }}>
                  Rematch Requests
                </Typography>
              </Box>
              <Alert severity="info" sx={{ mb: 2 }}>
                When other fighters request a rematch with you, you'll receive the request here. Rematches are only available with fighters you have already fought. 
                Go to Matchmaking → Rematches to request rematches with fighters you've fought before.
              </Alert>
              {calloutRequests.length === 0 ? (
                <Alert severity="info">
                  No pending rematch requests. Other fighters can request rematches with you, or you can request rematches from the Matchmaking page.
                </Alert>
              ) : (
                <Stack spacing={2}>
                  {calloutRequests.map((callout) => (
                    <Card key={callout.id} variant="outlined" sx={{ borderColor: 'error.main' }}>
                      <CardContent>
                        <Box display="flex" justifyContent="space-between" alignItems="center">
                          <Box flex={1}>
                            <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                              {callout.caller?.name || 'Unknown Fighter'} requested a rematch!
                            </Typography>
                            <Typography variant="body2" color="text.secondary" mt={1}>
                              {callout.weight_class} • {callout.tier_match ? 'Same Tier' : 'Different Tier'}
                              {callout.rank_difference !== null && ` • Rank Diff: ${callout.rank_difference}`}
                              {callout.points_difference !== null && ` • Points Diff: ${callout.points_difference}`}
                            </Typography>
                            {callout.match_score && (
                              <Chip 
                                label={`Fair Match Score: ${callout.match_score}%`} 
                                size="small" 
                                color={callout.match_score >= 60 ? 'success' : 'warning'}
                                sx={{ mt: 1 }}
                              />
                            )}
                            {callout.message && (
                              <Typography variant="body2" sx={{ mt: 1, fontStyle: 'italic' }}>
                                "{callout.message}"
                              </Typography>
                            )}
                            <Typography variant="caption" color="text.secondary" display="block" sx={{ mt: 1 }}>
                              Expires: {new Date(callout.expires_at).toLocaleString()}
                            </Typography>
                          </Box>
                          <Box display="flex" gap={1}>
                            <Button
                              variant="contained"
                              color="success"
                              startIcon={acceptingCallout === callout.id ? <CircularProgress size={16} /> : <CheckCircle />}
                              onClick={() => handleAcceptCallout(callout.id)}
                              disabled={acceptingCallout === callout.id || decliningCallout === callout.id}
                            >
                              Accept
                            </Button>
                            <Button
                              variant="outlined"
                              color="error"
                              startIcon={decliningCallout === callout.id ? <CircularProgress size={16} /> : <CancelIcon />}
                              onClick={() => handleDeclineCallout(callout.id)}
                              disabled={acceptingCallout === callout.id || decliningCallout === callout.id}
                            >
                              Decline
                            </Button>
                          </Box>
                        </Box>
                      </CardContent>
                    </Card>
                  ))}
                </Stack>
              )}
            </CardContent>
          </Card>
        </Box>

        {/* Scheduled Rematches */}
        <Box sx={{ flex: '1 1 100%', minWidth: '100%', mt: 3 }}>
          <Card>
            <CardContent>
              <Typography variant="h5" sx={{ fontWeight: 'bold', mb: 3 }}>
                Scheduled Rematches
              </Typography>
              <Alert severity="info" sx={{ mb: 2 }}>
                Your accepted rematch requests that have been scheduled as fights.
              </Alert>
              {scheduledCallouts.length === 0 ? (
                <Alert severity="info">
                  You don't have any scheduled rematches. Accept a rematch request to schedule a fight.
                </Alert>
              ) : (
                <Stack spacing={2}>
                  {scheduledCallouts.map((callout) => {
                    const isCaller = callout.caller?.user_id === fighterProfile?.user_id;
                    const opponent = isCaller ? callout.target : callout.caller;

                    return (
                      <Card key={callout.id} variant="outlined" sx={{ borderLeft: '4px solid', borderLeftColor: 'error.main' }}>
                        <CardContent>
                          <Box display="flex" justifyContent="space-between" alignItems="center">
                            <Box flex={1}>
                              <Chip 
                                label="Scheduled Rematch" 
                                color="error" 
                                size="small" 
                                sx={{ mb: 1 }}
                              />
                              <Typography variant="h6" sx={{ fontWeight: 'bold', mt: 1 }}>
                                {callout.caller?.name || 'Unknown Fighter'} vs {callout.target?.name || 'Unknown Fighter'}
                              </Typography>
                              <Typography variant="body2" color="text.secondary" mt={1}>
                                {callout.weight_class} • Rematch
                              </Typography>
                              {callout.message && (
                                <Typography variant="body2" sx={{ mt: 1, fontStyle: 'italic' }}>
                                  "{callout.message}"
                                </Typography>
                              )}
                              <Typography variant="body2" color="text.secondary" mt={1}>
                                Scheduled: {callout.scheduled_date ? new Date(callout.scheduled_date).toLocaleString() : 'TBD'}
                              </Typography>
                              <Typography variant="body2" color="text.secondary">
                                Opponent: {opponent?.name || 'Unknown'} • @{opponent?.handle || 'unknown'} • {opponent?.tier || 'Amateur'} • {opponent?.points || 0} pts
                              </Typography>
                            </Box>
                          </Box>
                        </CardContent>
                      </Card>
                    );
                  })}
                </Stack>
              )}
            </CardContent>
          </Card>
        </Box>

        {/* Mandatory Fight Requests (Pending) */}
        <Box sx={{ flex: '1 1 100%', minWidth: '100%', mt: 3 }}>
          <Card>
            <CardContent>
              <Typography variant="h5" sx={{ fontWeight: 'bold', mb: 3 }}>
                Mandatory Fight Requests
              </Typography>
              {pendingFightRequests.length === 0 ? (
                <Alert severity="info">
                  No pending mandatory fight requests at the moment.
                </Alert>
              ) : (
                <Stack spacing={2}>
                  {pendingFightRequests.map((fight) => {
                    // Determine which fighter is the current user and which is the opponent
                    const isFighter1 = fight.fighter1_id === fighterProfile?.user_id;
                    const opponent = isFighter1 ? fight.fighter2 : fight.fighter1;
                    const currentFighter = isFighter1 ? fight.fighter1 : fight.fighter2;
                    const opponentName = opponent?.name || 'TBD';
                    const currentFighterName = currentFighter?.name || fighterProfile?.name || 'You';
                    
                    // Format: Fighter1 vs Fighter2 (opponent first if they requested it)
                    const fightersDisplay = isFighter1 
                      ? `${currentFighterName} vs ${opponentName}`
                      : `${opponentName} vs ${currentFighterName}`;
                    
                    return (
                      <Card key={fight.id} variant="outlined" sx={{ bgcolor: 'warning.light', color: 'warning.contrastText' }}>
                        <CardContent>
                          <Box display="flex" justifyContent="space-between" alignItems="center">
                            <Box flex={1}>
                              <Chip 
                                label="Mandatory Fight Request" 
                                color="warning" 
                                size="small"
                                sx={{ mb: 1 }}
                              />
                              <Typography variant="h6" sx={{ fontWeight: 'bold', mt: 1 }}>
                                {opponentName} has scheduled a mandatory fight with you
                              </Typography>
                              <Typography variant="h6" sx={{ fontWeight: 'bold', mt: 1 }}>
                                {fightersDisplay}
                              </Typography>
                              <Typography variant="body2" color="text.secondary" mt={1}>
                                {new Date(fight.scheduled_date).toLocaleDateString()}
                              </Typography>
                              <Typography variant="body2" color="text.secondary">
                                TBD • {fight.weight_class} • {fight.timezone}
                              </Typography>
                            </Box>
                            <Box display="flex" gap={1} flexDirection="column">
                              <Button
                                variant="contained"
                                color="success"
                                startIcon={acceptingFight === fight.id ? <CircularProgress size={16} /> : <CheckCircle />}
                                onClick={() => handleAcceptFightRequest(fight.id)}
                                disabled={acceptingFight === fight.id || denyingFight === fight.id}
                              >
                                Accept
                              </Button>
                              <Button
                                variant="outlined"
                                color="error"
                                startIcon={denyingFight === fight.id ? <CircularProgress size={16} /> : <CancelIcon />}
                                onClick={() => handleDenyFightRequest(fight.id)}
                                disabled={acceptingFight === fight.id || denyingFight === fight.id}
                              >
                                Deny
                              </Button>
                            </Box>
                          </Box>
                        </CardContent>
                      </Card>
                    );
                  })}
                </Stack>
              )}
            </CardContent>
          </Card>
        </Box>

        {/* Scheduled Fights */}
        <Box sx={{ flex: '1 1 100%', minWidth: '100%', mt: 3 }}>
          <Card>
            <CardContent>
              <Typography variant="h5" sx={{ fontWeight: 'bold', mb: 3 }}>
                Scheduled Fights
              </Typography>
              {scheduledFights.length === 0 ? (
                <Alert severity="info">
                  No scheduled fights at the moment. Check the matchmaking system for opportunities!
                </Alert>
              ) : (
                <Stack spacing={2}>
                  {scheduledFights.map((fight) => {
                    // Determine which fighter is the current user and which is the opponent
                    const isFighter1 = fight.fighter1_id === fighterProfile?.user_id;
                    const opponent = isFighter1 ? fight.fighter2 : fight.fighter1;
                    const opponentName = opponent?.name || 'TBD';
                    const isMandatory = fight.match_type === 'manual' || fight.match_type === 'auto_mandatory';
                    
                    return (
                      <Card key={fight.id} variant="outlined">
                        <CardContent>
                          <Box display="flex" justifyContent="space-between" alignItems="center">
                            <Box flex={1}>
                              {isMandatory ? (
                                <Box mb={1}>
                                  <Chip 
                                    label="Mandatory Fight Request" 
                                    color="warning" 
                                    size="small"
                                    sx={{ mb: 1 }}
                                  />
                                  <Typography variant="body2" color="text.secondary">
                                    {isFighter1 ? fight.fighter2?.name : fight.fighter1?.name} has scheduled a mandatory fight with you
                                  </Typography>
                                </Box>
                              ) : null}
                              <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                                You vs {opponentName}
                              </Typography>
                              <Typography variant="body2" color="text.secondary" mt={1}>
                                {new Date(fight.scheduled_date).toLocaleDateString()} at{' '}
                                {fight.scheduled_time}
                              </Typography>
                              <Typography variant="body2" color="text.secondary">
                                {fight.venue} • {fight.weight_class} • {fight.timezone}
                              </Typography>
                            </Box>
                            <Box display="flex" gap={1} alignItems="center" flexDirection="column">
                              <Chip label={fight.status} color="primary" />
                              {isMandatory && (
                                <Chip 
                                  label="Mandatory" 
                                  color="warning" 
                                  size="small"
                                  sx={{ mt: 1 }}
                                />
                              )}
                            </Box>
                          </Box>
                        </CardContent>
                      </Card>
                    );
                  })}
                </Stack>
              )}
            </CardContent>
          </Card>
        </Box>

        {/* Dispute Resolution */}
        <Box sx={{ flex: '1 1 100%', minWidth: '100%', mt: 3 }}>
          <Card>
            <CardContent>
              <DisputeResolution />
            </CardContent>
          </Card>
        </Box>

        {/* Fight URL Submissions */}
        <Box sx={{ flex: '1 1 100%', minWidth: '100%', mt: 3 }}>
          <Card>
            <CardContent>
              <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
                <Typography variant="h5" sx={{ fontWeight: 'bold' }}>
                  Submit Fight URL
                </Typography>
                <Button
                  variant="contained"
                  startIcon={<LinkIcon />}
                  onClick={() => {
                    setSelectedFightForSubmission(null);
                    setNewSubmission({
                      fight_url: '',
                      event_type: 'Live Event',
                      description: '',
                    });
                    setSubmissionDialogOpen(true);
                  }}
                >
                  Submit URL
                </Button>
              </Box>
              
              <Typography variant="body2" color="text.secondary" mb={3}>
                Submit your fight URL/web link to the Admin for Live events and tournaments. 
                The Admin will review and approve your submission.
              </Typography>

              {fightUrlSubmissions.length === 0 ? (
                <Alert severity="info">
                  No submissions yet. Click "Submit URL" to submit your first fight URL.
                </Alert>
              ) : (
                <Stack spacing={2}>
                  {fightUrlSubmissions.map((submission) => (
                    <Card key={submission.id} variant="outlined">
                      <CardContent>
                        <Box display="flex" justifyContent="space-between" alignItems="start">
                          <Box flex={1}>
                            <Box display="flex" alignItems="center" gap={1} mb={1}>
                              <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                                {submission.event_type}
                              </Typography>
                              <Chip
                                label={submission.status}
                                size="small"
                                color={
                                  submission.status === 'Approved' ? 'success' :
                                  submission.status === 'Rejected' ? 'error' :
                                  submission.status === 'Reviewed' ? 'info' : 'default'
                                }
                              />
                            </Box>
                            <Typography variant="body2" color="text.secondary" mb={1}>
                              <LinkIcon sx={{ verticalAlign: 'middle', fontSize: 16, mr: 0.5 }} />
                              <a 
                                href={submission.fight_url} 
                                target="_blank" 
                                rel="noopener noreferrer"
                                style={{ color: 'inherit', textDecoration: 'underline' }}
                              >
                                {submission.fight_url}
                              </a>
                            </Typography>
                            {submission.description && (
                              <Typography variant="body2" color="text.secondary" mb={1}>
                                {submission.description}
                              </Typography>
                            )}
                            {submission.scheduled_fight && (
                              <Typography variant="body2" color="text.secondary" mb={1}>
                                Scheduled Fight: {submission.scheduled_fight.weight_class} • {new Date(submission.scheduled_fight.scheduled_date).toLocaleDateString()}
                              </Typography>
                            )}
                            {submission.tournament && (
                              <Typography variant="body2" color="text.secondary" mb={1}>
                                Tournament: {submission.tournament.name} • {submission.tournament.weight_class}
                              </Typography>
                            )}
                            {submission.admin_notes && (
                              <Alert severity={submission.status === 'Rejected' ? 'error' : 'info'} sx={{ mt: 1 }}>
                                <Typography variant="body2" fontWeight="bold">Admin Notes:</Typography>
                                <Typography variant="body2">{submission.admin_notes}</Typography>
                              </Alert>
                            )}
                            <Typography variant="caption" color="text.secondary">
                              Submitted: {new Date(submission.submitted_at).toLocaleString()}
                              {submission.reviewed_at && ` • Reviewed: ${new Date(submission.reviewed_at).toLocaleString()}`}
                            </Typography>
                          </Box>
                          {submission.status === 'Pending' && (
                            <IconButton
                              color="error"
                              size="small"
                              onClick={() => handleDeleteSubmissionClick(submission.id)}
                            >
                              <Delete />
                            </IconButton>
                          )}
                        </Box>
                      </CardContent>
                    </Card>
                  ))}
                </Stack>
              )}
            </CardContent>
          </Card>
        </Box>

        {/* My Tournaments */}
        <Box sx={{ flex: '1 1 100%', minWidth: '100%', mt: 3 }}>
          <Card>
            <CardContent>
              <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
                <Typography variant="h5" sx={{ fontWeight: 'bold' }}>
                  My Tournaments
                </Typography>
              </Box>
              
              {myTournaments.length === 0 ? (
                <Alert severity="info">You haven't joined any tournaments yet. Visit the Tournaments page to join!</Alert>
              ) : (
                <Stack spacing={2}>
                  {myTournaments.map((tournament) => (
                    <Card key={tournament.id} variant="outlined">
                      <CardContent>
                        <Box display="flex" justifyContent="space-between" alignItems="start">
                          <Box>
                            <Box display="flex" alignItems="center" gap={1} mb={1}>
                              <Typography variant="h6">{tournament.name}</Typography>
                              <Chip
                                label={tournament.status}
                                size="small"
                                color={
                                  tournament.status === 'Open' ? 'success' :
                                  tournament.status === 'In Progress' ? 'warning' :
                                  tournament.status === 'Completed' ? 'info' : 'default'
                                }
                              />
                              {tournament.winner_id === fighterProfile?.id && (
                                <Chip
                                  label="Champion"
                                  size="small"
                                  color="warning"
                                  icon={<EmojiEvents />}
                                />
                              )}
                            </Box>
                            {tournament.description && (
                              <Typography variant="body2" color="text.secondary" mb={1}>
                                {tournament.description}
                              </Typography>
                            )}
                            <Box display="flex" gap={2} flexWrap="wrap">
                              <Typography variant="body2" color="text.secondary">
                                <CalendarToday sx={{ verticalAlign: 'middle', fontSize: 16, mr: 0.5 }} />
                                Start: {new Date(tournament.start_date).toLocaleDateString()}
                              </Typography>
                              {tournament.registration_deadline && (
                                <Typography variant="body2" color="error">
                                  Deadline: {new Date(tournament.registration_deadline).toLocaleDateString()}
                                </Typography>
                              )}
                            </Box>
                            <Typography variant="body2" color="text.secondary" mt={1}>
                              {tournament.weight_class} • {tournament.format} • Prize Pool: ${tournament.prize_pool}
                            </Typography>
                          </Box>
                          <Button
                            variant="outlined"
                            size="small"
                            startIcon={<SportsMma />}
                            onClick={() => {
                              // Navigate to tournaments page
                              navigate('/tournaments');
                            }}
                          >
                            View Details
                          </Button>
                        </Box>
                      </CardContent>
                    </Card>
                  ))}
                </Stack>
              )}
            </CardContent>
          </Card>
        </Box>
      </Box>

      {/* Add Fight Dialog */}
      <Dialog 
        open={addFightDialogOpen} 
        onClose={loading ? undefined : () => {
          setAddFightDialogOpen(false);
          setFightRecordError(null);
        }}
        disableEscapeKeyDown={loading}
        disableEnforceFocus={loading}
        disableAutoFocus={loading}
        keepMounted={false}
        maxWidth="sm" 
        fullWidth
        aria-labelledby="add-fight-dialog-title"
      >
        <DialogTitle id="add-fight-dialog-title">Add Fight Record</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            {fightRecordError && (
              <Alert severity="error" onClose={() => setFightRecordError(null)}>
                {fightRecordError}
              </Alert>
            )}
            <TextField
              label="Opponent Name"
              fullWidth
              value={newFightRecord.opponent_name}
              onChange={(e) =>
                setNewFightRecord({ ...newFightRecord, opponent_name: e.target.value })
              }
            />
            <TextField
              label="Result"
              select
              fullWidth
              value={newFightRecord.result}
              onChange={(e) =>
                setNewFightRecord({ ...newFightRecord, result: e.target.value as any })
              }
              inputProps={{ 'aria-label': 'Fight Result' }}
            >
              <MenuItem value="win">Win</MenuItem>
              <MenuItem value="loss">Loss</MenuItem>
              <MenuItem value="draw">Draw</MenuItem>
            </TextField>
            <TextField
              label="Method"
              fullWidth
              value={newFightRecord.method}
              onChange={(e) =>
                setNewFightRecord({ ...newFightRecord, method: e.target.value })
              }
              helperText="Examples: KO, TKO, Decision, UD, SD, MD, Submission, DQ, No Contest. Common variations accepted (e.g., 'OK' → 'KO')"
              placeholder="KO, TKO, Decision, etc."
            />
            <TextField
              label="Round"
              type="number"
              fullWidth
              value={newFightRecord.round}
              onChange={(e) =>
                setNewFightRecord({ ...newFightRecord, round: e.target.value })
              }
            />
            <TextField
              label="Date"
              type="date"
              fullWidth
              InputLabelProps={{ shrink: true }}
              value={newFightRecord.date}
              onChange={(e) =>
                setNewFightRecord({ ...newFightRecord, date: e.target.value })
              }
            />
            <TextField
              label="Weight Class"
              fullWidth
              value={newFightRecord.weight_class}
              onChange={(e) =>
                setNewFightRecord({ ...newFightRecord, weight_class: e.target.value })
              }
            />
            {newFightRecord.result === 'win' && (
              <FormControlLabel
                control={
                  <Checkbox
                    checked={newFightRecord.is_tournament_win}
                    onChange={(e) =>
                      setNewFightRecord({ ...newFightRecord, is_tournament_win: e.target.checked })
                    }
                  />
                }
                label="Tournament Win"
              />
            )}
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button 
            onClick={() => {
              setAddFightDialogOpen(false);
              setFightRecordError(null);
            }}
            disabled={loading}
          >
            Cancel
          </Button>
          <Button
            variant="contained"
            onClick={handleAddFightRecord}
            disabled={loading}
            startIcon={loading ? <CircularProgress size={16} /> : <Add />}
          >
            {loading ? 'Adding...' : 'Add Fight'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dispute Submission Dialog */}
      <Dialog 
        open={disputeDialogOpen} 
        onClose={submittingDispute ? undefined : () => setDisputeDialogOpen(false)} 
        maxWidth="md" 
        fullWidth
        disableEscapeKeyDown={submittingDispute}
        disableEnforceFocus={submittingDispute}
        disableAutoFocus={submittingDispute}
        keepMounted={false}
        aria-labelledby="dispute-dialog-title"
      >
        <DialogTitle id="dispute-dialog-title">Submit Dispute</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            {selectedFightForDispute && (
              <Alert severity="info">
                Disputing fight: {selectedFightForDispute.fighter1?.name || 'TBD'} vs{' '}
                {selectedFightForDispute.fighter2?.name || 'TBD'}
              </Alert>
            )}
            <FormControl fullWidth>
              <InputLabel id="dispute-category-label">Dispute Category</InputLabel>
              <Select
                value={newDispute.dispute_category}
                onChange={(e) =>
                  setNewDispute({
                    ...newDispute,
                    dispute_category: e.target.value as any,
                  })
                }
                label="Dispute Category"
                labelId="dispute-category-label"
                aria-labelledby="dispute-category-label"
              >
                <MenuItem value="cheating" aria-label="Cheating">Cheating</MenuItem>
                <MenuItem value="spamming" aria-label="Spamming">Spamming</MenuItem>
                <MenuItem value="exploits" aria-label="Game Exploits">Game Exploits</MenuItem>
                <MenuItem value="excessive_punches" aria-label="Excessive Punches">Excessive Punches</MenuItem>
                <MenuItem value="stamina_draining" aria-label="Stamina Draining Tactics">Stamina Draining Tactics</MenuItem>
                <MenuItem value="power_punches" aria-label="Excessive Power Punches">Excessive Power Punches</MenuItem>
                <MenuItem value="other" aria-label="Other">Other</MenuItem>
              </Select>
            </FormControl>
            <TextField
              fullWidth
              label="Web Link to Fight"
              value={newDispute.fight_link}
              onChange={(e) => setNewDispute({ ...newDispute, fight_link: e.target.value })}
              placeholder="https://..."
              helperText="Provide a link to video or recording of the fight"
            />
            <TextField
              fullWidth
              multiline
              rows={4}
              label="Reason for Dispute"
              value={newDispute.reason}
              onChange={(e) => setNewDispute({ ...newDispute, reason: e.target.value })}
              placeholder="Explain why you're disputing this fight..."
              required
            />
            <Box>
              <Typography variant="body2" mb={1}>
                Evidence URLs (screenshots, videos, etc.)
              </Typography>
              <Box display="flex" gap={1} mb={1}>
                <TextField
                  fullWidth
                  size="small"
                  label="Evidence URL"
                  value={evidenceUrl}
                  onChange={(e) => setEvidenceUrl(e.target.value)}
                  placeholder="https://..."
                />
                <Button
                  variant="outlined"
                  onClick={() => {
                    if (evidenceUrl.trim()) {
                      setNewDispute({
                        ...newDispute,
                        evidence_urls: [...newDispute.evidence_urls, evidenceUrl.trim()],
                      });
                      setEvidenceUrl('');
                    }
                  }}
                >
                  Add
                </Button>
              </Box>
              {newDispute.evidence_urls.map((url, index) => (
                <Box key={index} display="flex" alignItems="center" gap={1} mb={1}>
                  <Typography variant="body2" sx={{ flex: 1, overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {url}
                  </Typography>
                  <Button
                    size="small"
                    color="error"
                    onClick={() => {
                      setNewDispute({
                        ...newDispute,
                        evidence_urls: newDispute.evidence_urls.filter((_, i) => i !== index),
                      });
                    }}
                  >
                    Remove
                  </Button>
                </Box>
              ))}
            </Box>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDisputeDialogOpen(false)}>Cancel</Button>
          <Button
            variant="contained"
            color="error"
            onClick={async () => {
              if (!fighterProfile || !selectedFightForDispute || !newDispute.reason.trim()) {
                return;
              }

              try {
                setSubmittingDispute(true);
                // Get the fighter profile ID (primary key from fighter_profiles table)
                // scheduled_fights.fighter1_id and fighter2_id reference fighter_profiles(id), not user_id
                // We need to get the fighter_profiles.id for the current user
                const { data: profile } = await supabase
                  .from('fighter_profiles')
                  .select('id')
                  .eq('user_id', fighterProfile.user_id)
                  .single();

                if (!profile?.id) {
                  throw new Error('Unable to find fighter profile ID');
                }

                const disputerFighterProfileId = profile.id;

                // Determine opponent - fighter1_id and fighter2_id are already fighter_profiles.id
                let opponentFighterProfileId: string | undefined;
                if (selectedFightForDispute.fighter1_id === disputerFighterProfileId) {
                  opponentFighterProfileId = selectedFightForDispute.fighter2_id;
                } else if (selectedFightForDispute.fighter2_id === disputerFighterProfileId) {
                  opponentFighterProfileId = selectedFightForDispute.fighter1_id;
                }

                // Validate that selectedFightForDispute.id is a valid UUID
                if (!selectedFightForDispute.id || typeof selectedFightForDispute.id !== 'string') {
                  throw new Error('Invalid fight ID: fight ID is missing or invalid');
                }

                // Validate UUID format (basic check)
                const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
                if (!uuidRegex.test(selectedFightForDispute.id)) {
                  console.error('Invalid fight ID format:', selectedFightForDispute.id);
                  console.error('Full fight object:', selectedFightForDispute);
                  throw new Error(`Invalid fight ID format: "${selectedFightForDispute.id}". Expected UUID.`);
                }

                console.log('Creating dispute with:', {
                  scheduled_fight_id: selectedFightForDispute.id,
                  disputerFighterProfileId,
                  opponentFighterProfileId,
                });

                await disputeService.createDispute(
                  {
                    scheduled_fight_id: selectedFightForDispute.id,
                    opponent_id: opponentFighterProfileId || undefined,
                    reason: newDispute.reason,
                    fight_link: newDispute.fight_link || undefined,
                    dispute_category: newDispute.dispute_category,
                    evidence_urls: newDispute.evidence_urls,
                    fighter1_name: selectedFightForDispute.fighter1?.name,
                    fighter2_name: selectedFightForDispute.fighter2?.name,
                  },
                  disputerFighterProfileId
                );
                setDisputeDialogOpen(false);
                setNewDispute({
                  reason: '',
                  fight_link: '',
                  dispute_category: 'other',
                  evidence_urls: [],
                });
                setEvidenceUrl('');
                setSelectedFightForDispute(null);
                alert('Dispute submitted successfully! Admin will review it.');
              } catch (error: any) {
                console.error('Error submitting dispute:', error);
                alert('Failed to submit dispute: ' + (error.message || 'Unknown error'));
              } finally {
                setSubmittingDispute(false);
              }
            }}
            disabled={!newDispute.reason.trim() || submittingDispute}
          >
            {submittingDispute ? 'Submitting...' : 'Submit Dispute'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Fight URL Submission Dialog */}
      <Dialog 
        open={submissionDialogOpen} 
        onClose={submittingUrl ? undefined : () => setSubmissionDialogOpen(false)} 
        maxWidth="md" 
        fullWidth
        disableEscapeKeyDown={submittingUrl}
        disableEnforceFocus={submittingUrl}
        disableAutoFocus={submittingUrl}
        keepMounted={false}
        aria-labelledby="submission-dialog-title"
      >
        <DialogTitle id="submission-dialog-title">Submit Fight URL</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            {selectedFightForSubmission && (
              <Alert severity="info">
                Submitting URL for: {selectedFightForSubmission.fighter1?.name || 'TBD'} vs{' '}
                {selectedFightForSubmission.fighter2?.name || 'TBD'}
              </Alert>
            )}
            <FormControl fullWidth>
              <InputLabel id="event-type-label">Event Type</InputLabel>
              <Select
                value={newSubmission.event_type}
                onChange={(e) =>
                  setNewSubmission({
                    ...newSubmission,
                    event_type: e.target.value as 'Live Event' | 'Tournament',
                  })
                }
                label="Event Type"
                labelId="event-type-label"
              >
                <MenuItem value="Live Event">Live Event</MenuItem>
                <MenuItem value="Tournament">Tournament</MenuItem>
              </Select>
            </FormControl>
            {scheduledFights.length > 0 && (
              <FormControl fullWidth>
                <InputLabel id="fight-select-label">Select Scheduled Fight (Optional)</InputLabel>
                <Select
                  value={selectedFightForSubmission?.id || ''}
                  onChange={(e) => {
                    const fight = scheduledFights.find(f => f.id === e.target.value);
                    setSelectedFightForSubmission(fight || null);
                    setNewSubmission({
                      ...newSubmission,
                      scheduled_fight_id: fight?.id,
                    });
                  }}
                  label="Select Scheduled Fight (Optional)"
                  labelId="fight-select-label"
                  aria-labelledby="fight-select-label"
                >
                  <MenuItem value="">None</MenuItem>
                  {scheduledFights.map((fight) => {
                    const fightText = `${fight.fighter1?.name || 'TBD'} vs ${fight.fighter2?.name || 'TBD'} - ${new Date(fight.scheduled_date).toLocaleDateString()}`;
                    return (
                      <MenuItem 
                        key={fight.id} 
                        value={fight.id} 
                        aria-label={fightText}
                      >
                        {fightText}
                      </MenuItem>
                    );
                  })}
                </Select>
              </FormControl>
            )}
            <TextField
              fullWidth
              label="Fight URL / Web Link"
              value={newSubmission.fight_url}
              onChange={(e) => setNewSubmission({ ...newSubmission, fight_url: e.target.value })}
              placeholder="https://..."
              required
              helperText="Enter the full URL to your fight video or recording"
            />
            <TextField
              fullWidth
              multiline
              rows={3}
              label="Description (Optional)"
              value={newSubmission.description || ''}
              onChange={(e) => setNewSubmission({ ...newSubmission, description: e.target.value })}
              placeholder="Add any additional notes about this fight..."
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSubmissionDialogOpen(false)} disabled={submittingUrl}>
            Cancel
          </Button>
          <Button
            variant="contained"
            onClick={handleSubmitFightUrl}
            disabled={!newSubmission.fight_url.trim() || submittingUrl}
            startIcon={submittingUrl ? <CircularProgress size={16} /> : <LinkIcon />}
          >
            {submittingUrl ? 'Submitting...' : 'Submit URL'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete Submission Confirmation Dialog */}
      <Dialog
        open={deleteSubmissionDialogOpen}
        onClose={() => {
          setDeleteSubmissionDialogOpen(false);
          setSubmissionToDelete(null);
        }}
        aria-labelledby="delete-submission-dialog-title"
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
        keepMounted={false}
      >
        <DialogTitle id="delete-submission-dialog-title">
          Delete Submission
        </DialogTitle>
        <DialogContent>
          <Typography>
            Are you sure you want to delete this submission? This action cannot be undone.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button
            onClick={() => {
              setDeleteSubmissionDialogOpen(false);
              setSubmissionToDelete(null);
            }}
          >
            Cancel
          </Button>
          <Button
            onClick={handleConfirmDeleteSubmission}
            color="error"
            variant="contained"
          >
            Delete
          </Button>
        </DialogActions>
      </Dialog>
      </Box>
    </>
  );
};

export default FighterProfile;
