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
  Chip,
  Avatar,
  Alert,
  CircularProgress,
} from '@mui/material';
import {
  EmojiEvents,
  TrendingUp,
  Person,
} from '@mui/icons-material';
import { TournamentService, Tournament, TournamentResult, TournamentParticipant } from '../../services/tournamentService';

interface TournamentResultsProps {
  tournamentId?: string;
}

const TournamentResults: React.FC<TournamentResultsProps> = ({ tournamentId }) => {
  const [completedTournaments, setCompletedTournaments] = useState<Tournament[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedTournament, setSelectedTournament] = useState<Tournament | null>(null);
  const [tournamentResult, setTournamentResult] = useState<TournamentResult | null>(null);
  const [participants, setParticipants] = useState<TournamentParticipant[]>([]);
  const [champions, setChampions] = useState<any[]>([]);
  const [mostWins, setMostWins] = useState<any[]>([]);

  useEffect(() => {
    loadCompletedTournaments();
    loadChampions();
    loadMostWins();
  }, []);

  useEffect(() => {
    if (tournamentId) {
      loadTournamentDetails(tournamentId);
    } else if (selectedTournament) {
      loadTournamentDetails(selectedTournament.id);
    }
  }, [tournamentId, selectedTournament]);

  const loadCompletedTournaments = async () => {
    try {
      setLoading(true);
      const data = await TournamentService.getTournaments('Completed');
      setCompletedTournaments(data);
      if (data.length > 0 && !selectedTournament) {
        setSelectedTournament(data[0]);
      }
    } catch (error) {
      console.error('Error loading tournaments:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadTournamentDetails = async (id: string) => {
    try {
      const [result, parts] = await Promise.all([
        TournamentService.getTournamentResults(id),
        TournamentService.getTournamentParticipants(id),
      ]);
      setTournamentResult(result);
      setParticipants(parts);
    } catch (error) {
      console.error('Error loading tournament details:', error);
    }
  };

  const loadChampions = async () => {
    try {
      const data = await TournamentService.getTournamentChampions();
      setChampions(data);
    } catch (error) {
      console.error('Error loading champions:', error);
    }
  };

  const loadMostWins = async () => {
    try {
      // This would need a service method to get tournament win statistics
      // For now, we'll aggregate from champions
      const champData = await TournamentService.getTournamentChampions();
      const winsMap: { [fighterId: string]: { fighter: any; wins: number; weightClasses: string[] } } = {};

      champData.forEach((champ: any) => {
        if (!winsMap[champ.fighter_id]) {
          winsMap[champ.fighter_id] = {
            fighter: champ.fighter,
            wins: 0,
            weightClasses: [],
          };
        }
        winsMap[champ.fighter_id].wins++;
        if (!winsMap[champ.fighter_id].weightClasses.includes(champ.weight_class)) {
          winsMap[champ.fighter_id].weightClasses.push(champ.weight_class);
        }
      });

      const sorted = Object.values(winsMap)
        .sort((a, b) => b.wins - a.wins)
        .slice(0, 10);

      setMostWins(sorted);
    } catch (error) {
      console.error('Error loading most wins:', error);
    }
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Tournament Results
      </Typography>

      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 2fr' }, gap: 3 }}>
        {/* Completed Tournaments List */}
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Completed Tournaments
            </Typography>
            {loading ? (
              <Box display="flex" justifyContent="center" p={4}>
                <CircularProgress />
              </Box>
            ) : completedTournaments.length === 0 ? (
              <Alert severity="info">No completed tournaments</Alert>
            ) : (
              <Box sx={{ maxHeight: 400, overflowY: 'auto' }}>
                {completedTournaments.map((tournament) => (
                  <Card
                    key={tournament.id}
                    sx={{
                      mb: 1,
                      cursor: 'pointer',
                      border: selectedTournament?.id === tournament.id ? '2px solid' : '1px solid',
                      borderColor: selectedTournament?.id === tournament.id ? 'primary.main' : 'divider',
                    }}
                    onClick={() => setSelectedTournament(tournament)}
                  >
                    <CardContent sx={{ p: 2 }}>
                      <Typography variant="subtitle1" fontWeight="bold">
                        {tournament.name}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {tournament.weight_class} • {new Date(tournament.end_date).toLocaleDateString()}
                      </Typography>
                    </CardContent>
                  </Card>
                ))}
              </Box>
            )}
          </CardContent>
        </Card>

        {/* Tournament Details */}
        <Box>
          {selectedTournament ? (
            <>
              {/* Tournament Winner/Champion */}
              {tournamentResult && (
                <Card sx={{ mb: 2, backgroundColor: 'success.light' }}>
                  <CardContent>
                    <Box display="flex" alignItems="center" gap={2}>
                      <Avatar sx={{ width: 60, height: 60, bgcolor: 'warning.main' }}>
                        <EmojiEvents sx={{ fontSize: 40 }} />
                      </Avatar>
                      <Box>
                        <Typography variant="h6">Tournament Champion</Typography>
                        <Typography variant="h5" fontWeight="bold">
                          {tournamentResult.champion_name || 'TBD'}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          {selectedTournament.name} • {selectedTournament.weight_class}
                        </Typography>
                      </Box>
                    </Box>
                  </CardContent>
                </Card>
              )}

              {/* Tournament Standings */}
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Tournament Participants
                  </Typography>
                  {participants.length === 0 ? (
                    <Alert severity="info">No participants found</Alert>
                  ) : (
                    <TableContainer>
                      <Table>
                        <TableHead>
                          <TableRow>
                            <TableCell>Rank</TableCell>
                            <TableCell>Fighter</TableCell>
                            <TableCell>Tier</TableCell>
                            <TableCell>Points</TableCell>
                            <TableCell>Status</TableCell>
                          </TableRow>
                        </TableHead>
                        <TableBody>
                          {participants.map((participant, index) => (
                            <TableRow key={participant.id}>
                              <TableCell>{index + 1}</TableCell>
                              <TableCell>
                                <Box display="flex" alignItems="center" gap={1}>
                                  <Avatar sx={{ width: 32, height: 32 }}>
                                    {participant.fighter_name?.charAt(0)}
                                  </Avatar>
                                  <Typography>{participant.fighter_name}</Typography>
                                </Box>
                              </TableCell>
                              <TableCell>
                                <Chip label={participant.fighter_tier} size="small" />
                              </TableCell>
                              <TableCell>{participant.fighter_points || 0}</TableCell>
                              <TableCell>
                                <Chip
                                  label={participant.status}
                                  size="small"
                                  color={
                                    participant.status === 'Active' ? 'success' :
                                    participant.status === 'Eliminated' ? 'error' : 'default'
                                  }
                                />
                              </TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </TableContainer>
                  )}
                </CardContent>
              </Card>
            </>
          ) : (
            <Alert severity="info">Select a tournament to view results</Alert>
          )}
        </Box>
      </Box>

      {/* Champions & Statistics */}
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 3, mt: 2 }}>
        {/* All Tournament Champions */}
        <Box>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Tournament Champions
              </Typography>
              {champions.length === 0 ? (
                <Alert severity="info">No champions yet</Alert>
              ) : (
                <Box sx={{ maxHeight: 300, overflowY: 'auto' }}>
                  {champions.map((champ: any) => (
                    <Card key={champ.id} variant="outlined" sx={{ mb: 1 }}>
                      <CardContent sx={{ p: 2 }}>
                        <Box display="flex" alignItems="center" gap={2}>
                          <Avatar sx={{ bgcolor: 'warning.main' }}>
                            <EmojiEvents />
                          </Avatar>
                          <Box>
                            <Typography variant="subtitle1" fontWeight="bold">
                              {champ.fighter?.name || 'Unknown'}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              {champ.belt_name} • {champ.weight_class}
                            </Typography>
                          </Box>
                        </Box>
                      </CardContent>
                    </Card>
                  ))}
                </Box>
              )}
            </CardContent>
          </Card>
        </Box>

        {/* Most Tournament Wins */}
        <Box>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Most Tournament Wins
              </Typography>
              {mostWins.length === 0 ? (
                <Alert severity="info">No tournament wins recorded</Alert>
              ) : (
                <TableContainer>
                  <Table size="small">
                    <TableHead>
                      <TableRow>
                        <TableCell>Rank</TableCell>
                        <TableCell>Fighter</TableCell>
                        <TableCell>Wins</TableCell>
                        <TableCell>Weight Classes</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {mostWins.map((entry, index) => (
                        <TableRow key={entry.fighter?.id || index}>
                          <TableCell>
                            {index === 0 && <TrendingUp color="warning" />} {index + 1}
                          </TableCell>
                          <TableCell>{entry.fighter?.name || 'Unknown'}</TableCell>
                          <TableCell>
                            <Chip label={entry.wins} color="warning" size="small" />
                          </TableCell>
                          <TableCell>
                            {entry.weightClasses.join(', ')}
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>
              )}
            </CardContent>
          </Card>
        </Box>
      </Box>
    </Box>
  );
};

export default TournamentResults;

