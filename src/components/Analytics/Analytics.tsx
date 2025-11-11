import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  CircularProgress,
  Alert,
  Chip,
  LinearProgress,
} from '@mui/material';
import {
  TrendingUp,
  EmojiEvents,
  SportsMma,
  LocalFireDepartment,
} from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';
import { useRealtime } from '../../contexts/RealtimeContext';
import { AnalyticsService, FighterAnalytics } from '../../services/analyticsService';
// Import Logo1.png
import logo1 from '../../Logo1.png';
// Import Canelo undisputed.png background
import caneloBackground from '../../Canelo undisputed.png';

// Debug log
console.log('Analytics background image path:', caneloBackground);

const Analytics: React.FC = () => {
  const { fighterProfile } = useAuth();
  const { subscribeToFightRecords, subscribeToFighterProfiles } = useRealtime();
  const [analytics, setAnalytics] = useState<FighterAnalytics | null>(null);
  const [loading, setLoading] = useState(true);

  const loadAnalytics = async () => {
    if (!fighterProfile?.id && !fighterProfile?.user_id) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      // Try with id first, then fallback to user_id
      const fighterId = fighterProfile.id || fighterProfile.user_id;
      console.log('Loading analytics for fighter:', { id: fighterProfile.id, user_id: fighterProfile.user_id, using: fighterId });
      const data = await AnalyticsService.getFighterAnalytics(fighterId);
      console.log('Analytics data loaded:', data);
      setAnalytics(data);
    } catch (error) {
      console.error('Error loading analytics:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadAnalytics();
  }, [fighterProfile?.id]);

  // Real-time updates
  useEffect(() => {
    const unsubscribeFightRecords = subscribeToFightRecords((payload) => {
      console.log('Fight record changed - reloading analytics:', payload);
      // Reload analytics when fight records change (affects stats)
      if (fighterProfile && (
        payload.new?.fighter_id === fighterProfile.id || 
        payload.new?.fighter_id === fighterProfile.user_id ||
        payload.new?.opponent_id === fighterProfile.id ||
        payload.new?.opponent_id === fighterProfile.user_id
      )) {
        loadAnalytics();
      }
    });

    const unsubscribeFighterProfiles = subscribeToFighterProfiles((payload) => {
      console.log('Fighter profile changed - reloading analytics:', payload);
      // Reload analytics when fighter profile changes (affects stats, tier, etc.)
      if (fighterProfile && payload.new?.user_id === fighterProfile.user_id) {
        loadAnalytics();
      }
    });

    return () => {
      unsubscribeFightRecords();
      unsubscribeFighterProfiles();
    };
  }, [fighterProfile?.id, fighterProfile?.user_id]);

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight={400}>
        <CircularProgress />
      </Box>
    );
  }

  if (!fighterProfile) {
    return (
      <Alert severity="info">
        Please complete your fighter profile to view analytics.
      </Alert>
    );
  }

  if (!analytics) {
    return (
      <Alert severity="warning">
        Unable to load analytics. Please try again later.
      </Alert>
    );
  }

  return (
    <>
      {/* Full-screen background layer */}
      <Box
        component="div"
        sx={{
          position: 'fixed',
          top: 0,
          left: { xs: 0, sm: '240px' },
          right: 0,
          bottom: 0,
          width: { xs: '100%', sm: 'calc(100% - 240px)' },
          height: '100vh',
          backgroundImage: caneloBackground ? `url("${caneloBackground}")` : 'url("/Canelo undisputed.png")',
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
            backgroundColor: 'rgba(0, 0, 0, 0.5)',
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
      <Box display="flex" alignItems="center" gap={2} mb={3}>
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
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 'bold', mb: 0, color: 'white', textShadow: '2px 2px 4px rgba(0,0,0,0.8)' }}>
          Fighter Analytics
        </Typography>
      </Box>

      {/* Key Stats Grid */}
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr', md: 'repeat(4, 1fr)' }, gap: 2, mb: 3 }}>
        <Card sx={{ backgroundColor: 'rgba(255, 255, 255, 0.95)' }}>
          <CardContent>
            <Box display="flex" alignItems="center" mb={1}>
              <EmojiEvents sx={{ mr: 1, color: 'primary.main' }} />
              <Typography variant="h6">Overall Rank</Typography>
            </Box>
            <Typography variant="h4" fontWeight="bold">
              #{analytics.rank_overall || 'N/A'}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              Out of all fighters
            </Typography>
          </CardContent>
        </Card>

        <Card sx={{ backgroundColor: 'rgba(255, 255, 255, 0.95)' }}>
          <CardContent>
            <Box display="flex" alignItems="center" mb={1}>
              <TrendingUp sx={{ mr: 1, color: 'success.main' }} />
              <Typography variant="h6">Points</Typography>
            </Box>
            <Typography variant="h4" fontWeight="bold">
              {analytics.points}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              Tier: {analytics.tier}
            </Typography>
          </CardContent>
        </Card>

        <Card sx={{ backgroundColor: 'rgba(255, 255, 255, 0.95)' }}>
          <CardContent>
            <Box display="flex" alignItems="center" mb={1}>
              <SportsMma sx={{ mr: 1, color: 'info.main' }} />
              <Typography variant="h6">Win Rate</Typography>
            </Box>
            <Typography variant="h4" fontWeight="bold">
              {analytics.win_percentage.toFixed(1)}%
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {analytics.wins}W - {analytics.losses}L - {analytics.draws}D
            </Typography>
          </CardContent>
        </Card>

        <Card sx={{ backgroundColor: 'rgba(255, 255, 255, 0.95)' }}>
          <CardContent>
            <Box display="flex" alignItems="center" mb={1}>
              <LocalFireDepartment sx={{ mr: 1, color: 'error.main' }} />
              <Typography variant="h6">KO Rate</Typography>
            </Box>
            <Typography variant="h4" fontWeight="bold">
              {analytics.ko_percentage.toFixed(1)}%
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {analytics.knockouts} KOs
            </Typography>
          </CardContent>
        </Card>
      </Box>

      {/* Rankings by Category */}
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr 1fr' }, gap: 2, mb: 3 }}>
        <Card sx={{ backgroundColor: 'rgba(255, 255, 255, 0.95)' }}>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Weight Class Ranking
            </Typography>
            <Typography variant="h3" fontWeight="bold" color="primary.main">
              #{analytics.rank_by_weight_class || 'N/A'}
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
              {analytics.weight_class}
            </Typography>
          </CardContent>
        </Card>

        <Card sx={{ backgroundColor: 'rgba(255, 255, 255, 0.95)' }}>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Tier Ranking
            </Typography>
            <Typography variant="h3" fontWeight="bold" color="secondary.main">
              #{analytics.rank_by_tier || 'N/A'}
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
              {analytics.tier} Tier
            </Typography>
          </CardContent>
        </Card>

        <Card sx={{ backgroundColor: 'rgba(255, 255, 255, 0.95)' }}>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Overall Ranking
            </Typography>
            <Typography variant="h3" fontWeight="bold" color="success.main">
              #{analytics.rank_overall || 'N/A'}
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
              League-wide
            </Typography>
          </CardContent>
        </Card>
      </Box>

      {/* Performance Metrics */}
      <Card sx={{ mb: 3, backgroundColor: 'rgba(255, 255, 255, 0.95)' }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Performance Metrics
          </Typography>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2, mt: 2 }}>
            <Box>
              <Typography variant="body2" color="text.secondary">
                Total Matches
              </Typography>
              <Typography variant="h5" fontWeight="bold">
                {analytics.total_matches}
              </Typography>
            </Box>
            <Box>
              <Typography variant="body2" color="text.secondary">
                Average Points per Match
              </Typography>
              <Typography variant="h5" fontWeight="bold">
                {analytics.average_points_per_match.toFixed(2)}
              </Typography>
            </Box>
            <Box>
              <Typography variant="body2" color="text.secondary">
                Consecutive Losses
              </Typography>
              <Typography 
                variant="h5" 
                fontWeight="bold"
                color={analytics.consecutive_losses >= 3 ? 'error.main' : 'text.primary'}
              >
                {analytics.consecutive_losses}
              </Typography>
              {analytics.consecutive_losses >= 3 && (
                <Chip 
                  label={
                    analytics.consecutive_losses >= 5 
                      ? `⚠️ ${analytics.consecutive_losses} losses - Demotion risk!` 
                      : `⚠️ ${analytics.consecutive_losses} losses - Warning!`
                  } 
                  color="error" 
                  size="small" 
                  sx={{ mt: 1 }} 
                />
              )}
            </Box>
            <Box>
              <Typography variant="body2" color="text.secondary">
                Current Tier
              </Typography>
              <Chip 
                label={analytics.tier} 
                color="primary" 
                sx={{ mt: 1, fontWeight: 'bold' }}
              />
            </Box>
          </Box>
        </CardContent>
      </Card>
      </Box>
    </>
  );
};

export default Analytics;
