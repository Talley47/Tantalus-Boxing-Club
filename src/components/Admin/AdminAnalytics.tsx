import React, { useState, useEffect } from 'react';
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
  CircularProgress,
  Alert,
  Chip,
  Grid,
} from '@mui/material';
import {
  People,
  TrendingUp,
  SportsMma,
  Warning,
  EmojiEvents,
} from '@mui/icons-material';
import { useRealtime } from '../../contexts/RealtimeContext';
import { AnalyticsService, LeagueAnalytics, FighterAnalytics } from '../../services/analyticsService';

const AdminAnalytics: React.FC = () => {
  const { subscribeToFightRecords, subscribeToFighterProfiles } = useRealtime();
  const [leagueAnalytics, setLeagueAnalytics] = useState<LeagueAnalytics | null>(null);
  const [allFightersAnalytics, setAllFightersAnalytics] = useState<FighterAnalytics[]>([]);
  const [loading, setLoading] = useState(true);

  const loadAnalytics = async () => {
    try {
      setLoading(true);
      const [league, fighters] = await Promise.all([
        AnalyticsService.getLeagueAnalytics(),
        AnalyticsService.getAllFightersAnalytics(),
      ]);
      setLeagueAnalytics(league);
      setAllFightersAnalytics(fighters);
    } catch (error) {
      console.error('Error loading analytics:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadAnalytics();
  }, []);

  // Real-time updates
  useEffect(() => {
    const unsubscribeFightRecords = subscribeToFightRecords((payload) => {
      console.log('Fight record changed - reloading admin analytics:', payload);
      // Reload analytics when any fight record changes (affects league stats)
      loadAnalytics();
    });

    const unsubscribeFighterProfiles = subscribeToFighterProfiles((payload) => {
      console.log('Fighter profile changed - reloading admin analytics:', payload);
      // Reload analytics when any fighter profile changes (affects league stats, tier distribution, etc.)
      // Check if points, tier, or weight_class changed - these affect league analytics
      const analyticsChange = 
        payload.old?.points !== payload.new?.points ||
        payload.old?.tier !== payload.new?.tier ||
        payload.old?.weight_class !== payload.new?.weight_class;
      
      if (analyticsChange) {
        console.log('Analytics-affecting change detected:', {
          points: `${payload.old?.points} → ${payload.new?.points}`,
          tier: `${payload.old?.tier} → ${payload.new?.tier}`,
          weight_class: `${payload.old?.weight_class} → ${payload.new?.weight_class}`
        });
      }
      loadAnalytics();
    });

    return () => {
      unsubscribeFightRecords();
      unsubscribeFighterProfiles();
    };
  }, []);

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight={400}>
        <CircularProgress />
      </Box>
    );
  }

  if (!leagueAnalytics) {
    return <Alert severity="error">Failed to load analytics</Alert>;
  }

  return (
    <Card>
      <CardContent>
        <Box display="flex" alignItems="center" mb={3}>
          <TrendingUp sx={{ mr: 1 }} />
          <Typography variant="h6">League Analytics Dashboard</Typography>
        </Box>

        {/* Overview Stats */}
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr', md: 'repeat(4, 1fr)' }, gap: 2, mb: 3 }}>
          <Card variant="outlined">
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <People sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="body2" color="text.secondary">Total Fighters</Typography>
              </Box>
              <Typography variant="h4" fontWeight="bold">
                {leagueAnalytics.total_fighters}
              </Typography>
            </CardContent>
          </Card>

          <Card variant="outlined">
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <TrendingUp sx={{ mr: 1, color: 'success.main' }} />
                <Typography variant="body2" color="text.secondary">Active Fighters</Typography>
              </Box>
              <Typography variant="h4" fontWeight="bold" color="success.main">
                {leagueAnalytics.active_fighters}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                {leagueAnalytics.inactive_fighters} inactive
              </Typography>
            </CardContent>
          </Card>

          <Card variant="outlined">
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <SportsMma sx={{ mr: 1, color: 'info.main' }} />
                <Typography variant="body2" color="text.secondary">Total Matches</Typography>
              </Box>
              <Typography variant="h4" fontWeight="bold">
                {leagueAnalytics.total_matches}
              </Typography>
            </CardContent>
          </Card>

          <Card variant="outlined">
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <EmojiEvents sx={{ mr: 1, color: 'error.main' }} />
                <Typography variant="body2" color="text.secondary">Total KOs</Typography>
              </Box>
              <Typography variant="h4" fontWeight="bold" color="error.main">
                {leagueAnalytics.total_knockouts}
              </Typography>
            </CardContent>
          </Card>
        </Box>

        {/* Averages */}
        <Card variant="outlined" sx={{ mb: 3 }}>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Average Points
            </Typography>
            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr 1fr' }, gap: 2, mt: 2 }}>
              <Box>
                <Typography variant="body2" color="text.secondary">Overall Average</Typography>
                <Typography variant="h5" fontWeight="bold">
                  {leagueAnalytics.average_points.toFixed(2)}
                </Typography>
              </Box>
              <Box>
                <Typography variant="body2" color="text.secondary">By Weight Class</Typography>
                {Object.entries(leagueAnalytics.average_points_by_weight_class).slice(0, 3).map(([wc, avg]) => (
                  <Typography key={wc} variant="body2">
                    {wc}: {avg.toFixed(2)}
                  </Typography>
                ))}
              </Box>
              <Box>
                <Typography variant="body2" color="text.secondary">By Tier</Typography>
                {Object.entries(leagueAnalytics.average_points_by_tier).map(([tier, avg]) => (
                  <Typography key={tier} variant="body2">
                    {tier}: {avg.toFixed(2)}
                  </Typography>
                ))}
              </Box>
            </Box>
          </CardContent>
        </Card>

        {/* Distribution */}
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 2, mb: 3 }}>
          <Card variant="outlined">
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Fighters by Weight Class
              </Typography>
              {Object.entries(leagueAnalytics.fighters_by_weight_class).map(([wc, count]) => (
                <Box key={wc} display="flex" justifyContent="space-between" alignItems="center" sx={{ mb: 1 }}>
                  <Typography variant="body2">{wc}</Typography>
                  <Chip label={count} size="small" />
                </Box>
              ))}
            </CardContent>
          </Card>

          <Card variant="outlined">
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Fighters by Tier
              </Typography>
              {Object.entries(leagueAnalytics.fighters_by_tier).map(([tier, count]) => (
                <Box key={tier} display="flex" justifyContent="space-between" alignItems="center" sx={{ mb: 1 }}>
                  <Typography variant="body2">{tier}</Typography>
                  <Chip label={count} size="small" color="primary" />
                </Box>
              ))}
            </CardContent>
          </Card>
        </Box>

        {/* Fighters with 3+ Consecutive Losses (Warning) */}
        {leagueAnalytics.fighters_with_four_consecutive_losses.length > 0 && (
          <Card variant="outlined" sx={{ mb: 3, borderColor: 'error.main' }}>
            <CardContent>
              <Box display="flex" alignItems="center" mb={2}>
                <Warning sx={{ mr: 1, color: 'error.main' }} />
                <Typography variant="h6" color="error.main">
                  Fighters with 3+ Consecutive Losses (Warning)
                </Typography>
              </Box>
              <TableContainer>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Fighter</TableCell>
                      <TableCell>Weight Class</TableCell>
                      <TableCell>Tier</TableCell>
                      <TableCell>Points</TableCell>
                      <TableCell>Record</TableCell>
                      <TableCell>Consecutive Losses</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {leagueAnalytics.fighters_with_four_consecutive_losses.map((fighter) => (
                      <TableRow key={fighter.fighter_id}>
                        <TableCell>{fighter.name}</TableCell>
                        <TableCell>{fighter.weight_class}</TableCell>
                        <TableCell>
                          <Chip label={fighter.tier} size="small" />
                        </TableCell>
                        <TableCell>{fighter.points}</TableCell>
                        <TableCell>
                          {fighter.wins}W - {fighter.losses}L - {fighter.draws}D
                        </TableCell>
                        <TableCell>
                          <Chip 
                            label={fighter.consecutive_losses} 
                            color="error" 
                            size="small" 
                          />
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        )}

        {/* All Fighters Table */}
        <Card variant="outlined">
          <CardContent>
            <Typography variant="h6" gutterBottom>
              All Fighters Statistics
            </Typography>
            <TableContainer component={Paper} sx={{ maxHeight: 600 }}>
              <Table stickyHeader size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Fighter</TableCell>
                    <TableCell>Weight Class</TableCell>
                    <TableCell>Tier</TableCell>
                    <TableCell align="right">Points</TableCell>
                    <TableCell align="right">Rank</TableCell>
                    <TableCell align="right">Wins</TableCell>
                    <TableCell align="right">Losses</TableCell>
                    <TableCell align="right">KOs</TableCell>
                    <TableCell align="right">Matches</TableCell>
                    <TableCell align="right">Win %</TableCell>
                    <TableCell align="right">KO %</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {allFightersAnalytics
                    .sort((a, b) => (b.points || 0) - (a.points || 0))
                    .map((fighter) => (
                      <TableRow key={fighter.fighter_id}>
                        <TableCell>{fighter.name}</TableCell>
                        <TableCell>{fighter.weight_class}</TableCell>
                        <TableCell>
                          <Chip label={fighter.tier} size="small" />
                        </TableCell>
                        <TableCell align="right">{fighter.points}</TableCell>
                        <TableCell align="right">#{fighter.rank_overall}</TableCell>
                        <TableCell align="right">{fighter.wins}</TableCell>
                        <TableCell align="right">{fighter.losses}</TableCell>
                        <TableCell align="right">{fighter.knockouts}</TableCell>
                        <TableCell align="right">{fighter.total_matches}</TableCell>
                        <TableCell align="right">{fighter.win_percentage.toFixed(1)}%</TableCell>
                        <TableCell align="right">{fighter.ko_percentage.toFixed(1)}%</TableCell>
                      </TableRow>
                    ))}
                </TableBody>
              </Table>
            </TableContainer>
          </CardContent>
        </Card>
      </CardContent>
    </Card>
  );
};

export default AdminAnalytics;

