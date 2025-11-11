import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Avatar,
  Chip,
  Alert,
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  ListItemSecondaryAction,
  Divider,
  IconButton,
  Tabs,
  Tab,
  CircularProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Tooltip,
} from '@mui/material';
import {
  EmojiEvents,
  CalendarToday,
  People,
  TrendingUp,
  CheckCircle,
  Error as ErrorIcon,
  SportsMma,
  Lock,
  OpenInNew,
} from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';
import { TournamentService, Tournament, TournamentBracket } from '../../services/tournamentService';
import TournamentBracketView from './TournamentBracketView';
import TournamentResults from './TournamentResults';
import { useRealtime } from '../../contexts/RealtimeContext';
import { useNavigate } from 'react-router-dom';
// Import Logo1.png
import logo1 from '../../Logo1.png';
// Import KOTH Tournament.png background image
import tournamentBackground from '../../KOTH Tournament.png';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;
  return (
    <div role="tabpanel" hidden={value !== index} id={`tournament-tabpanel-${index}`} {...other}>
      {value === index && <Box sx={{ p: 3 }}>{children}</Box>}
    </div>
  );
}

const Tournaments: React.FC = () => {
  const { fighterProfile } = useAuth();
  const navigate = useNavigate();
  const [tournaments, setTournaments] = useState<Tournament[]>([]);
  const [loading, setLoading] = useState(false);
  const [tabValue, setTabValue] = useState(0);
  const [selectedTournament, setSelectedTournament] = useState<Tournament | null>(null);
  const [bracketDialogOpen, setBracketDialogOpen] = useState(false);
  const [brackets, setBrackets] = useState<TournamentBracket[]>([]);
  const [joiningTournament, setJoiningTournament] = useState<string | null>(null);
  const [joinError, setJoinError] = useState<string | null>(null);

  const { subscribeToFightRecords } = useRealtime();

  const loadTournaments = async () => {
    try {
      setLoading(true);
      const statusMap: { [key: number]: 'Open' | 'In Progress' | 'Completed' } = {
        0: 'Open',
        1: 'In Progress',
        2: 'Completed',
      };
      const status = statusMap[tabValue];
      const data = await TournamentService.getTournaments(status);
      setTournaments(data);
    } catch (error) {
      console.error('Error loading tournaments:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadTournaments();
  }, [tabValue]);

  // Real-time updates
  useEffect(() => {
    const unsubscribe = subscribeToFightRecords(() => {
      loadTournaments();
      if (selectedTournament) {
        loadBrackets(selectedTournament.id);
      }
    });

    return () => {
      unsubscribe();
    };
  }, [selectedTournament]);

  const loadBrackets = async (tournamentId: string) => {
    try {
      const data = await TournamentService.getTournamentBrackets(tournamentId);
      setBrackets(data);
    } catch (error) {
      console.error('Error loading brackets:', error);
    }
  };

  const handleJoinTournament = async (tournamentId: string) => {
    if (!fighterProfile) {
      setJoinError('Please log in to join tournaments');
      return;
    }

    try {
      setJoiningTournament(tournamentId);
      setJoinError(null);
      await TournamentService.joinTournament(fighterProfile.id, tournamentId);
      await loadTournaments();
      alert('Successfully joined tournament!');
    } catch (error: any) {
      setJoinError(error.message || 'Failed to join tournament');
    } finally {
      setJoiningTournament(null);
    }
  };

  const handleViewBracket = async (tournament: Tournament) => {
    setSelectedTournament(tournament);
    await loadBrackets(tournament.id);
    setBracketDialogOpen(true);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Open': return 'success';
      case 'In Progress': return 'warning';
      case 'Completed': return 'info';
      case 'Cancelled': return 'error';
      default: return 'default';
    }
  };

  const getFormatText = (format: string) => {
    return format.replace(/([A-Z])/g, ' $1').trim();
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const formatDateTime = (dateString: string) => {
    return new Date(dateString).toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    });
  };

  return (
    <>
      {/* Full-screen background layer with KOTH Tournament.png */}
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
          backgroundImage: tournamentBackground ? `url("${tournamentBackground}")` : 'url("/KOTH Tournament.png")',
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          backgroundRepeat: 'no-repeat',
          backgroundAttachment: 'fixed',
          zIndex: -1,
          display: 'block',
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
          '& .MuiCard-root': {
            backgroundColor: 'rgba(255, 255, 255, 0.92)',
            backdropFilter: 'blur(5px)',
          },
          '& .MuiAlert-root': {
            backgroundColor: 'rgba(255, 255, 255, 0.92)',
            backdropFilter: 'blur(5px)',
          },
        }}
      >
        <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
          <Box display="flex" alignItems="center" gap={2}>
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
            <Box>
              <Typography 
                variant="h4" 
                gutterBottom 
                sx={{ 
                  fontWeight: 'bold',
                  color: 'white',
                  textShadow: '2px 2px 4px rgba(0,0,0,0.8)',
                }}
              >
                Tournaments
              </Typography>
              <Typography 
                variant="body1" 
                sx={{ 
                  color: 'white',
                  textShadow: '1px 1px 2px rgba(0,0,0,0.8)',
                }}
              >
                Compete in tournaments and climb the rankings
              </Typography>
            </Box>
          </Box>
        </Box>

      {joinError && (
        <Alert severity="error" onClose={() => setJoinError(null)} sx={{ mb: 2 }}>
          {joinError}
        </Alert>
      )}

      <Card>
        <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tabs value={tabValue} onChange={(e, newValue) => setTabValue(newValue)}>
            <Tab label="Upcoming & Open" />
            <Tab label="In Progress" />
            <Tab label="Completed" />
            <Tab label="Results & Champions" />
          </Tabs>
        </Box>

        <TabPanel value={tabValue} index={0}>
          <Typography variant="h6" gutterBottom>
            Open Tournaments
          </Typography>
          {loading ? (
            <Box display="flex" justifyContent="center" p={4}>
              <CircularProgress />
            </Box>
          ) : tournaments.length === 0 ? (
            <Alert severity="info">No open tournaments available</Alert>
          ) : (
            <List>
              {tournaments.map((tournament) => (
                <React.Fragment key={tournament.id}>
                  <ListItem>
                    <ListItemAvatar>
                      <Avatar sx={{ bgcolor: 'primary.main' }}>
                        <EmojiEvents />
                      </Avatar>
                    </ListItemAvatar>
                    <ListItemText
                      primary={
                        <Box display="flex" alignItems="center" gap={1} flexWrap="wrap">
                          <Typography variant="subtitle1" fontWeight="bold">
                            {tournament.name}
                          </Typography>
                          <Chip label={tournament.status} size="small" color={getStatusColor(tournament.status) as any} />
                          {tournament.min_tier && (
                            <Chip label={`Min: ${tournament.min_tier}`} size="small" variant="outlined" />
                          )}
                        </Box>
                      }
                      secondary={
                        <>
                          {tournament.description && (
                            <Typography variant="body2" color="text.secondary" component="span" display="block" sx={{ mb: 1 }}>
                              {tournament.description}
                            </Typography>
                          )}
                          <Box display="flex" alignItems="center" gap={2} mb={1} flexWrap="wrap" component="span">
                            <Box display="flex" alignItems="center" gap={0.5} component="span">
                              <CalendarToday fontSize="small" />
                              <Typography variant="body2" component="span">
                                Start: {formatDate(tournament.start_date)}
                              </Typography>
                              {tournament.registration_deadline && (
                                <Typography variant="body2" color="error" component="span">
                                  {' • '}Deadline: {formatDateTime(tournament.registration_deadline)}
                                </Typography>
                              )}
                            </Box>
                            <Box display="flex" alignItems="center" gap={0.5} component="span">
                              <People fontSize="small" />
                              <Typography variant="body2" component="span">
                                {tournament.current_participants || 0}/{tournament.max_participants} participants
                              </Typography>
                            </Box>
                          </Box>
                          <Typography variant="body2" color="text.secondary" component="span" display="block">
                            {tournament.weight_class} • {getFormatText(tournament.format)} • 
                            Prize Pool: ${tournament.prize_pool} • Entry Fee: ${tournament.entry_fee || 'Free'}
                          </Typography>
                        </>
                      }
                      secondaryTypographyProps={{ component: 'div' }}
                    />
                    <ListItemSecondaryAction>
                      <Button
                        variant="contained"
                        size="small"
                        startIcon={<EmojiEvents />}
                        onClick={(e) => {
                          e.currentTarget.blur(); // Remove focus from button before opening dialog/action
                          handleJoinTournament(tournament.id);
                        }}
                        disabled={!!joiningTournament}
                      >
                        {joiningTournament === tournament.id ? 'Joining...' : 'Join'}
                      </Button>
                    </ListItemSecondaryAction>
                  </ListItem>
                  <Divider />
                </React.Fragment>
              ))}
            </List>
          )}
        </TabPanel>

        <TabPanel value={tabValue} index={1}>
          <Typography variant="h6" gutterBottom>
            Active Tournaments
          </Typography>
          {loading ? (
            <Box display="flex" justifyContent="center" p={4}>
              <CircularProgress />
            </Box>
          ) : tournaments.length === 0 ? (
            <Alert severity="info">No active tournaments</Alert>
          ) : (
            <List>
              {tournaments.map((tournament) => (
                <React.Fragment key={tournament.id}>
                  <ListItem>
                    <ListItemAvatar>
                      <Avatar sx={{ bgcolor: 'warning.main' }}>
                        <TrendingUp />
                      </Avatar>
                    </ListItemAvatar>
                    <ListItemText
                      primary={
                        <Box display="flex" alignItems="center" gap={1}>
                          <Typography variant="subtitle1" fontWeight="bold">
                            {tournament.name}
                          </Typography>
                          <Chip label={tournament.status} size="small" color={getStatusColor(tournament.status) as any} />
                        </Box>
                      }
                      secondary={
                        <Box>
                          <Typography variant="body2" color="text.secondary">
                            {tournament.description}
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            {tournament.weight_class} • {getFormatText(tournament.format)} • 
                            {tournament.current_participants} participants
                          </Typography>
                        </Box>
                      }
                    />
                    <ListItemSecondaryAction>
                      <Button
                        variant="outlined"
                        size="small"
                        startIcon={<SportsMma />}
                        onClick={(e) => {
                          e.currentTarget.blur(); // Remove focus from button before opening dialog
                          handleViewBracket(tournament);
                        }}
                      >
                        View Bracket
                      </Button>
                    </ListItemSecondaryAction>
                  </ListItem>
                  <Divider />
                </React.Fragment>
              ))}
            </List>
          )}
        </TabPanel>

        <TabPanel value={tabValue} index={2}>
          <Typography variant="h6" gutterBottom>
            Completed Tournaments
          </Typography>
          {loading ? (
            <Box display="flex" justifyContent="center" p={4}>
              <CircularProgress />
            </Box>
          ) : tournaments.length === 0 ? (
            <Alert severity="info">No completed tournaments</Alert>
          ) : (
            <List>
              {tournaments.map((tournament) => (
                <React.Fragment key={tournament.id}>
                  <ListItem>
                    <ListItemAvatar>
                      <Avatar sx={{ bgcolor: 'success.main' }}>
                        <CheckCircle />
                      </Avatar>
                    </ListItemAvatar>
                    <ListItemText
                      primary={
                        <Box display="flex" alignItems="center" gap={1}>
                          <Typography variant="subtitle1" fontWeight="bold">
                            {tournament.name}
                          </Typography>
                          <Chip label={tournament.status} size="small" color={getStatusColor(tournament.status) as any} />
                          {tournament.winner_id && (
                            <Chip 
                              label="Champion" 
                              size="small" 
                              color="warning" 
                              icon={<EmojiEvents />}
                            />
                          )}
                        </Box>
                      }
                      secondary={
                        <Box>
                          <Typography variant="body2" color="text.secondary">
                            {tournament.description}
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            {tournament.weight_class} • {getFormatText(tournament.format)} • 
                            Completed: {formatDate(tournament.end_date)}
                          </Typography>
                        </Box>
                      }
                      secondaryTypographyProps={{ component: 'div' }}
                    />
                    <ListItemSecondaryAction>
                      <Button
                        variant="outlined"
                        size="small"
                        startIcon={<EmojiEvents />}
                        onClick={(e) => {
                          e.currentTarget.blur(); // Remove focus from button before opening dialog
                          handleViewBracket(tournament);
                        }}
                      >
                        View Results
                      </Button>
                    </ListItemSecondaryAction>
                  </ListItem>
                  <Divider />
                </React.Fragment>
              ))}
            </List>
          )}
        </TabPanel>

        <TabPanel value={tabValue} index={3}>
          <TournamentResults />
        </TabPanel>
      </Card>

      {/* Bracket/Results Dialog */}
      <Dialog 
        open={bracketDialogOpen} 
        onClose={() => setBracketDialogOpen(false)} 
        maxWidth="lg" 
        fullWidth
        keepMounted={false}
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
      >
        <DialogTitle>
          {selectedTournament?.name}
          {selectedTournament?.winner_id && (
            <Chip label="Champion" color="warning" icon={<EmojiEvents />} sx={{ ml: 2 }} />
          )}
        </DialogTitle>
        <DialogContent>
          {selectedTournament && (
            <TournamentBracketView
              tournament={selectedTournament}
              brackets={brackets}
              onBracketUpdate={() => loadBrackets(selectedTournament.id)}
            />
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setBracketDialogOpen(false)}>Close</Button>
        </DialogActions>
        </Dialog>
      </Box>
    </>
  );
};

export default Tournaments;
