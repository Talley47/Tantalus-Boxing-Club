import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  Paper,
  CircularProgress,
  Alert
} from '@mui/material';
import {
  LineChart,
  Line,
  AreaChart,
  Area,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer
} from 'recharts';
import { AnalyticsService } from '../../services/analyticsService';
import { TournamentService } from '../../services/tournamentService';
import { supabase, TABLES } from '../../services/supabase';
// Import Logo1.png
import logo1 from '../../Logo1.png';

interface AnalyticsData {
  totalFighters: number;
  totalFights: number;
  totalTournaments: number;
  activeUsers: number;
  fightTrends: Array<{
    date: string;
    fights: number;
    wins: number;
  }>;
  tierDistribution: Array<{
    tier: string;
    count: number;
    percentage: number;
  }>;
  weightClassStats: Array<{
    weightClass: string;
    fighters: number;
    avgPoints: number;
  }>;
  monthlyStats: Array<{
    month: string;
    registrations: number;
    fights: number;
    tournaments: number;
  }>;
}

const AnalyticsDashboard: React.FC = () => {
  const [data, setData] = useState<AnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadAnalyticsData();
  }, []);

  const loadAnalyticsData = async () => {
    try {
      setLoading(true);
      setError(null);

      // Get league analytics from service
      const leagueData = await AnalyticsService.getLeagueAnalytics();

      // Get tournaments
      const tournaments = await TournamentService.getTournaments();
      const totalTournaments = tournaments?.length || 0;

      // Get fight records for trends
      const sixMonthsAgo = new Date();
      sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
      
      const { data: fightRecords } = await supabase
        .from(TABLES.FIGHT_RECORDS)
        .select('date, result')
        .gte('date', sixMonthsAgo.toISOString().split('T')[0])
        .order('date', { ascending: true });

      // Process fight trends by month
      const fightTrendsMap = new Map<string, { fights: number; wins: number }>();
      fightRecords?.forEach(record => {
        const month = new Date(record.date).toISOString().slice(0, 7); // YYYY-MM
        const current = fightTrendsMap.get(month) || { fights: 0, wins: 0 };
        current.fights += 1;
        if (record.result === 'Win') {
          current.wins += 1;
        }
        fightTrendsMap.set(month, current);
      });

      const fightTrends = Array.from(fightTrendsMap.entries())
        .map(([date, stats]) => ({ date, ...stats }))
        .sort((a, b) => a.date.localeCompare(b.date))
        .slice(-6); // Last 6 months

      // Process tier distribution
      const tierCounts = leagueData.fighters_by_tier || {};
      const totalFighters = leagueData.total_fighters || 0;
      const tierDistribution = Object.entries(tierCounts).map(([tier, count]) => ({
        tier,
        count: count as number,
        percentage: totalFighters > 0 ? Math.round(((count as number) / totalFighters) * 100 * 10) / 10 : 0
      })).sort((a, b) => b.count - a.count);

      // Process weight class stats
      const weightClassStats = Object.entries(leagueData.fighters_by_weight_class || {}).map(([weightClass, count]) => ({
        weightClass,
        fighters: count as number,
        avgPoints: Math.round(leagueData.average_points_by_weight_class[weightClass] || 0)
      }));

      // Get monthly stats (last 6 months)
      const monthlyStatsMap = new Map<string, { registrations: number; fights: number; tournaments: number }>();
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      
      for (let i = 5; i >= 0; i--) {
        const date = new Date();
        date.setMonth(date.getMonth() - i);
        const monthKey = monthNames[date.getMonth()];
        monthlyStatsMap.set(monthKey, { registrations: 0, fights: 0, tournaments: 0 });
      }

      // Count fights per month
      fightRecords?.forEach(record => {
        const date = new Date(record.date);
        const monthKey = monthNames[date.getMonth()];
        const current = monthlyStatsMap.get(monthKey);
        if (current) {
          current.fights += 1;
        }
      });

      // Count registrations (fighter profiles created in last 6 months)
      const { data: recentProfiles } = await supabase
        .from(TABLES.FIGHTER_PROFILES)
        .select('created_at')
        .gte('created_at', sixMonthsAgo.toISOString());

      recentProfiles?.forEach(profile => {
        const date = new Date(profile.created_at);
        const monthKey = monthNames[date.getMonth()];
        const current = monthlyStatsMap.get(monthKey);
        if (current) {
          current.registrations += 1;
        }
      });

      const monthlyStats = Array.from(monthlyStatsMap.entries())
        .map(([month, stats]) => ({ month, ...stats }));

      const analyticsData: AnalyticsData = {
        totalFighters: leagueData.total_fighters || 0,
        totalFights: leagueData.total_matches || 0,
        totalTournaments,
        activeUsers: leagueData.active_fighters || 0,
        fightTrends: fightTrends.length > 0 ? fightTrends : [
          { date: new Date().toISOString().slice(0, 7), fights: 0, wins: 0 }
        ],
        tierDistribution: tierDistribution.length > 0 ? tierDistribution : [],
        weightClassStats: weightClassStats.length > 0 ? weightClassStats : [],
        monthlyStats: monthlyStats.length > 0 ? monthlyStats : [
          { month: monthNames[new Date().getMonth()], registrations: 0, fights: 0, tournaments: 0 }
        ]
      };

      setData(analyticsData);
    } catch (err) {
      setError('Failed to load analytics data');
      console.error('Error loading analytics:', err);
      setData(null);
    } finally {
      setLoading(false);
    }
  };

  const COLORS = ['#d32f2f', '#ff9800', '#4caf50', '#2196f3'];

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="error">{error}</Alert>
      </Box>
    );
  }

  if (!data) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="info">No analytics data available</Alert>
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
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
        <Typography variant="h4" gutterBottom sx={{ mb: 0 }}>
          Analytics Dashboard
        </Typography>
      </Box>

      {/* Key Metrics */}
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: 'repeat(2, 1fr)', md: 'repeat(4, 1fr)' }, gap: 2, mb: 3 }}>
        <Card>
          <CardContent>
            <Typography color="textSecondary" gutterBottom>
              Total Fighters
            </Typography>
            <Typography variant="h4">
              {data.totalFighters}
            </Typography>
          </CardContent>
        </Card>
        <Card>
          <CardContent>
            <Typography color="textSecondary" gutterBottom>
              Total Fights
            </Typography>
            <Typography variant="h4">
              {data.totalFights}
            </Typography>
          </CardContent>
        </Card>
        <Card>
          <CardContent>
            <Typography color="textSecondary" gutterBottom>
              Tournaments
            </Typography>
            <Typography variant="h4">
              {data.totalTournaments}
            </Typography>
          </CardContent>
        </Card>
        <Card>
          <CardContent>
            <Typography color="textSecondary" gutterBottom>
              Active Users
            </Typography>
            <Typography variant="h4">
              {data.activeUsers}
            </Typography>
          </CardContent>
        </Card>
      </Box>

      {/* Charts */}
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', lg: 'repeat(2, 1fr)' }, gap: 3, mb: 3 }}>
        {/* Fight Trends */}
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Fight Trends
            </Typography>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={data.fightTrends}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="fights" stroke="#d32f2f" strokeWidth={2} />
                <Line type="monotone" dataKey="wins" stroke="#4caf50" strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Tier Distribution */}
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Tier Distribution
            </Typography>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={data.tierDistribution}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={(entry: any) => `${entry.tier}: ${entry.percentage}%`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="count"
                >
                  {data.tierDistribution.map((_, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </Box>

      {/* Weight Class Stats */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Weight Class Statistics
          </Typography>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={data.weightClassStats}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="weightClass" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Bar dataKey="fighters" fill="#d32f2f" />
              <Bar dataKey="avgPoints" fill="#ff9800" />
            </BarChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      {/* Monthly Activity */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Monthly Activity
          </Typography>
          <ResponsiveContainer width="100%" height={300}>
            <AreaChart data={data.monthlyStats}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Area type="monotone" dataKey="registrations" stackId="1" stroke="#d32f2f" fill="#d32f2f" />
              <Area type="monotone" dataKey="fights" stackId="1" stroke="#ff9800" fill="#ff9800" />
              <Area type="monotone" dataKey="tournaments" stackId="1" stroke="#4caf50" fill="#4caf50" />
            </AreaChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>
    </Box>
  );
};

export default AnalyticsDashboard;