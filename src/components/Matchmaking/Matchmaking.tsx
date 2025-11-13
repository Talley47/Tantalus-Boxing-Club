import React, { useState, useEffect, useCallback } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  Button,
  Avatar,
  Chip,
  LinearProgress,
  Alert,
  Paper,
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  ListItemSecondaryAction,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Divider,
  Tabs,
  Tab,
  CircularProgress,
} from '@mui/material';
import {
  SportsMma,
  Search,
  FilterList,
  PersonAdd,
  TrendingUp,
  EmojiEvents,
  AutoAwesome,
  FitnessCenter,
  Refresh,
} from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';
import { matchmakingService, MatchmakingCriteria, MatchmakingSuggestion } from '../../services/matchmakingService';
import { schedulingService } from '../../services/schedulingService';
import { useRealtime } from '../../contexts/RealtimeContext';
import { smartMatchmakingService } from '../../services/smartMatchmakingService';
import { trainingCampService } from '../../services/trainingCampService';
import { calloutService } from '../../services/calloutService';
import { supabase } from '../../services/supabase';
// Import Gregg Vs Cholo.png background image
import matchmakingBackground from '../../Gregg Vs Cholo.png';
// Import Logo1.png
import logo1 from '../../Logo1.png';

// Debug log
console.log('Matchmaking background image path:', matchmakingBackground);

// Use the imported MatchmakingSuggestion interface from matchmakingService

// Use the imported MatchmakingCriteria interface from matchmakingService

const Matchmaking: React.FC = () => {
  const { fighterProfile } = useAuth();
  const [suggestions, setSuggestions] = useState<MatchmakingSuggestion[]>([]);
  const [filteredSuggestions, setFilteredSuggestions] = useState<MatchmakingSuggestion[]>([]);
  const [loading, setLoading] = useState(false);
  // Initialize with fighter's actual weight class or default
  const [criteria, setCriteria] = useState<MatchmakingCriteria>(() => ({
    weight_class: fighterProfile?.weight_class || 'Lightweight',
    min_rank: 1,
    max_rank: 5,
    min_points: 0,
    max_points: 2000,
    avoid_recent_opponents: true,
    timezone: fighterProfile?.timezone || 'UTC'
  }));
  const [selectedFighter, setSelectedFighter] = useState<MatchmakingSuggestion | null>(null);
  const [requestDialogOpen, setRequestDialogOpen] = useState(false);
  const [requestMessage, setRequestMessage] = useState('');
  const [autoAssignedOpponent, setAutoAssignedOpponent] = useState<MatchmakingSuggestion | null>(null);
  const [autoAssignedSparring, setAutoAssignedSparring] = useState<MatchmakingSuggestion | null>(null);
  const [autoAssigning, setAutoAssigning] = useState(false);
  const [autoAssigningSparring, setAutoAssigningSparring] = useState(false);
  const [autoMatchingAll, setAutoMatchingAll] = useState(false);
  const [activeTab, setActiveTab] = useState(0); // 0 = Smart Matchmaking, 1 = Training Camp, 2 = Rematches
  const [trainingCampMessage, setTrainingCampMessage] = useState('');
  const [rematchMessage, setRematchMessage] = useState('');
  const [selectedFighterForTrainingCamp, setSelectedFighterForTrainingCamp] = useState<MatchmakingSuggestion | null>(null);
  const [selectedFighterForRematch, setSelectedFighterForRematch] = useState<MatchmakingSuggestion | null>(null);
  const [trainingCampDialogOpen, setTrainingCampDialogOpen] = useState(false);
  const [rematchDialogOpen, setRematchDialogOpen] = useState(false);
  const [sendingTrainingCampInvite, setSendingTrainingCampInvite] = useState(false);
  const [sendingRematch, setSendingRematch] = useState(false);
  const [rematchableFighters, setRematchableFighters] = useState<any[]>([]);
  const [trainingCampEligibility, setTrainingCampEligibility] = useState<{ canStart: boolean; reason?: string } | null>(null);
  const [checkingEligibility, setCheckingEligibility] = useState(false);
  const [weeklyResetDialogOpen, setWeeklyResetDialogOpen] = useState(false);
  const [resettingWeekly, setResettingWeekly] = useState(false);

  const { subscribeToFightRecords, subscribeToFighterProfiles, subscribeToScheduledFights } = useRealtime();

  // Initialize criteria based on fighter's actual rank and points
  useEffect(() => {
    if (fighterProfile) {
      const weightClass = fighterProfile.weight_class || 'Lightweight';
      
      // Update weight class immediately to match fighter's actual weight class
      setCriteria(prev => ({
        ...prev,
        weight_class: weightClass, // Set correct weight class first
      }));

      // Get fighter's rank from weight class rankings
      (async () => {
        try {
          const { getRankingsByWeightClass } = await import('../../services/rankingsService');
          const rankings = await getRankingsByWeightClass(weightClass, 100);
          const fighterRank = rankings.findIndex(r => r.fighter_id === fighterProfile.user_id) + 1;
          
          if (fighterRank > 0) {
            // Set rank window: ±3 ranks from fighter's current rank
            const minRank = Math.max(1, fighterRank - 3);
            const maxRank = fighterRank + 3;
            
            // Set points window: ±30 points (fairness rule: warn if >50)
            const minPoints = Math.max(0, (fighterProfile.points || 0) - 30);
            const maxPoints = (fighterProfile.points || 0) + 30;
            
            setCriteria(prev => ({
              ...prev,
              weight_class: weightClass, // Ensure weight class is set (already set above, but ensure it)
              min_rank: prev.min_rank || minRank,
              max_rank: prev.max_rank || maxRank,
              min_points: prev.min_points !== undefined ? prev.min_points : minPoints,
              max_points: prev.max_points !== undefined ? prev.max_points : maxPoints,
            }));
            
            // Load suggestions after criteria is fully updated
            loadSuggestions();
          } else {
            // Even if no rank found, still load suggestions
            loadSuggestions();
          }
        } catch (error) {
          console.error('Error loading fighter rank for matchmaking defaults:', error);
          // Load suggestions anyway with current criteria
          loadSuggestions();
        }
      })();
    }

    // Subscribe to real-time changes
    const unsubscribeFightRecords = subscribeToFightRecords((payload) => {
      console.log('Fight record changed - reloading matchmaking:', payload);
      // Reload suggestions when fight records change (affects rankings/compatibility)
      if (fighterProfile) {
        loadSuggestions();
      }
    });

    const unsubscribeFighterProfiles = subscribeToFighterProfiles((payload) => {
      console.log('Fighter profile changed - reloading matchmaking:', payload);
      // Reload suggestions when profiles change (affects points, tier, weight_class, etc.)
      // Check if points, tier, or weight_class changed - these affect matchmaking compatibility
      const matchmakingChange = 
        payload.old?.points !== payload.new?.points ||
        payload.old?.tier !== payload.new?.tier ||
        payload.old?.weight_class !== payload.new?.weight_class;
      
      if (matchmakingChange) {
        console.log('Matchmaking-affecting change detected:', {
          points: `${payload.old?.points} → ${payload.new?.points}`,
          tier: `${payload.old?.tier} → ${payload.new?.tier}`,
          weight_class: `${payload.old?.weight_class} → ${payload.new?.weight_class}`
        });
      }
      
      // Reload suggestions if it's the current fighter or if any fighter's compatibility changed
      if (fighterProfile) {
        if (payload.new?.user_id === fighterProfile.user_id) {
          // Current fighter's profile changed - reload to update criteria
          loadSuggestions();
        } else if (matchmakingChange) {
          // Another fighter's profile changed in a way that affects compatibility
          loadSuggestions();
        }
      }
    });

    const unsubscribeScheduledFights = subscribeToScheduledFights((payload) => {
      console.log('Scheduled fight changed:', payload);
      // Fights are being scheduled via Smart Matchmaking - reload to show updated availability
      if (fighterProfile) {
        loadSuggestions();
      }
    });

    return () => {
      unsubscribeFightRecords();
      unsubscribeFighterProfiles();
      unsubscribeScheduledFights();
    };
  }, [fighterProfile]);

  // Load rematchable fighters when rematch tab is active
  useEffect(() => {
    if (activeTab === 2 && fighterProfile) {
      const loadRematchableFighters = async () => {
        try {
          setLoading(true);
          const fighters = await calloutService.getRematchableFighters(fighterProfile.user_id);
          setRematchableFighters(fighters);
        } catch (error) {
          console.error('Error loading rematchable fighters:', error);
          setRematchableFighters([]);
        } finally {
          setLoading(false);
        }
      };
      loadRematchableFighters();
    }
  }, [activeTab, fighterProfile]);

  const loadSuggestions = async () => {
    if (!fighterProfile) return;
    
    try {
      setLoading(true);
      
      const matchmakingCriteria: MatchmakingCriteria = {
        weight_class: criteria.weight_class,
        min_rank: criteria.min_rank,
        max_rank: criteria.max_rank,
        min_points: criteria.min_points,
        max_points: criteria.max_points,
        avoid_recent_opponents: criteria.avoid_recent_opponents,
        timezone: criteria.timezone
      };
      
      const result = await matchmakingService.findMatchmakingSuggestions(
        fighterProfile.user_id, // Use user_id, not id
        matchmakingCriteria
      );
      
      setSuggestions(result.suggestions);
      
      // Filter out scheduled opponents for Training Camp tab
      await filterScheduledOpponents(result.suggestions);
    } catch (error) {
      console.error('Error loading suggestions:', error);
    } finally {
      setLoading(false);
    }
  };

  const filterScheduledOpponents = useCallback(async (suggestionsList: MatchmakingSuggestion[]) => {
    if (!fighterProfile || activeTab !== 1) {
      // Not on Training Camp tab, show all suggestions
      setFilteredSuggestions(suggestionsList);
      return;
    }

    try {
      // Get fighter profile ID
      const { data: fighterProfileData, error: profileError } = await supabase
        .from('fighter_profiles')
        .select('id')
        .eq('user_id', fighterProfile.user_id)
        .single();

      if (profileError || !fighterProfileData) {
        setFilteredSuggestions(suggestionsList);
        return;
      }

      // Get all scheduled opponents
      const { data: scheduledFights, error: fightsError } = await supabase
        .from('scheduled_fights')
        .select('fighter1_id, fighter2_id')
        .or(`fighter1_id.eq.${fighterProfileData.id},fighter2_id.eq.${fighterProfileData.id}`)
        .in('status', ['Scheduled', 'Pending']);

      if (fightsError) {
        console.error('Error fetching scheduled fights:', fightsError);
        setFilteredSuggestions(suggestionsList);
        return;
      }

      // Get opponent profile IDs
      const opponentIds = new Set<string>();
      scheduledFights?.forEach(fight => {
        if (fight.fighter1_id === fighterProfileData.id) {
          opponentIds.add(fight.fighter2_id);
        } else if (fight.fighter2_id === fighterProfileData.id) {
          opponentIds.add(fight.fighter1_id);
        }
      });

      // Get opponent user_ids from profile IDs
      if (opponentIds.size > 0) {
        const { data: opponents, error: opponentsError } = await supabase
          .from('fighter_profiles')
          .select('user_id, name')
          .in('id', Array.from(opponentIds));

        if (!opponentsError && opponents) {
          const opponentUserIds = new Set(opponents.map(o => o.user_id));
          const opponentNames = new Set(opponents.map(o => o.name?.toLowerCase().trim()).filter(Boolean));
          
          // Also get past opponents from fight records (check both user_id and profile ID)
          const { data: fightRecords, error: recordsError } = await supabase
            .from('fight_records')
            .select('opponent_name')
            .or(`fighter_id.eq.${fighterProfile.user_id},fighter_id.eq.${fighterProfileData.id}`)
            .limit(1000);

          if (!recordsError && fightRecords) {
            fightRecords.forEach(record => {
              if (record.opponent_name) {
                opponentNames.add(record.opponent_name.toLowerCase().trim());
              }
            });
          }

          // Filter out scheduled opponents and past opponents
          const filtered = suggestionsList.filter(suggestion => {
            const fighterUserId = suggestion.fighter.user_id || suggestion.fighter.id;
            const fighterName = suggestion.fighter.name?.toLowerCase().trim();
            
            // Exclude if it's a scheduled opponent (by user_id)
            if (opponentUserIds.has(fighterUserId)) {
              return false;
            }
            
            // Exclude if it's a past opponent (by name)
            if (fighterName && opponentNames.has(fighterName)) {
              return false;
            }
            
            return true;
          });
          setFilteredSuggestions(filtered);
          return;
        }
      }

      // Check for past opponents even if no scheduled fights (check both user_id and profile ID)
      const { data: fightRecords, error: recordsError } = await supabase
        .from('fight_records')
        .select('opponent_name')
        .or(`fighter_id.eq.${fighterProfile.user_id},fighter_id.eq.${fighterProfileData.id}`)
        .limit(1000);

      if (!recordsError && fightRecords && fightRecords.length > 0) {
        const opponentNames = new Set(fightRecords.map(record => record.opponent_name?.toLowerCase().trim()).filter(Boolean));
        const filtered = suggestionsList.filter(suggestion => {
          const fighterName = suggestion.fighter.name?.toLowerCase().trim();
          return !fighterName || !opponentNames.has(fighterName);
        });
        setFilteredSuggestions(filtered);
        return;
      }

      // No scheduled opponents, show all suggestions
      setFilteredSuggestions(suggestionsList);
    } catch (error) {
      console.error('Error filtering scheduled opponents:', error);
      setFilteredSuggestions(suggestionsList);
    }
  }, [fighterProfile, activeTab]);

  useEffect(() => {
    // Filter suggestions when tab changes
    if (suggestions.length > 0) {
      filterScheduledOpponents(suggestions);
    }
  }, [activeTab, suggestions, filterScheduledOpponents]);

  const handleRequestFight = (fighter: MatchmakingSuggestion) => {
    setSelectedFighter(fighter);
    setRequestDialogOpen(true);
  };

  const handleSendRequest = async () => {
    if (!selectedFighter || !fighterProfile) return;
    
    // Get fighter profile ID first (needed for both check and scheduling)
    const { data: requesterProfile } = await supabase
      .from('fighter_profiles')
      .select('id')
      .eq('user_id', fighterProfile.user_id)
      .single();

    if (!requesterProfile) {
      alert('Error: Fighter profile not found');
      return;
    }

    // Check if fighter has already sent a mandatory fight request this week
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

    const { data: recentRequests, error: checkError } = await supabase
      .from('scheduled_fights')
      .select('id, created_at')
      .eq('requested_by', requesterProfile.id)
      .eq('match_type', 'manual')
      .in('status', ['Pending', 'Scheduled'])
      .gte('created_at', oneWeekAgo.toISOString())
      .limit(1);

    if (checkError) {
      console.error('Error checking recent requests:', checkError);
    }

    if (recentRequests && recentRequests.length > 0) {
      const lastRequestDate = new Date(recentRequests[0].created_at);
      const daysSinceLastRequest = Math.floor((Date.now() - lastRequestDate.getTime()) / (1000 * 60 * 60 * 24));
      const daysRemaining = 7 - daysSinceLastRequest;
      
      alert(`You can only send one mandatory fight request per week. Your last request was ${daysSinceLastRequest} day(s) ago. Please wait ${daysRemaining} more day(s) before sending another request.`);
      return;
    }

    // Get target profile ID
    const { data: targetProfile } = await supabase
      .from('fighter_profiles')
      .select('id')
      .eq('user_id', selectedFighter.fighter.user_id || selectedFighter.fighter.id)
      .single();

    if (!targetProfile) {
      alert('Error: Target fighter profile not found');
      return;
    }

    // Check if fighters have fought before (before weekly reset)
    // Check for completed fights between these two fighters since the last weekly reset
    const { data: previousFights, error: previousFightsError } = await supabase
      .from('scheduled_fights')
      .select('id, status, created_at')
      .or(`and(fighter1_id.eq.${requesterProfile.id},fighter2_id.eq.${targetProfile.id}),and(fighter1_id.eq.${targetProfile.id},fighter2_id.eq.${requesterProfile.id})`)
      .eq('status', 'Completed')
      .gte('created_at', oneWeekAgo.toISOString())
      .limit(1);

    if (previousFightsError) {
      console.error('Error checking previous fights:', previousFightsError);
    }

    if (previousFights && previousFights.length > 0) {
      alert(`You cannot send a mandatory fight request to ${selectedFighter.fighter.name} because you have already fought them this week. Wait for the weekly reset or use the Callout system for a rematch.`);
      return;
    }
    
    // Fairness rule: Warn if >50 points gap
    const pointsDiff = Math.abs((fighterProfile.points || 0) - (selectedFighter.fighter.points || 0));
    if (pointsDiff > 50) {
      const confirmed = window.confirm(
        `⚠️ Fairness Warning: There is a ${pointsDiff} point gap between you and this opponent. ` +
        `This may result in an unfair matchup. Do you want to proceed with scheduling this fight?`
      );
      if (!confirmed) {
        return;
      }
    }
    
    try {

      // Calculate scheduled date (1 week from now)
      // Use default timezone and platform (columns don't exist in current schema)
      const fighterTimezone = 'UTC';
      const fighterPlatform = 'PC';
      const now = new Date();
      const oneWeekFromNow = new Date(now);
      oneWeekFromNow.setDate(oneWeekFromNow.getDate() + 7);
      // Add some random hours (0-12) for variety in scheduling times
      oneWeekFromNow.setHours(oneWeekFromNow.getHours() + Math.floor(Math.random() * 12));

      // Create the scheduled fight directly with Pending status (needs opponent acceptance)
      const scheduledFight = await schedulingService.scheduleFight({
        fighter1_id: requesterProfile.id, // Use profile ID (primary key)
        fighter2_id: targetProfile.id, // Use profile ID (primary key)
        weight_class: fighterProfile.weight_class || selectedFighter.fighter.weight_class || 'Lightweight',
        scheduled_date: oneWeekFromNow.toISOString(),
        timezone: fighterTimezone,
        platform: fighterPlatform,
        connection_notes: requestMessage || `Mandatory fight scheduled by ${fighterProfile.name}. Must be completed within 1 week.`,
        house_rules: 'Standard boxing rules apply. Fight must be completed within 7 days of scheduling.',
        status: 'Pending' // Set to Pending so opponent can accept/deny
      });

      // Mark as manual mandatory fight and set requested_by
      await supabase
        .from('scheduled_fights')
        .update({
          match_type: 'manual',
          match_score: selectedFighter.compatibility_score,
          requested_by: requesterProfile.id
        })
        .eq('id', scheduledFight.id);
      
      setRequestDialogOpen(false);
      setRequestMessage('');
      setSelectedFighter(null);
      
      // Reload suggestions to update availability
      loadSuggestions();
      
      alert('Fight scheduled successfully! Your opponent has been notified and the fight will appear in both of your Scheduled Fights sections.');
    } catch (error: any) {
      console.error('Error scheduling fight:', error);
      alert('Failed to schedule fight: ' + (error.message || 'Unknown error'));
    }
  };

  const handleAutoAssignOpponent = async () => {
    if (!fighterProfile) return;
    
    try {
      setAutoAssigning(true);
      const assigned = await matchmakingService.autoAssignOpponent(fighterProfile.user_id);
      
      if (assigned) {
        setAutoAssignedOpponent(assigned);
        setSelectedFighter(assigned);
        setRequestDialogOpen(true);
      } else {
        alert('No suitable opponent found. Try adjusting your criteria or check back later.');
      }
    } catch (error) {
      console.error('Error auto-assigning opponent:', error);
      alert('Failed to auto-assign opponent. Please try again.');
    } finally {
      setAutoAssigning(false);
    }
  };

  const handleAutoAssignSparring = async () => {
    if (!fighterProfile) return;
    
    try {
      setAutoAssigningSparring(true);
      const assigned = await matchmakingService.autoAssignSparringPartner(fighterProfile.user_id);
      
      if (assigned) {
        setAutoAssignedSparring(assigned);
        setSelectedFighter(assigned);
        setRequestDialogOpen(true);
      } else {
        alert('No suitable sparring partner found. Try adjusting your criteria or check back later.');
      }
    } catch (error) {
      console.error('Error auto-assigning sparring partner:', error);
      alert('Failed to auto-assign sparring partner. Please try again.');
    } finally {
      setAutoAssigningSparring(false);
    }
  };

  const getCompatibilityColor = (score: number) => {
    if (score >= 80) return 'success';
    if (score >= 60) return 'warning';
    return 'error';
  };

  const getCompatibilityText = (score: number) => {
    if (score >= 80) return 'Excellent Match';
    if (score >= 60) return 'Good Match';
    return 'Fair Match';
  };

  if (!fighterProfile) {
    return (
      <Alert severity="error">
        Please complete your fighter profile to access matchmaking.
      </Alert>
    );
  }

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
          backgroundImage: matchmakingBackground ? `url("${matchmakingBackground}")` : 'url("/Gregg Vs Cholo.png")',
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          backgroundRepeat: 'no-repeat',
          backgroundAttachment: 'fixed',
          zIndex: -1,
          display: 'block',
          backgroundColor: 'transparent',
          '&::after': {
            content: '""',
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.3)',
            zIndex: 1,
            pointerEvents: 'none',
          },
        }}
      />
      {/* Content layer */}
      <Box 
        sx={{ 
          position: 'relative',
          zIndex: 1,
          m: -3,
          px: 3,
          py: 4,
          minHeight: '100vh',
        }}
      >
      <Box display="flex" alignItems="center" gap={2} mb={2}>
        <Box
          component="img"
          src={logo1}
          alt="Tantalus Boxing League Logo"
          sx={{
            height: { xs: 50, md: 70 },
            width: 'auto',
            objectFit: 'contain',
          }}
        />
        <Typography variant="h4" gutterBottom sx={{ color: 'white', fontWeight: 'bold', mb: 0 }}>
          Matchmaking
        </Typography>
      </Box>
      <Typography variant="body1" paragraph sx={{ color: 'rgba(255, 255, 255, 0.9)' }}>
        Find your next opponent or sparring partner with our intelligent matching system.
      </Typography>

      {/* Tabs for Smart Matchmaking and Training Camp */}
      <Tabs 
        value={activeTab} 
        onChange={(e, newValue) => setActiveTab(newValue)} 
        sx={{ 
          mb: 3,
          '& .MuiTab-root': {
            color: 'white',
            fontWeight: 'bold',
            backgroundColor: 'rgba(0, 0, 0, 0.5)',
            borderRadius: '8px 8px 0 0',
            marginRight: 1,
            '&:hover': {
              backgroundColor: 'rgba(0, 0, 0, 0.7)',
            },
            '&.Mui-selected': {
              color: 'white',
              backgroundColor: 'rgba(211, 47, 47, 0.9)', // Primary red with opacity
            },
          },
          '& .MuiTabs-indicator': {
            backgroundColor: 'white',
            height: 3,
          },
        }}
      >
        <Tab label="Smart Matchmaking" icon={<SportsMma />} iconPosition="start" />
        <Tab label="Training Camp" icon={<FitnessCenter />} iconPosition="start" />
        <Tab label="Rematches" icon={<EmojiEvents />} iconPosition="start" />
      </Tabs>

      {/* Smart Matchmaking Tab */}
      {activeTab === 0 && (
        <>
          <Typography variant="h5" gutterBottom sx={{ mb: 2, color: 'white', fontWeight: 'bold' }}>
            Smart Matchmaking
          </Typography>
          <Typography variant="body2" paragraph sx={{ mb: 3, color: 'rgba(255, 255, 255, 0.9)' }}>
            Automatically find fair opponents based on Rankings, Weight Class, and Tier System. Mandatory fights will appear in your My Profile section.
          </Typography>

          {/* HIDDEN: Auto-Match All Fighters Button (Admin/System) */}
          {/* <Card sx={{ mb: 3, bgcolor: 'warning.dark', color: 'warning.contrastText' }}>
            <CardContent>
              <Box display="flex" justifyContent="space-between" alignItems="center" flexWrap="wrap" gap={2}>
                <Box flex={1}>
                  <Typography variant="h6" gutterBottom>
                    Automatic Smart Matchmaking
                  </Typography>
                  <Typography variant="body2" paragraph>
                    The system will automatically match all fighters based on rankings, weight class, tier, and points. 
                    Matched fighters will receive mandatory fights in their My Profile section. Fights must be completed within 1 week.
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    <strong>Weekly Reset:</strong> Old mandatory fights (older than 1 week) will be cancelled and new matches will be created.
                  </Typography>
                </Box>
                <Box display="flex" flexDirection="column" gap={1}>
                  <Button
                    variant="contained"
                    color="secondary"
                    size="large"
                    startIcon={autoMatchingAll ? <CircularProgress size={20} /> : <AutoAwesome />}
                    onClick={async () => {
                      if (!fighterProfile) return;
                      try {
                        setAutoMatchingAll(true);
                        const matches = await smartMatchmakingService.autoMatchFighters();
                        alert(`Successfully created ${matches.length} automatic matches! Check your My Profile for mandatory fights.`);
                      } catch (error: any) {
                        console.error('Error auto-matching fighters:', error);
                        alert('Failed to auto-match fighters: ' + (error.message || 'Unknown error'));
                      } finally {
                        setAutoMatchingAll(false);
                      }
                    }}
                    disabled={autoMatchingAll}
                  >
                    {autoMatchingAll ? 'Matching Fighters...' : 'Run Auto-Matchmaking'}
                  </Button>
                  <Button
                    variant="outlined"
                    color="secondary"
                    size="medium"
                    startIcon={resettingWeekly ? <CircularProgress size={16} /> : <Refresh />}
                    onClick={() => setWeeklyResetDialogOpen(true)}
                    disabled={autoMatchingAll || resettingWeekly}
                  >
                    Weekly Reset
                  </Button>
                </Box>
              </Box>
            </CardContent>
          </Card> */}

          {/* HIDDEN: Auto-Assign Button */}
          {/* <Card sx={{ mb: 3, bgcolor: 'primary.light', color: 'primary.contrastText' }}>
            <CardContent>
              <Box display="flex" justifyContent="space-between" alignItems="center">
                <Box>
                  <Typography variant="h6" gutterBottom>
                    Auto-Assign Opponent
                  </Typography>
                  <Typography variant="body2">
                    Let our system automatically find the best match for you based on your rank, tier, and weight class.
                  </Typography>
                </Box>
                <Button
                  variant="contained"
                  color="secondary"
                  size="large"
                  startIcon={autoAssigning ? <CircularProgress size={20} /> : <AutoAwesome />}
                  onClick={handleAutoAssignOpponent}
                  disabled={autoAssigning}
                >
                  {autoAssigning ? 'Finding Match...' : 'Auto-Assign Opponent'}
                </Button>
              </Box>
            </CardContent>
          </Card> */}

          {/* HIDDEN: Show Auto-Assigned Opponent */}
          {/* {autoAssignedOpponent && (
            <Card sx={{ mb: 3 }}>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Mandatory Opponent
                </Typography>
                <Box display="flex" alignItems="center" gap={2} mb={2}>
                  <Avatar src={autoAssignedOpponent.fighter.profile_photo_url} sx={{ width: 64, height: 64 }}>
                    {autoAssignedOpponent.fighter.name.charAt(0)}
                  </Avatar>
                  <Box>
                    <Typography variant="h6">
                      {autoAssignedOpponent.fighter.name}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      @{autoAssignedOpponent.fighter.handle}
                    </Typography>
                    <Box display="flex" gap={1} mt={1}>
                      <Chip label={autoAssignedOpponent.fighter.tier} size="small" color="primary" />
                      <Chip 
                        label={`${autoAssignedOpponent.compatibility_score}% Match`}
                        size="small"
                        color={getCompatibilityColor(autoAssignedOpponent.compatibility_score)}
                      />
                    </Box>
                  </Box>
                </Box>
                <Typography variant="body2" color="text.secondary">
                  {autoAssignedOpponent.fighter.weight_class} • {autoAssignedOpponent.fighter.points} points • 
                  Record: {autoAssignedOpponent.fighter.wins}-{autoAssignedOpponent.fighter.losses}-{autoAssignedOpponent.fighter.draws}
                </Typography>
                {autoAssignedOpponent.reasons.length > 0 && (
                  <Box mt={2}>
                    <Typography variant="caption" color="text.secondary">
                      Match Reasons: {autoAssignedOpponent.reasons.join(', ')}
                    </Typography>
                  </Box>
                )}
              </CardContent>
            </Card>
          )} */}

      {/* HIDDEN: Matchmaking Criteria */}
      {/* <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Matchmaking Criteria
          </Typography>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr', md: '1fr 1fr 1fr 1fr' }, gap: 2 }}>
            <FormControl fullWidth>
              <InputLabel>Weight Class</InputLabel>
              <Select
                value={criteria.weight_class}
                onChange={(e) => setCriteria({ ...criteria, weight_class: e.target.value })}
              >
                <MenuItem value="Flyweight">Flyweight</MenuItem>
                <MenuItem value="Bantamweight">Bantamweight</MenuItem>
                <MenuItem value="Featherweight">Featherweight</MenuItem>
                <MenuItem value="Lightweight">Lightweight</MenuItem>
                <MenuItem value="Welterweight">Welterweight</MenuItem>
                <MenuItem value="Middleweight">Middleweight</MenuItem>
                <MenuItem value="Light Heavyweight">Light Heavyweight</MenuItem>
                <MenuItem value="Heavyweight">Heavyweight</MenuItem>
              </Select>
            </FormControl>
            <FormControl fullWidth>
              <InputLabel>Rank Range</InputLabel>
              <Select
                value={`${criteria.min_rank}-${criteria.max_rank}`}
                onChange={(e) => {
                  const [min, max] = e.target.value.split('-').map(Number);
                  setCriteria({ ...criteria, min_rank: min, max_rank: max });
                }}
              >
                <MenuItem value="1-3">Rank 1-3</MenuItem>
                <MenuItem value="2-4">Rank 2-4</MenuItem>
                <MenuItem value="3-5">Rank 3-5</MenuItem>
                <MenuItem value="1-5">All Ranks</MenuItem>
              </Select>
            </FormControl>
            <TextField
              fullWidth
              label="Min Points"
              type="number"
              value={criteria.min_points}
              onChange={(e) => setCriteria({ 
                ...criteria, 
                min_points: Number(e.target.value)
              })}
            />
            <TextField
              fullWidth
              label="Max Points"
              type="number"
              value={criteria.max_points}
              onChange={(e) => setCriteria({ 
                ...criteria, 
                max_points: Number(e.target.value)
              })}
            />
          </Box>
        </CardContent>
      </Card> */}

      {/* Matchmaking Suggestions */}
      <Card>
        <CardContent>
          <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
            <Typography variant="h6">
              Mandatory Opponents ({suggestions.length})
            </Typography>
            <Button
              variant="outlined"
              startIcon={<Search />}
              onClick={loadSuggestions}
              disabled={loading}
            >
              Refresh
            </Button>
          </Box>

          {loading ? (
            <LinearProgress />
          ) : suggestions.length === 0 ? (
            <Alert severity="info">
              No suitable opponents found. Try adjusting your criteria.
            </Alert>
          ) : (
            <List>
              {suggestions.map((suggestion) => (
                <React.Fragment key={suggestion.fighter.id}>
                  <ListItem>
                    <ListItemAvatar>
                      <Avatar src={suggestion.fighter.profile_photo_url}>
                        {suggestion.fighter.name.charAt(0)}
                      </Avatar>
                    </ListItemAvatar>
                    <ListItemText
                      primary={
                        <Box display="flex" alignItems="center" gap={1}>
                          <Typography variant="subtitle1" fontWeight="bold">
                            {suggestion.fighter.name}
                          </Typography>
                          <Chip 
                            label={suggestion.fighter.tier} 
                            size="small" 
                            color="primary" 
                          />
                          <Chip 
                            label={`${suggestion.compatibility_score}%`}
                            size="small"
                            color={getCompatibilityColor(suggestion.compatibility_score)}
                          />
                        </Box>
                      }
                      secondary={
                        <>
                          <Typography variant="body2" color="text.secondary" component="span" display="block">
                            {suggestion.fighter.weight_class} • {suggestion.fighter.points} points • {suggestion.fighter.wins}-{suggestion.fighter.losses}-{suggestion.fighter.draws}
                          </Typography>
                          <Typography variant="caption" color="text.secondary" component="span" display="block">
                            {getCompatibilityText(suggestion.compatibility_score)}
                            {suggestion.last_fought && ` • Last fought: ${new Date(suggestion.last_fought).toLocaleDateString()}`}
                          </Typography>
                        </>
                      }
                    />
                    <ListItemSecondaryAction>
                      <Button
                        variant="contained"
                        startIcon={<SportsMma />}
                        onClick={() => handleRequestFight(suggestion)}
                      >
                        Schedule Fight
                      </Button>
                    </ListItemSecondaryAction>
                  </ListItem>
                  <Divider />
                </React.Fragment>
              ))}
            </List>
          )}
        </CardContent>
      </Card>
        </>
      )}

      {/* Fight Request Dialog */}
      <Dialog 
        open={requestDialogOpen} 
        onClose={() => setRequestDialogOpen(false)} 
        maxWidth="sm" 
        fullWidth
        aria-labelledby="fight-request-dialog-title"
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
        keepMounted={false}
      >
        <DialogTitle id="fight-request-dialog-title">
          Schedule Fight with {selectedFighter?.fighter.name}
        </DialogTitle>
        <DialogContent>
          <Box mb={2}>
            <Typography variant="body2" color="text.secondary">
              Compatibility Score: {selectedFighter?.compatibility_score}%
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Record: {selectedFighter?.fighter.wins}-{selectedFighter?.fighter.losses}-{selectedFighter?.fighter.draws} • Points: {selectedFighter?.fighter.points}
            </Typography>
          </Box>
          <TextField
            fullWidth
            multiline
            rows={4}
            label="Message (Optional)"
            placeholder="Add a personal message to your fight request..."
            value={requestMessage}
            onChange={(e) => setRequestMessage(e.target.value)}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setRequestDialogOpen(false)}>
            Cancel
          </Button>
          <Button 
            onClick={handleSendRequest} 
            variant="contained"
            startIcon={<SportsMma />}
          >
            Send Request
          </Button>
        </DialogActions>
      </Dialog>

      {/* Training Camp Tab */}
      {activeTab === 1 && (
        <>
          <Typography variant="h5" gutterBottom sx={{ mb: 2, color: 'white', fontWeight: 'bold' }}>
            Training Camp Invitations
          </Typography>
          <Typography variant="body2" paragraph sx={{ mb: 3, color: 'rgba(255, 255, 255, 0.9)' }}>
            Send training camp invitations to other fighters. Training camps last 72 hours. You cannot start a training camp within 3 days of a scheduled fight.
          </Typography>

          {/* Manual Search for Training Camp Partners */}
          <Card sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Find Fighters to Invite to Training Camp
              </Typography>
              <Typography variant="body2" color="text.secondary" paragraph>
                Use the criteria below to search for fighters to invite to training camp.
              </Typography>
              
              <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr', md: '1fr 1fr 1fr 1fr' }, gap: 2, mt: 2 }}>
                <FormControl fullWidth>
                  <InputLabel>Weight Class</InputLabel>
                  <Select
                    value={criteria.weight_class}
                    onChange={(e) => setCriteria({ ...criteria, weight_class: e.target.value })}
                  >
                    <MenuItem value="Flyweight">Flyweight</MenuItem>
                    <MenuItem value="Bantamweight">Bantamweight</MenuItem>
                    <MenuItem value="Featherweight">Featherweight</MenuItem>
                    <MenuItem value="Lightweight">Lightweight</MenuItem>
                    <MenuItem value="Welterweight">Welterweight</MenuItem>
                    <MenuItem value="Middleweight">Middleweight</MenuItem>
                    <MenuItem value="Light Heavyweight">Light Heavyweight</MenuItem>
                    <MenuItem value="Heavyweight">Heavyweight</MenuItem>
                  </Select>
                </FormControl>
                <FormControl fullWidth>
                  <InputLabel>Rank Range</InputLabel>
                  <Select
                    value={`${criteria.min_rank}-${criteria.max_rank}`}
                    onChange={(e) => {
                      const [min, max] = e.target.value.split('-').map(Number);
                      setCriteria({ ...criteria, min_rank: min, max_rank: max });
                    }}
                  >
                    <MenuItem value="1-5">Rank 1-5</MenuItem>
                    <MenuItem value="1-10">Rank 1-10</MenuItem>
                    <MenuItem value="1-20">Rank 1-20</MenuItem>
                    <MenuItem value="1-50">Rank 1-50</MenuItem>
                  </Select>
                </FormControl>
                <TextField
                  fullWidth
                  label="Min Points"
                  type="number"
                  value={criteria.min_points}
                  onChange={(e) => setCriteria({ 
                    ...criteria, 
                    min_points: Number(e.target.value)
                  })}
                />
                <TextField
                  fullWidth
                  label="Max Points"
                  type="number"
                  value={criteria.max_points}
                  onChange={(e) => setCriteria({ 
                    ...criteria, 
                    max_points: Number(e.target.value)
                  })}
                />
              </Box>
              <Button
                variant="outlined"
                startIcon={<Search />}
                onClick={loadSuggestions}
                disabled={loading}
                sx={{ mt: 2 }}
              >
                Search for Fighters
              </Button>
              
              {/* Show suggestions with invite buttons */}
              {(activeTab === 1 ? filteredSuggestions : suggestions).length > 0 && (
                <Box sx={{ mt: 3 }}>
                  <Typography variant="h6" gutterBottom>
                    Suggested Fighters
                    {activeTab === 1 && filteredSuggestions.length < suggestions.length && (
                      <Typography variant="caption" color="text.secondary" sx={{ ml: 1 }}>
                        ({suggestions.length - filteredSuggestions.length} scheduled opponents hidden)
                      </Typography>
                    )}
                  </Typography>
                  <List>
                    {(activeTab === 1 ? filteredSuggestions : suggestions).map((suggestion) => (
                      <React.Fragment key={suggestion.fighter.id}>
                        <ListItem>
                          <ListItemAvatar>
                            <Avatar src={suggestion.fighter.profile_photo_url}>
                              {suggestion.fighter.name.charAt(0)}
                            </Avatar>
                          </ListItemAvatar>
                          <ListItemText
                            primary={suggestion.fighter.name}
                            secondary={`${suggestion.fighter.weight_class} • ${suggestion.fighter.points} points • ${suggestion.compatibility_score}% match`}
                          />
                          <ListItemSecondaryAction>
                            <Button
                              variant="contained"
                              startIcon={<FitnessCenter />}
                              onClick={async () => {
                                if (!fighterProfile) return;
                                setSelectedFighterForTrainingCamp(suggestion);
                                setTrainingCampMessage('');
                                setCheckingEligibility(true);
                                try {
                                  const eligibility = await trainingCampService.canStartTrainingCamp(fighterProfile.user_id);
                                  setTrainingCampEligibility(eligibility);
                                } catch (error) {
                                  console.error('Error checking eligibility:', error);
                                  setTrainingCampEligibility({ canStart: false, reason: 'Error checking eligibility' });
                                } finally {
                                  setCheckingEligibility(false);
                                  setTrainingCampDialogOpen(true);
                                }
                              }}
                            >
                              Invite to Training Camp
                            </Button>
                          </ListItemSecondaryAction>
                        </ListItem>
                        <Divider />
                      </React.Fragment>
                    ))}
                  </List>
                </Box>
              )}
            </CardContent>
          </Card>

          {/* HIDDEN: Auto-Assign Sparring Partner Button */}
          {/* <Card sx={{ mb: 3, bgcolor: 'success.light', color: 'success.contrastText' }}>
            <CardContent>
              <Box display="flex" justifyContent="space-between" alignItems="center">
                <Box>
                  <Typography variant="h6" gutterBottom>
                    Auto-Assign Sparring Partner
                  </Typography>
                  <Typography variant="body2">
                    Automatically find a sparring partner with similar skill level for practice sessions.
                  </Typography>
                </Box>
                <Button
                  variant="contained"
                  color="secondary"
                  size="large"
                  startIcon={autoAssigningSparring ? <CircularProgress size={20} /> : <AutoAwesome />}
                  onClick={handleAutoAssignSparring}
                  disabled={autoAssigningSparring}
                >
                  {autoAssigningSparring ? 'Finding Partner...' : 'Auto-Assign Sparring Partner'}
                </Button>
              </Box>
            </CardContent>
          </Card> */}

          {/* HIDDEN: Show Auto-Assigned Sparring Partner */}
          {/* {autoAssignedSparring && (
            <Card sx={{ mb: 3 }}>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Suggested Sparring Partner
                </Typography>
                <Box display="flex" alignItems="center" gap={2} mb={2}>
                  <Avatar src={autoAssignedSparring.fighter.profile_photo_url} sx={{ width: 64, height: 64 }}>
                    {autoAssignedSparring.fighter.name.charAt(0)}
                  </Avatar>
                  <Box>
                    <Typography variant="h6">
                      {autoAssignedSparring.fighter.name}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      @{autoAssignedSparring.fighter.handle}
                    </Typography>
                    <Box display="flex" gap={1} mt={1}>
                      <Chip label={autoAssignedSparring.fighter.tier} size="small" color="primary" />
                      <Chip 
                        label={`${autoAssignedSparring.compatibility_score}% Match`}
                        size="small"
                        color={getCompatibilityColor(autoAssignedSparring.compatibility_score)}
                      />
                    </Box>
                  </Box>
                </Box>
                <Typography variant="body2" color="text.secondary">
                  {autoAssignedSparring.fighter.weight_class} • {autoAssignedSparring.fighter.points} points • 
                  Record: {autoAssignedSparring.fighter.wins}-{autoAssignedSparring.fighter.losses}-{autoAssignedSparring.fighter.draws}
                </Typography>
                {autoAssignedSparring.reasons.length > 0 && (
                  <Box mt={2}>
                    <Typography variant="caption" color="text.secondary">
                      Match Reasons: {autoAssignedSparring.reasons.join(', ')}
                    </Typography>
                  </Box>
                )}
                <Button
                  variant="contained"
                  startIcon={<FitnessCenter />}
                  onClick={async () => {
                    if (!fighterProfile) return;
                    setSelectedFighterForTrainingCamp(autoAssignedSparring);
                    setTrainingCampMessage('');
                    setCheckingEligibility(true);
                    try {
                      const eligibility = await trainingCampService.canStartTrainingCamp(fighterProfile.user_id);
                      setTrainingCampEligibility(eligibility);
                    } catch (error) {
                      console.error('Error checking eligibility:', error);
                      setTrainingCampEligibility({ canStart: false, reason: 'Error checking eligibility' });
                    } finally {
                      setCheckingEligibility(false);
                      setTrainingCampDialogOpen(true);
                    }
                  }}
                  sx={{ mt: 2 }}
                >
                  Send Training Camp Invitation
                </Button>
              </CardContent>
            </Card>
          )} */}

        </>
      )}

      {/* Rematch Tab */}
      {activeTab === 2 && (
        <>
          <Typography variant="h5" gutterBottom sx={{ mb: 2, color: 'white', fontWeight: 'bold' }}>
            Rematch System
          </Typography>
          <Alert severity="info" sx={{ mb: 3 }}>
            <Typography variant="body2" component="div">
              <strong>Rematch Requirements:</strong>
              <ul style={{ margin: '8px 0', paddingLeft: '20px' }}>
                <li>Must have fought this fighter before</li>
                <li>Same weight class and tier</li>
                <li>Rank difference: ≤ 5 ranks</li>
                <li>Points difference: ≤ 30 points</li>
              </ul>
              Only fighters meeting all requirements are shown below.
            </Typography>
          </Alert>

          {/* Show rematchable fighters */}
          {loading ? (
            <Box display="flex" justifyContent="center" alignItems="center" minHeight={200}>
              <CircularProgress />
            </Box>
          ) : rematchableFighters.length === 0 ? (
            <Card>
              <CardContent>
                <Alert severity="info">
                  You don't have any fighters available for rematch. Rematches are only available with fighters you have already fought. 
                  Check your fight records on your My Profile page to see your past opponents.
                </Alert>
              </CardContent>
            </Card>
          ) : (
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Available Fighters for Rematch ({rematchableFighters.length})
                </Typography>
                <List>
                  {rematchableFighters.map((fighter) => (
                    <React.Fragment key={fighter.id}>
                      <ListItem>
                        <ListItemAvatar>
                          <Avatar src={fighter.profile_photo_url}>
                            {fighter.name.charAt(0)}
                          </Avatar>
                        </ListItemAvatar>
                        <ListItemText
                          primary={
                            <Box display="flex" alignItems="center" gap={1}>
                              <Typography variant="subtitle1" fontWeight="bold">
                                {fighter.name}
                              </Typography>
                              <Chip label={fighter.tier} size="small" color="primary" />
                              {fighter.rank && (
                                <Chip label={`Rank #${fighter.rank}`} size="small" />
                              )}
                            </Box>
                          }
                          secondary={
                            <>
                              <Typography variant="body2" color="text.secondary" component="span" display="block">
                                {fighter.weight_class} • {fighter.points} points
                                {fighter.rank_difference !== null && ` • Rank Diff: ${fighter.rank_difference}`}
                                {fighter.points_difference !== null && ` • Points Diff: ${fighter.points_difference}`}
                              </Typography>
                              <Typography variant="caption" color="text.secondary" component="span" display="block">
                                You have fought this fighter before - Rematch available
                              </Typography>
                            </>
                          }
                        />
                        <ListItemSecondaryAction>
                          <Button
                            variant="contained"
                            color="error"
                            startIcon={<EmojiEvents />}
                            onClick={() => {
                              setSelectedFighterForRematch({
                                fighter: {
                                  ...fighter,
                                  id: fighter.user_id || fighter.id,
                                  user_id: fighter.user_id || fighter.id
                                },
                                compatibility_score: 100
                              } as MatchmakingSuggestion);
                              setRematchMessage('');
                              setRematchDialogOpen(true);
                            }}
                          >
                            Request Rematch
                          </Button>
                        </ListItemSecondaryAction>
                      </ListItem>
                      <Divider />
                    </React.Fragment>
                  ))}
                </List>
              </CardContent>
            </Card>
          )}
        </>
      )}

      {/* Training Camp Invitation Dialog */}
      <Dialog 
        open={trainingCampDialogOpen} 
        onClose={() => {
          setTrainingCampDialogOpen(false);
          setTrainingCampEligibility(null);
          setTrainingCampMessage('');
        }} 
        maxWidth="sm" 
        fullWidth
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
        keepMounted={false}
      >
        <DialogTitle>
          Send Training Camp Invitation to {selectedFighterForTrainingCamp?.fighter.name}
        </DialogTitle>
        <DialogContent>
          {checkingEligibility ? (
            <Box display="flex" alignItems="center" gap={2} sx={{ mb: 2 }}>
              <CircularProgress size={20} />
              <Typography>Checking eligibility...</Typography>
            </Box>
          ) : trainingCampEligibility && !trainingCampEligibility.canStart ? (
            <Alert severity="error" sx={{ mb: 2 }}>
              {trainingCampEligibility.reason || 'Cannot start training camp at this time.'}
            </Alert>
          ) : (
            <Alert severity="info" sx={{ mb: 2 }}>
              Training camps last 72 hours. You cannot start a training camp within 3 days of a scheduled fight.
            </Alert>
          )}
          <TextField
            fullWidth
            multiline
            rows={4}
            label="Message (Optional)"
            placeholder="Add a personal message to your invitation..."
            value={trainingCampMessage}
            onChange={(e) => setTrainingCampMessage(e.target.value)}
            disabled={!trainingCampEligibility?.canStart}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setTrainingCampDialogOpen(false)}>
            Cancel
          </Button>
          <Button 
            onClick={async () => {
              if (!selectedFighterForTrainingCamp || !fighterProfile) return;
              try {
                setSendingTrainingCampInvite(true);
                await trainingCampService.createInvitation(fighterProfile.user_id, {
                  invitee_user_id: selectedFighterForTrainingCamp.fighter.user_id || selectedFighterForTrainingCamp.fighter.id,
                  message: trainingCampMessage || undefined
                });
                setTrainingCampDialogOpen(false);
                setTrainingCampMessage('');
                setSelectedFighterForTrainingCamp(null);
                alert('Training camp invitation sent successfully!');
              } catch (error: any) {
                console.error('Error sending training camp invitation:', error);
                alert('Failed to send invitation: ' + (error.message || 'Unknown error'));
              } finally {
                setSendingTrainingCampInvite(false);
              }
            }}
            variant="contained"
            startIcon={sendingTrainingCampInvite ? <CircularProgress size={16} /> : <FitnessCenter />}
            disabled={sendingTrainingCampInvite || !trainingCampEligibility?.canStart || checkingEligibility}
          >
            {sendingTrainingCampInvite ? 'Sending...' : 'Send Invitation'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Rematch Dialog */}
      <Dialog 
        open={rematchDialogOpen} 
        onClose={() => setRematchDialogOpen(false)} 
        maxWidth="sm" 
        fullWidth
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
        keepMounted={false}
      >
        <DialogTitle>
          Request Rematch with {selectedFighterForRematch?.fighter.name}
        </DialogTitle>
        <DialogContent>
          <Alert severity="info" sx={{ mb: 2 }}>
            Rematches are only available with fighters you have already fought. The system will validate that this is a fair matchup based on rankings, weight class, tier, and points.
          </Alert>
          <TextField
            fullWidth
            multiline
            rows={4}
            label="Message (Optional)"
            placeholder="Add a message to your rematch request..."
            value={rematchMessage}
            onChange={(e) => setRematchMessage(e.target.value)}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setRematchDialogOpen(false)}>
            Cancel
          </Button>
          <Button 
            onClick={async () => {
              if (!selectedFighterForRematch || !fighterProfile) return;
              try {
                setSendingRematch(true);
                await calloutService.createCallout(fighterProfile.user_id, {
                  target_user_id: selectedFighterForRematch.fighter.user_id || selectedFighterForRematch.fighter.id,
                  message: rematchMessage || undefined
                });
                setRematchDialogOpen(false);
                setRematchMessage('');
                setSelectedFighterForRematch(null);
                // Reload rematchable fighters
                const fighters = await calloutService.getRematchableFighters(fighterProfile.user_id);
                setRematchableFighters(fighters);
                alert('Rematch request sent successfully! The fighter will receive it on their My Profile page.');
              } catch (error: any) {
                console.error('Error sending rematch request:', error);
                // Provide user-friendly error message
                let errorMessage = 'Failed to send rematch request. ';
                if (error.message?.includes('Rank difference too large')) {
                  errorMessage += 'The rank difference is too large (max 5 ranks). This fighter is not currently eligible for a rematch.';
                } else if (error.message?.includes('Points difference')) {
                  errorMessage += 'The points difference is too large (max 30 points). This fighter is not currently eligible for a rematch.';
                } else if (error.message?.includes('tier')) {
                  errorMessage += 'Fighters must be in the same tier for rematches.';
                } else {
                  errorMessage += error.message || 'Unknown error';
                }
                alert(errorMessage);
              } finally {
                setSendingRematch(false);
              }
            }}
            variant="contained"
            color="error"
            startIcon={sendingRematch ? <CircularProgress size={16} /> : <EmojiEvents />}
            disabled={sendingRematch}
          >
            {sendingRematch ? 'Sending...' : 'Send Rematch Request'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Weekly Reset Confirmation Dialog */}
      <Dialog
        open={weeklyResetDialogOpen}
        onClose={() => !resettingWeekly && setWeeklyResetDialogOpen(false)}
        maxWidth="sm"
        fullWidth
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
        keepMounted={false}
      >
        <DialogTitle>Confirm Weekly Reset</DialogTitle>
        <DialogContent>
          <Typography variant="body1" paragraph>
            This will cancel all mandatory fights older than 1 week and create new matches for all fighters.
          </Typography>
          <Typography variant="body2" color="text.secondary">
            <strong>Warning:</strong> This action cannot be undone. All old mandatory fights will be marked as Cancelled.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button 
            onClick={() => setWeeklyResetDialogOpen(false)}
            disabled={resettingWeekly}
          >
            Cancel
          </Button>
          <Button
            onClick={async () => {
              if (!fighterProfile) return;
              try {
                setResettingWeekly(true);
                const result = await smartMatchmakingService.weeklyReset();
                alert(`Weekly reset complete! Cleared ${result.cleared} old fights and created ${result.newMatches} new matches.`);
                setWeeklyResetDialogOpen(false);
              } catch (error: any) {
                console.error('Error running weekly reset:', error);
                alert('Failed to run weekly reset: ' + (error.message || 'Unknown error'));
              } finally {
                setResettingWeekly(false);
              }
            }}
            variant="contained"
            color="warning"
            disabled={resettingWeekly}
            startIcon={resettingWeekly ? <CircularProgress size={16} /> : <Refresh />}
          >
            {resettingWeekly ? 'Resetting...' : 'Confirm Reset'}
          </Button>
        </DialogActions>
      </Dialog>
      </Box>
    </>
  );
};

export default Matchmaking;