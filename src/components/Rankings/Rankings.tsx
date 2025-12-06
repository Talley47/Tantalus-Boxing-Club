import React, { useState, useEffect, useRef } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  Tabs,
  Tab,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Avatar,
  LinearProgress,
  Tooltip,
  IconButton,
  Alert,
  Stack,
} from '@mui/material';
import {
  EmojiEvents,
  TrendingUp,
  TrendingDown,
  Remove,
  FilterList,
  Refresh,
  Info,
} from '@mui/icons-material';
import {
  getOverallRankings,
  getRankingsByWeightClass,
  getAvailableWeightClasses,
  RankingEntry,
  TIER_THRESHOLDS,
  getTierForPoints,
} from '../../services/rankingsService';
import { useAuth } from '../../contexts/AuthContext';
import { useRealtime } from '../../contexts/RealtimeContext';
// Import RBC Rankings page.png directly from src folder
import rankingsBackground from '../../RBC Rankings page.png';
// Import Logo1.png
import logo1 from '../../Logo1.png';


const Rankings: React.FC = () => {
  const { fighterProfile } = useAuth();
  const [rankings, setRankings] = useState<RankingEntry[]>([]);
  const [overallRankings, setOverallRankings] = useState<RankingEntry[]>([]);
  const [rankingsByWeightClass, setRankingsByWeightClass] = useState<{ [weightClass: string]: RankingEntry[] }>({});
  const [loading, setLoading] = useState(true);
  const [selectedWeightClass, setSelectedWeightClass] = useState<string>('all');
  const [availableWeightClasses, setAvailableWeightClasses] = useState<string[]>([]);
  const [activeTab, setActiveTab] = useState(0); // 0 = Overall, 1 = Weight Class

  const { subscribeToFightRecords, subscribeToRankings, subscribeToFighterProfiles } = useRealtime();
  
  // Debounce ref for real-time handlers to prevent blocking message handlers
  const reloadTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    loadWeightClasses();
  }, []);

  useEffect(() => {
    if (availableWeightClasses.length > 0 || activeTab === 0) {
      loadRankings();
    }

    // Debounced reload function to prevent blocking message handlers
    const debouncedReload = () => {
      if (reloadTimeoutRef.current) {
        clearTimeout(reloadTimeoutRef.current);
      }
      // Use setTimeout to defer heavy operation and prevent blocking message handler
      // Increased debounce to reduce frequency of expensive ranking calculations
      reloadTimeoutRef.current = setTimeout(() => {
        loadRankings();
        reloadTimeoutRef.current = null;
      }, 1000); // 1000ms debounce - rankings are expensive to calculate
    };

    // Subscribe to real-time changes
    const unsubscribeFightRecords = subscribeToFightRecords(() => {
      // Defer heavy reload operation
      debouncedReload();
    });

    const unsubscribeRankings = subscribeToRankings(() => {
      // Defer heavy reload operation
      debouncedReload();
    });

    const unsubscribeFighterProfiles = subscribeToFighterProfiles((payload) => {
      // Reload rankings when profiles change (affects points, tier, weight_class, etc.)
      // Check if points, tier, or weight_class changed - these directly affect rankings
      const rankingChange = 
        payload.old?.points !== payload.new?.points ||
        payload.old?.tier !== payload.new?.tier ||
        payload.old?.weight_class !== payload.new?.weight_class;
      
      // Only reload if ranking-affecting change detected, but still debounced
      if (rankingChange) {
        debouncedReload();
      }
    });

    return () => {
      unsubscribeFightRecords();
      unsubscribeRankings();
      unsubscribeFighterProfiles();
      // Clear any pending reloads on unmount
      if (reloadTimeoutRef.current) {
        clearTimeout(reloadTimeoutRef.current);
      }
    };
  }, [selectedWeightClass, activeTab, availableWeightClasses.length]);

  const loadWeightClasses = async () => {
    try {
      const classes = await getAvailableWeightClasses();
      setAvailableWeightClasses(classes);
    } catch (error) {
      console.error('Error loading weight classes:', error);
    }
  };

  const loadRankings = async () => {
    setLoading(true);
    try {
      if (activeTab === 0) {
        // Overall rankings - increased limit to ensure all fighters are shown
        const overall = await getOverallRankings(1000);
        setOverallRankings(overall);
        setRankings(overall);
      } else {
        // Weight class rankings - load all weight classes
        if (selectedWeightClass === 'all') {
          // Load rankings for all weight classes
          const allRankingsByClass: { [weightClass: string]: RankingEntry[] } = {};
          
          for (const weightClass of availableWeightClasses) {
            const rankings = await getRankingsByWeightClass(weightClass, 1000);
            if (rankings.length > 0) {
              allRankingsByClass[weightClass] = rankings;
            }
          }
          
          setRankingsByWeightClass(allRankingsByClass);
          // For "all" view, show flattened rankings sorted by points
          const allRankings = Object.values(allRankingsByClass).flat();
          allRankings.sort((a, b) => b.points - a.points);
          setRankings(allRankings);
        } else {
          // Single weight class selected - increased limit to ensure all fighters are shown
          const byClass = await getRankingsByWeightClass(selectedWeightClass, 1000);
          setRankings(byClass);
          setRankingsByWeightClass({ [selectedWeightClass]: byClass });
        }
      }
    } catch (error) {
      console.error('Error loading rankings:', error);
    } finally {
      setLoading(false);
    }
  };

  const getTierColor = (tier: string): string => {
    switch (tier.toLowerCase()) {
      case 'hall of famer':
        return '#FFD700'; // Gold
      case 'elite':
        return '#9C27B0'; // Purple
      case 'contender':
        return '#C0C0C0'; // Silver
      case 'pro':
        return '#CD7F32'; // Bronze
      case 'semi-pro':
        return '#90EE90'; // Light Green
      case 'amateur':
      default:
        return '#87CEEB'; // Sky Blue
    }
  };

  const getRankBadge = (rank: number) => {
    if (rank === 1) return <EmojiEvents sx={{ color: '#FFD700', fontSize: 24 }} />;
    if (rank === 2) return <EmojiEvents sx={{ color: '#C0C0C0', fontSize: 24 }} />;
    if (rank === 3) return <EmojiEvents sx={{ color: '#CD7F32', fontSize: 24 }} />;
    return <Typography variant="body2" sx={{ fontWeight: 'bold', minWidth: '24px' }}>#{rank}</Typography>;
  };

  const getStreakIcon = (streak?: number) => {
    if (!streak || streak === 0) return null;
    if (streak > 0) {
      return <TrendingUp sx={{ color: 'success.main', fontSize: 16 }} />;
    }
    return <TrendingDown sx={{ color: 'error.main', fontSize: 16 }} />;
  };

  const getCurrentFighterRank = (): number | null => {
    if (!fighterProfile?.user_id) return null;
    const fighterRank = rankings.findIndex(r => r.fighter_id === fighterProfile.user_id);
    return fighterRank >= 0 ? fighterRank + 1 : null;
  };

  return (
    <>
      {/* Full-screen background layer with RBC Rankings page.png */}
      <Box
        component="div"
        sx={{
          position: 'fixed',
          top: 0,
          left: { xs: 0, sm: '200px' },
          right: 0,
          bottom: 0,
          width: { xs: '100%', sm: 'calc(100% - 200px)' },
          height: '100vh',
          backgroundImage: rankingsBackground ? `url("${rankingsBackground}")` : 'url("/RBC Rankings page.png")',
          backgroundSize: '100% 100%',
          backgroundPosition: 'center center',
          backgroundRepeat: 'no-repeat',
          backgroundAttachment: 'fixed',
          zIndex: -1,
          // Ensure it's visible
          display: 'block',
          // Light overlay to ensure text readability
          '&::after': {
            content: '""',
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.2)',
            pointerEvents: 'none',
            zIndex: 1,
          },
        }}
      />
      {/* Content layer */}
      <Box 
        sx={{ 
          position: 'relative',
          zIndex: 0,
          py: 4,
          m: -3,
          px: 3,
          minHeight: '100vh',
          // Ensure content is readable over background
          '& .MuiCard-root': {
            backgroundColor: 'rgba(255, 255, 255, 0.92)',
            backdropFilter: 'blur(5px)',
          },
          '& .MuiAlert-root': {
            backgroundColor: 'rgba(255, 255, 255, 0.92)',
            backdropFilter: 'blur(5px)',
          },
          '& .MuiTableContainer-root': {
            backgroundColor: 'rgba(255, 255, 255, 0.92)',
            backdropFilter: 'blur(5px)',
          },
        }}
      >
      {/* Header */}
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
              <Typography 
                variant="h3" 
                gutterBottom 
                sx={{ 
                  fontWeight: 'bold',
                  color: 'white',
                  textShadow: '2px 2px 4px rgba(0,0,0,0.8)',
                }}
              >
                Club Rankings
              </Typography>
              <Typography 
                variant="body1" 
                sx={{ 
                  color: 'white',
                  textShadow: '1px 1px 2px rgba(0,0,0,0.8)',
                }}
              >
                Per-weight-class & overall leaderboards
              </Typography>
              {fighterProfile && (fighterProfile as any)?.original_weight_class && (
                <Typography 
                  variant="caption" 
                  sx={{ 
                    mt: 0.5, 
                    display: 'block',
                    color: 'rgba(255, 255, 255, 0.9)',
                    textShadow: '1px 1px 2px rgba(0,0,0,0.8)',
                  }}
                >
                  Note: You can move up or down 3 weight classes from your original_weight_class
                </Typography>
              )}
            </Box>
          </Box>
          <IconButton onClick={loadRankings} disabled={loading}>
            <Refresh />
          </IconButton>
        </Box>

        {/* Point System Info */}
        <Alert severity="info" icon={<Info />} sx={{ mb: 3 }}>
          <Typography variant="subtitle2" gutterBottom sx={{ fontWeight: 'bold' }}>
            Point System:
          </Typography>
          <Typography variant="body2">
            Win = +5 | Loss = -3 | Draw = 0 | KO/TKO Bonus = +3
          </Typography>
          <Typography variant="caption" display="block" sx={{ mt: 1 }}>
            Tiebreakers: Head-to-head → KO% → Strength of Opponent → Recent Form
          </Typography>
        </Alert>

        {/* Demotion System Info */}
        <Alert severity="warning" icon={<TrendingDown />} sx={{ mb: 3 }}>
          <Typography variant="subtitle2" gutterBottom sx={{ fontWeight: 'bold' }}>
            Demotion System:
          </Typography>
          <Typography variant="body2" component="div">
            <strong>Automatic Demotion:</strong> If a fighter loses 5 consecutive fights, they will be automatically demoted one tier.
          </Typography>
          <Typography variant="body2" component="div" sx={{ mt: 1 }}>
            <strong>Promotion Back:</strong> After demotion, a fighter must win 5 consecutive fights to be promoted back to their previous tier.
          </Typography>
          <Typography variant="caption" display="block" sx={{ mt: 1, fontStyle: 'italic' }}>
            Tier Progression: Amateur → Semi-Pro → Pro → Contender → Elite
          </Typography>
          <Typography variant="caption" display="block" sx={{ mt: 0.5 }}>
            ⚠️ Fighters with 3+ consecutive losses are at risk of demotion. Look for the red warning indicator (!) next to fighters' names.
          </Typography>
        </Alert>

        {/* Current Fighter Rank Highlight */}
        {fighterProfile && getCurrentFighterRank() && (
          <Alert severity="success" sx={{ mb: 3 }}>
            <Typography variant="body2">
              <strong>Your Rank:</strong> #{getCurrentFighterRank()} | {fighterProfile.points || 0} points |{' '}
              {fighterProfile.tier || 'Amateur'} Tier
            </Typography>
          </Alert>
        )}
      </Box>

      {/* Tabs for Overall vs Weight Class */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Tabs value={activeTab} onChange={(e, newValue) => {
            setActiveTab(newValue);
            if (newValue === 1 && availableWeightClasses.length === 0) {
              loadWeightClasses();
            }
          }} sx={{ mb: 2 }}>
            <Tab label="Overall Rankings" />
            <Tab label="Weight Class Rankings" />
          </Tabs>

          {activeTab === 1 && (
            <FormControl fullWidth sx={{ mt: 2 }}>
              <InputLabel id="weight-class-select-label">Weight Class</InputLabel>
              <Select
                value={selectedWeightClass}
                onChange={(e) => setSelectedWeightClass(e.target.value)}
                label="Weight Class"
                labelId="weight-class-select-label"
                aria-labelledby="weight-class-select-label"
              >
                <MenuItem 
                  value="all" 
                  aria-label={`All Weight Classes (${availableWeightClasses.length})`}
                >
                  All Weight Classes ({availableWeightClasses.length})
                </MenuItem>
                {availableWeightClasses.map((wc) => {
                  const fighterCount = rankingsByWeightClass[wc]?.length || 0;
                  const menuText = `${wc} (${fighterCount} fighters)`;
                  return (
                    <MenuItem 
                      key={wc} 
                      value={wc} 
                      aria-label={menuText}
                    >
                      {wc} ({fighterCount} fighters)
                    </MenuItem>
                  );
                })}
              </Select>
            </FormControl>
          )}
        </CardContent>
      </Card>

      {/* Tier Thresholds Display */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Tier Thresholds
          </Typography>
          <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2 }}>
            {TIER_THRESHOLDS.map((threshold) => (
              <Chip
                key={threshold.tier}
                label={
                  threshold.max_points
                    ? `${threshold.tier}: ${threshold.min_points}-${threshold.max_points} pts`
                    : `${threshold.tier}: ${threshold.min_points}+ pts`
                }
                sx={{
                  backgroundColor: getTierColor(threshold.tier),
                  color: (threshold.tier === 'Elite' || threshold.tier === 'Hall of famer') ? '#000' : '#fff',
                  fontWeight: 'bold',
                }}
              />
            ))}
          </Box>
        </CardContent>
      </Card>

      {/* Rankings Table */}
      <Card>
        <CardContent>
          {loading ? (
            <Box>
              <LinearProgress sx={{ mb: 2 }} />
              <Typography>Loading rankings...</Typography>
            </Box>
          ) : activeTab === 1 && selectedWeightClass === 'all' && Object.keys(rankingsByWeightClass).length > 0 ? (
            // Show rankings grouped by weight class
            <Stack spacing={3}>
              {Object.entries(rankingsByWeightClass)
                .sort(([a], [b]) => a.localeCompare(b))
                .map(([weightClass, classRankings]) => (
                  <Card key={weightClass} variant="outlined">
                    <CardContent>
                      <Typography variant="h5" gutterBottom sx={{ fontWeight: 'bold', mb: 2, textTransform: 'capitalize' }}>
                        {weightClass} Rankings ({classRankings.length} fighters)
                      </Typography>
                      <TableContainer component={Paper}>
                        <Table size="small">
                          <TableHead>
                            <TableRow>
                              <TableCell sx={{ fontWeight: 'bold' }}>Rank</TableCell>
                              <TableCell sx={{ fontWeight: 'bold' }}>Fighter</TableCell>
                              <TableCell sx={{ fontWeight: 'bold' }}>Tier</TableCell>
                              <TableCell sx={{ fontWeight: 'bold' }}>Points</TableCell>
                              <TableCell sx={{ fontWeight: 'bold' }}>Record</TableCell>
                              <TableCell sx={{ fontWeight: 'bold' }}>Stats</TableCell>
                              <TableCell sx={{ fontWeight: 'bold' }}>Recent Form</TableCell>
                              <TableCell sx={{ fontWeight: 'bold' }}>Streak</TableCell>
                            </TableRow>
                          </TableHead>
                          <TableBody>
                            {classRankings.map((entry) => {
                              const isCurrentFighter = fighterProfile?.user_id === entry.fighter_id;
                              return (
                                <TableRow
                                  key={entry.fighter_id}
                                  sx={{
                                    backgroundColor: isCurrentFighter ? 'action.selected' : 'inherit',
                                    '&:hover': { backgroundColor: 'action.hover' },
                                  }}
                                >
                                  <TableCell>{getRankBadge(entry.rank)}</TableCell>
                                  <TableCell>
                                    <Box display="flex" alignItems="center" gap={1}>
                                      <Avatar sx={{ width: 32, height: 32, bgcolor: 'primary.main' }}>
                                        {entry.name.charAt(0).toUpperCase()}
                                      </Avatar>
                                      <Box>
                                        <Box display="flex" alignItems="center" gap={1}>
                                          <Typography variant="body2" sx={{ fontWeight: isCurrentFighter ? 'bold' : 'normal' }}>
                                            {entry.name}
                                          </Typography>
                                          {entry.belts && entry.belts.length > 0 && (
                                            <Box display="flex" gap={0.5} alignItems="center">
                                              {entry.belts.map((belt) => (
                                                <Box
                                                  key={belt.id}
                                                  component="img"
                                                  src={belt.belt_image_url}
                                                  alt="Championship Belt"
                                                  sx={{
                                                    width: 36,
                                                    height: 36,
                                                    objectFit: 'contain',
                                                    borderRadius: '4px',
                                                  }}
                                                />
                                              ))}
                                            </Box>
                                          )}
                                        </Box>
                                        <Typography variant="caption" color="text.secondary">
                                          @{entry.handle}
                                        </Typography>
                                      </Box>
                                    </Box>
                                  </TableCell>
                                  <TableCell>
                                    <Chip
                                      label={entry.tier || 'Amateur'}
                                      size="small"
                                      sx={{
                                        backgroundColor: getTierColor(entry.tier || 'Amateur'),
                                        color: ((entry.tier || 'Amateur') === 'Elite' || (entry.tier || 'Amateur') === 'Hall of famer') ? '#000' : '#fff',
                                        fontWeight: 'bold',
                                      }}
                                    />
                                  </TableCell>
                                  <TableCell>
                                    <Typography variant="body2" sx={{ fontWeight: 'bold' }}>
                                      {entry.points ?? 0}
                                    </Typography>
                                  </TableCell>
                                  <TableCell>
                                    <Typography variant="body2">
                                      {entry.wins ?? 0}-{entry.losses ?? 0}-{entry.draws ?? 0}
                                    </Typography>
                                    {(entry.knockouts ?? 0) > 0 && (
                                      <Typography variant="caption" color="text.secondary">
                                        {entry.knockouts} KO
                                      </Typography>
                                    )}
                                  </TableCell>
                                  <TableCell>
                                    <Typography variant="caption" display="block">
                                      Win: {((entry.win_percentage ?? 0)).toFixed(1)}%
                                    </Typography>
                                    {(entry.ko_percentage ?? 0) > 0 && (
                                      <Typography variant="caption" color="text.secondary" display="block">
                                        KO: {(entry.ko_percentage ?? 0).toFixed(1)}%
                                      </Typography>
                                    )}
                                  </TableCell>
                                  <TableCell>
                                    <Box display="flex" gap={0.5}>
                                      {entry.recent_form.length > 0 ? (
                                        entry.recent_form.map((result, i) => (
                                          <Chip
                                            key={i}
                                            label={result}
                                            size="small"
                                            sx={{
                                              width: 24,
                                              height: 24,
                                              backgroundColor:
                                                result === 'W'
                                                  ? 'success.main'
                                                  : result === 'L'
                                                  ? 'error.main'
                                                  : 'default',
                                              color: 'white',
                                              fontSize: '0.7rem',
                                            }}
                                          />
                                        ))
                                      ) : (
                                        <Typography variant="caption" color="text.secondary">
                                          No fights
                                        </Typography>
                                      )}
                                    </Box>
                                  </TableCell>
                                  <TableCell>
                                    <Box display="flex" alignItems="center" gap={0.5}>
                                      {getStreakIcon(entry.current_streak)}
                                      {entry.current_streak && entry.current_streak !== 0 && (
                                        <Typography variant="caption" sx={{ fontWeight: 'bold' }}>
                                          {Math.abs(entry.current_streak)}
                                        </Typography>
                                      )}
                                      {entry.consecutive_losses && entry.consecutive_losses >= 3 && (
                                        <Tooltip 
                                          title={
                                            entry.consecutive_losses >= 5
                                              ? `⚠️ ${entry.consecutive_losses} consecutive losses - Demoted one tier!`
                                              : `⚠️ ${entry.consecutive_losses} consecutive losses - ${5 - entry.consecutive_losses} more loss(es) until demotion`
                                          }
                                        >
                                          <Chip
                                            label={entry.consecutive_losses >= 5 ? "⚠️" : "!"}
                                            size="small"
                                            color={entry.consecutive_losses >= 5 ? "error" : "warning"}
                                            sx={{ 
                                              width: entry.consecutive_losses >= 5 ? 28 : 20, 
                                              height: 20, 
                                              fontSize: '0.7rem',
                                              fontWeight: 'bold'
                                            }}
                                          />
                                        </Tooltip>
                                      )}
                                    </Box>
                                  </TableCell>
                                </TableRow>
                              );
                            })}
                          </TableBody>
                        </Table>
                      </TableContainer>
                    </CardContent>
                  </Card>
                ))}
            </Stack>
          ) : rankings.length === 0 ? (
            <Alert severity="info">No fighters found in rankings.</Alert>
          ) : (
            <TableContainer component={Paper}>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell sx={{ fontWeight: 'bold' }}>Rank</TableCell>
                    <TableCell sx={{ fontWeight: 'bold' }}>Fighter</TableCell>
                    {activeTab === 0 && <TableCell sx={{ fontWeight: 'bold' }}>Weight Class</TableCell>}
                    <TableCell sx={{ fontWeight: 'bold' }}>Tier</TableCell>
                    <TableCell sx={{ fontWeight: 'bold' }}>Points</TableCell>
                    <TableCell sx={{ fontWeight: 'bold' }}>Record</TableCell>
                    <TableCell sx={{ fontWeight: 'bold' }}>Stats</TableCell>
                    <TableCell sx={{ fontWeight: 'bold' }}>Recent Form</TableCell>
                    <TableCell sx={{ fontWeight: 'bold' }}>Streak</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {rankings.map((entry, index) => {
                    const isCurrentFighter = fighterProfile?.user_id === entry.fighter_id;
                    return (
                      <TableRow
                        key={entry.fighter_id}
                        sx={{
                          backgroundColor: isCurrentFighter ? 'action.selected' : 'inherit',
                          '&:hover': { backgroundColor: 'action.hover' },
                        }}
                      >
                        <TableCell>
                          <Box display="flex" alignItems="center" gap={1}>
                            {getRankBadge(entry.rank)}
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Box display="flex" alignItems="center" gap={1}>
                            <Avatar sx={{ width: 32, height: 32, bgcolor: 'primary.main' }}>
                              {entry.name.charAt(0).toUpperCase()}
                            </Avatar>
                            <Box>
                              <Box display="flex" alignItems="center" gap={1}>
                                <Typography variant="body2" sx={{ fontWeight: isCurrentFighter ? 'bold' : 'normal' }}>
                                  {entry.name}
                                </Typography>
                                {entry.belts && entry.belts.length > 0 && (
                                  <Box display="flex" gap={0.5} alignItems="center">
                                    {entry.belts.map((belt) => (
                                      <Box
                                        key={belt.id}
                                        component="img"
                                        src={belt.belt_image_url}
                                        alt="Championship Belt"
                                        sx={{
                                          width: 24,
                                          height: 24,
                                          objectFit: 'contain',
                                          borderRadius: '4px',
                                        }}
                                      />
                                    ))}
                                  </Box>
                                )}
                              </Box>
                              <Typography variant="caption" color="text.secondary">
                                @{entry.handle}
                              </Typography>
                            </Box>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" sx={{ textTransform: 'capitalize' }}>
                            {entry.weight_class || 'Unknown'}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={entry.tier || 'Amateur'}
                            size="small"
                            sx={{
                              backgroundColor: getTierColor(entry.tier || 'Amateur'),
                              color: ((entry.tier || 'Amateur') === 'Elite' || (entry.tier || 'Amateur') === 'Hall of famer') ? '#000' : '#fff',
                              fontWeight: 'bold',
                            }}
                          />
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" sx={{ fontWeight: 'bold' }}>
                            {entry.points ?? 0}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {entry.wins ?? 0}-{entry.losses ?? 0}-{entry.draws ?? 0}
                          </Typography>
                          {(entry.knockouts ?? 0) > 0 && (
                            <Typography variant="caption" color="text.secondary">
                              {entry.knockouts} KO
                            </Typography>
                          )}
                        </TableCell>
                        <TableCell>
                          <Typography variant="caption" display="block">
                            Win: {((entry.win_percentage ?? 0)).toFixed(1)}%
                          </Typography>
                          {(entry.ko_percentage ?? 0) > 0 && (
                            <Typography variant="caption" color="text.secondary" display="block">
                              KO: {(entry.ko_percentage ?? 0).toFixed(1)}%
                            </Typography>
                          )}
                        </TableCell>
                        <TableCell>
                          <Box display="flex" gap={0.5}>
                            {entry.recent_form.length > 0 ? (
                              entry.recent_form.map((result, i) => (
                                <Chip
                                  key={i}
                                  label={result}
                                  size="small"
                                  sx={{
                                    width: 24,
                                    height: 24,
                                    backgroundColor:
                                      result === 'W'
                                        ? 'success.main'
                                        : result === 'L'
                                        ? 'error.main'
                                        : 'default',
                                    color: 'white',
                                    fontSize: '0.7rem',
                                  }}
                                />
                              ))
                            ) : (
                              <Typography variant="caption" color="text.secondary">
                                No fights
                              </Typography>
                            )}
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Box display="flex" alignItems="center" gap={0.5}>
                            {getStreakIcon(entry.current_streak)}
                            {entry.current_streak && entry.current_streak !== 0 && (
                              <Typography variant="caption" sx={{ fontWeight: 'bold' }}>
                                {Math.abs(entry.current_streak)}
                              </Typography>
                            )}
                            {entry.consecutive_losses && entry.consecutive_losses >= 3 && (
                              <Tooltip 
                                title={
                                  entry.consecutive_losses >= 5
                                    ? `⚠️ ${entry.consecutive_losses} consecutive losses - Demoted one tier!`
                                    : `⚠️ ${entry.consecutive_losses} consecutive losses - ${5 - entry.consecutive_losses} more loss(es) until demotion`
                                }
                              >
                                <Chip
                                  label={entry.consecutive_losses >= 5 ? "⚠️" : "!"}
                                  size="small"
                                  color={entry.consecutive_losses >= 5 ? "error" : "warning"}
                                  sx={{ 
                                    width: entry.consecutive_losses >= 5 ? 28 : 20, 
                                    height: 20, 
                                    fontSize: '0.7rem',
                                    fontWeight: 'bold'
                                  }}
                                />
                              </Tooltip>
                            )}
                          </Box>
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </CardContent>
      </Card>
      </Box>
    </>
  );
};

export default Rankings;
