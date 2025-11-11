import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  LinearProgress,
  Chip,
  Grid,
  Avatar,
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  ListItemSecondaryAction,
  Divider,
  Alert,
  Paper,
  Stepper,
  Step,
  StepLabel,
  StepContent,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
} from '@mui/material';
import {
  EmojiEvents,
  TrendingUp,
  TrendingDown,
  Star,
  Timeline,
  Assessment,
  History,
  Info,
} from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';
import { useRealtime } from '../../contexts/RealtimeContext';
import { tierService, TierChange, TierStats } from '../../services/tierService';
import { Tier, TierHistory } from '../../types';
// Import Logo1.png
import logo1 from '../../Logo1.png';

const TierSystem: React.FC = () => {
  const { fighterProfile } = useAuth();
  const { subscribeToFightRecords, subscribeToFighterProfiles } = useRealtime();
  const [tiers, setTiers] = useState<Tier[]>([]);
  const [tierStats, setTierStats] = useState<TierStats | null>(null);
  const [tierHistory, setTierHistory] = useState<TierHistory[]>([]);
  const [tierProgression, setTierProgression] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [selectedTier, setSelectedTier] = useState<string>('');
  const [tierFighters, setTierFighters] = useState<any[]>([]);
  const [tierDialogOpen, setTierDialogOpen] = useState(false);

  useEffect(() => {
    loadTierData();
  }, []);

  // Real-time updates for tier system
  useEffect(() => {
    const unsubscribeFightRecords = subscribeToFightRecords((payload) => {
      console.log('Fight record changed - reloading tier data:', payload);
      loadTierData();
    });

    const unsubscribeFighterProfiles = subscribeToFighterProfiles((payload) => {
      console.log('Fighter profile changed - reloading tier data:', payload);
      // Reload if tier changed (affects tier distribution and stats)
      const tierChanged = payload.new?.tier !== payload.old?.tier;
      const pointsChanged = payload.new?.points !== payload.old?.points;
      
      if (tierChanged) {
        console.log('Tier change detected - reloading tier data:', {
          fighter: payload.new?.name || payload.new?.user_id,
          old_tier: payload.old?.tier,
          new_tier: payload.new?.tier,
          points: `${payload.old?.points} → ${payload.new?.points}`
        });
        // Always reload when tier changes (affects tier distribution)
        loadTierData();
      } else if (fighterProfile && payload.new?.user_id === fighterProfile.user_id && pointsChanged) {
        // Current fighter's points changed (may affect tier progression)
        loadTierData();
      } else if (pointsChanged) {
        // Any fighter's points changed (may affect tier distribution)
        loadTierData();
      }
    });

    return () => {
      unsubscribeFightRecords();
      unsubscribeFighterProfiles();
    };
  }, [fighterProfile?.user_id]);

  const loadTierData = async () => {
    try {
      setLoading(true);
      
      // Load tiers
      const tiersData = await tierService.getTiers();
      setTiers(tiersData);
      
      // Load tier statistics
      const stats = await tierService.getTierStats();
      setTierStats(stats);
      
      // Load fighter's tier progression if available
      if (fighterProfile) {
        const progression = await tierService.getTierProgression(fighterProfile.id);
        setTierProgression(progression);
        
        // Load tier history
        const history = await tierService.getTierHistory(fighterProfile.id);
        setTierHistory(history);
      }
    } catch (error) {
      console.error('Error loading tier data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleTierClick = async (tierName: string) => {
    try {
      setSelectedTier(tierName);
      const fighters = await tierService.getFightersByTier(tierName);
      setTierFighters(fighters);
      setTierDialogOpen(true);
    } catch (error) {
      console.error('Error loading tier fighters:', error);
    }
  };

  const getTierColor = (tierName: string) => {
    const colors: { [key: string]: string } = {
      'Amateur': '#808080',
      'Semi-Pro': '#4CAF50',
      'Pro': '#2196F3',
      'Contender': '#FF9800',
      'Elite': '#9C27B0'
    };
    return colors[tierName] || '#808080';
  };

  const getTierIcon = (tierName: string) => {
    if (tierName === 'Elite') return <Star />;
    if (tierName === 'Contender') return <EmojiEvents />;
    if (tierName === 'Pro') return <TrendingUp />;
    if (tierName === 'Semi-Pro') return <Assessment />;
    return <Timeline />;
  };

  return (
    <Box sx={{ p: 3 }}>
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
        <Typography variant="h4" gutterBottom sx={{ mb: 0 }}>
          Tier System
        </Typography>
      </Box>
      
      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        The Tantalus Boxing Club uses a 5-tier progression system based on points earned through fights.
        Fighters automatically promote when reaching point thresholds and demote after 5 consecutive losses.
      </Typography>

      {/* Fighter's Current Tier Progress */}
      {fighterProfile && tierProgression && (
        <Card sx={{ mb: 4 }}>
          <CardContent>
            <Box display="flex" alignItems="center" mb={2}>
              <Avatar sx={{ bgcolor: getTierColor(fighterProfile.tier), mr: 2 }}>
                {getTierIcon(fighterProfile.tier)}
              </Avatar>
              <Box>
                <Typography variant="h6">
                  Your Tier: {fighterProfile.tier}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {fighterProfile.points} points
                </Typography>
              </Box>
            </Box>
            
            <Box mb={2}>
              <Box display="flex" justifyContent="space-between" mb={1}>
                <Typography variant="body2">
                  Progress to next tier
                </Typography>
                <Typography variant="body2">
                  {tierProgression.tier_progress_percentage}%
                </Typography>
              </Box>
              <LinearProgress 
                variant="determinate" 
                value={tierProgression.tier_progress_percentage}
                sx={{ height: 8, borderRadius: 4 }}
              />
              <Typography variant="caption" color="text.secondary" sx={{ mt: 1 }}>
                {tierProgression.points_to_next_tier} points to next tier
              </Typography>
            </Box>
          </CardContent>
        </Card>
      )}

      {/* Tier Overview */}
      <Card sx={{ mb: 4 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Tier Overview
          </Typography>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr', md: '1fr 1fr 1fr 1fr 1fr' }, gap: 2 }}>
            {tiers.map((tier) => (
              <Paper
                key={tier.name}
                sx={{
                  p: 2,
                  cursor: 'pointer',
                  border: `2px solid ${tier.color}`,
                  '&:hover': { bgcolor: `${tier.color}10` }
                }}
                onClick={() => handleTierClick(tier.name)}
              >
                <Box display="flex" alignItems="center" mb={1}>
                  <Avatar sx={{ bgcolor: tier.color, mr: 1, width: 32, height: 32 }}>
                    {getTierIcon(tier.name)}
                  </Avatar>
                  <Typography variant="subtitle1" fontWeight="bold">
                    {tier.name}
                  </Typography>
                </Box>
                <Typography variant="body2" color="text.secondary" mb={1}>
                  {tier.min_points} - {tier.max_points || '∞'} points
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  {tier.benefits.join(', ')}
                </Typography>
              </Paper>
            ))}
          </Box>
        </CardContent>
      </Card>

      {/* Tier Statistics */}
      {tierStats && (
        <Card sx={{ mb: 4 }}>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              League Statistics
            </Typography>
            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr', md: '1fr 1fr 1fr 1fr' }, gap: 2 }}>
              <Paper sx={{ p: 2, textAlign: 'center' }}>
                <Typography variant="h4" color="primary">
                  {tierStats.total_fighters}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Total Fighters
                </Typography>
              </Paper>
              <Paper sx={{ p: 2, textAlign: 'center' }}>
                <Typography variant="h4" color="success.main">
                  {tierStats.recent_promotions}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Recent Promotions
                </Typography>
              </Paper>
              <Paper sx={{ p: 2, textAlign: 'center' }}>
                <Typography variant="h4" color="warning.main">
                  {tierStats.recent_demotions}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Recent Demotions
                </Typography>
              </Paper>
              <Paper sx={{ p: 2, textAlign: 'center' }}>
                <Typography variant="h4" color="info.main">
                  {Object.keys(tierStats.tier_distribution).length}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Active Tiers
                </Typography>
              </Paper>
            </Box>
          </CardContent>
        </Card>
      )}

      {/* Tier History */}
      {tierHistory.length > 0 && (
        <Card sx={{ mb: 4 }}>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Your Tier History
            </Typography>
            <List>
              {tierHistory.map((change, index) => (
                <React.Fragment key={index}>
                  <ListItem>
                    <ListItemAvatar>
                      <Avatar sx={{ bgcolor: getTierColor(change.to_tier) }}>
                        {change.reason === 'Points threshold reached' ? <TrendingUp /> : <TrendingDown />}
                      </Avatar>
                    </ListItemAvatar>
                    <ListItemText
                      primary={`${change.from_tier} → ${change.to_tier}`}
                      secondary={change.reason}
                    />
                    <ListItemSecondaryAction>
                      <Chip
                        label={change.reason === 'Points threshold reached' ? 'Promotion' : 'Demotion'}
                        color={change.reason === 'Points threshold reached' ? 'success' : 'warning'}
                        size="small"
                      />
                    </ListItemSecondaryAction>
                  </ListItem>
                  {index < tierHistory.length - 1 && <Divider />}
                </React.Fragment>
              ))}
            </List>
          </CardContent>
        </Card>
      )}

      {/* Tier Rules */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Tier Rules & Progression
          </Typography>
          <Stepper orientation="vertical">
            <Step>
              <StepLabel>Automatic Promotion</StepLabel>
              <StepContent>
                <Typography variant="body2">
                  Fighters are automatically promoted when they reach the point threshold for the next tier.
                </Typography>
              </StepContent>
            </Step>
            <Step>
              <StepLabel>5-Loss Demotion Rule</StepLabel>
              <StepContent>
                <Typography variant="body2">
                  Fighters are demoted one tier after 5 consecutive losses. Fighters with 3+ consecutive losses show a warning indicator. This rule does not apply to Amateur tier.
                </Typography>
              </StepContent>
            </Step>
            <Step>
              <StepLabel>Elite Tier Benefits</StepLabel>
              <StepContent>
                <Typography variant="body2">
                  Elite tier fighters (150+ points) unlock special features including live events, interviews, and press conferences.
                </Typography>
              </StepContent>
            </Step>
            <Step>
              <StepLabel>Point System</StepLabel>
              <StepContent>
                <Typography variant="body2">
                  Win: +5 points, Loss: -3 points, Draw: 0 points. KO/TKO bonus: +3 points (total +8 for KO win).
                </Typography>
              </StepContent>
            </Step>
          </Stepper>
        </CardContent>
      </Card>

      {/* Tier Fighters Dialog */}
      <Dialog 
        open={tierDialogOpen} 
        onClose={() => setTierDialogOpen(false)} 
        maxWidth="md" 
        fullWidth
        aria-labelledby="tier-dialog-title"
      >
        <DialogTitle id="tier-dialog-title">
          {selectedTier} Tier Fighters
        </DialogTitle>
        <DialogContent>
          <List>
            {tierFighters.map((fighter, index) => (
              <ListItem key={fighter.id}>
                <ListItemAvatar>
                  <Avatar src={fighter.profile_photo_url}>
                    {fighter.name.charAt(0)}
                  </Avatar>
                </ListItemAvatar>
                <ListItemText
                  primary={fighter.name}
                  secondary={`${fighter.points} points • ${fighter.wins}-${fighter.losses}-${fighter.draws}`}
                />
                <ListItemSecondaryAction>
                  <Chip label={`#${fighter.rank}`} color="primary" size="small" />
                </ListItemSecondaryAction>
              </ListItem>
            ))}
          </List>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setTierDialogOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default TierSystem;
export {};