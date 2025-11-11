import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Chip,
  Avatar,
  Tooltip,
  Button,
  Alert,
} from '@mui/material';
import {
  SportsMma,
  EmojiEvents,
  Person,
  CheckCircle,
  Schedule,
} from '@mui/icons-material';
import { Tournament, TournamentBracket } from '../../services/tournamentService';
import { TournamentService } from '../../services/tournamentService';
import { useAuth } from '../../contexts/AuthContext';

interface TournamentBracketViewProps {
  tournament: Tournament;
  brackets: TournamentBracket[];
  onBracketUpdate?: () => void;
}

const TournamentBracketView: React.FC<TournamentBracketViewProps> = ({
  tournament,
  brackets,
  onBracketUpdate,
}) => {
  const { fighterProfile } = useAuth();
  const [loading, setLoading] = useState(false);

  // Organize brackets by round
  const bracketsByRound: { [round: number]: TournamentBracket[] } = {};
  brackets.forEach((bracket) => {
    if (!bracketsByRound[bracket.round]) {
      bracketsByRound[bracket.round] = [];
    }
    bracketsByRound[bracket.round].push(bracket);
  });

  const rounds = Object.keys(bracketsByRound)
    .map(Number)
    .sort((a, b) => a - b);

  const handleCheckIn = async (bracketId: string) => {
    if (!fighterProfile) return;

    try {
      setLoading(true);
      await TournamentService.checkIn(bracketId, fighterProfile.id);
      if (onBracketUpdate) onBracketUpdate();
    } catch (error: any) {
      alert(error.message || 'Failed to check in');
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Completed': return 'success';
      case 'Scheduled': return 'info';
      case 'In Progress': return 'warning';
      case 'Bye': return 'default';
      case 'No Show': return 'error';
      default: return 'default';
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    });
  };

  const isDeadlinePassed = (deadline: string) => {
    return new Date() > new Date(deadline);
  };

  const canCheckIn = (bracket: TournamentBracket) => {
    if (!fighterProfile) return false;
    if (bracket.status !== 'Pending' && bracket.status !== 'Scheduled') return false;
    if (bracket.fighter1_id !== fighterProfile.id && bracket.fighter2_id !== fighterProfile.id) return false;
    
    const alreadyCheckedIn = 
      (bracket.fighter1_id === fighterProfile.id && bracket.fighter1_check_in) ||
      (bracket.fighter2_id === fighterProfile.id && bracket.fighter2_check_in);
    
    return !alreadyCheckedIn;
  };

  const RenderMatch = ({ bracket }: { bracket: TournamentBracket }) => {
    const isFighter1 = fighterProfile && bracket.fighter1_id === fighterProfile.id;
    const isFighter2 = fighterProfile && bracket.fighter2_id === fighterProfile.id;
    const isFighterMatch = isFighter1 || isFighter2;

    return (
      <Card
        sx={{
          mb: 2,
          border: isFighterMatch ? '2px solid' : '1px solid',
          borderColor: isFighterMatch ? 'primary.main' : 'divider',
          backgroundColor: bracket.status === 'Completed' ? 'action.selected' : 'background.paper',
        }}
      >
        <CardContent>
          <Box display="flex" justifyContent="space-between" alignItems="center" mb={1}>
            <Chip
              label={`Round ${bracket.round} - Match ${bracket.match_number}`}
              size="small"
              color="primary"
            />
            <Chip
              label={bracket.status}
              size="small"
              color={getStatusColor(bracket.status) as any}
            />
          </Box>

          {/* Fighter 1 */}
          <Box
            sx={{
              p: 1,
              mb: 1,
              borderRadius: 1,
              backgroundColor: bracket.winner_id === bracket.fighter1_id ? 'success.light' : 'background.default',
              border: isFighter1 ? '2px solid' : 'none',
              borderColor: 'primary.main',
            }}
          >
            <Box display="flex" justifyContent="space-between" alignItems="center">
              <Box display="flex" alignItems="center" gap={1}>
                <Avatar sx={{ width: 32, height: 32 }}>
                  {bracket.fighter1_id ? bracket.fighter1_name?.charAt(0) : '?'}
                </Avatar>
                <Typography variant="body2" fontWeight={bracket.winner_id === bracket.fighter1_id ? 'bold' : 'normal'}>
                  {bracket.fighter1_name || 'TBD'}
                </Typography>
                {bracket.winner_id === bracket.fighter1_id && (
                  <EmojiEvents fontSize="small" color="warning" />
                )}
              </Box>
              {bracket.fighter1_check_in && (
                <CheckCircle fontSize="small" color="success" />
              )}
              {canCheckIn(bracket) && isFighter1 && (
                <Button
                  size="small"
                  variant="outlined"
                  onClick={() => handleCheckIn(bracket.id)}
                  disabled={loading}
                >
                  Check In
                </Button>
              )}
            </Box>
          </Box>

          {/* VS */}
          <Box textAlign="center" my={0.5}>
            <Typography variant="caption" color="text.secondary">
              VS
            </Typography>
          </Box>

          {/* Fighter 2 */}
          {bracket.fighter2_id ? (
            <Box
              sx={{
                p: 1,
                borderRadius: 1,
                backgroundColor: bracket.winner_id === bracket.fighter2_id ? 'success.light' : 'background.default',
                border: isFighter2 ? '2px solid' : 'none',
                borderColor: 'primary.main',
              }}
            >
              <Box display="flex" justifyContent="space-between" alignItems="center">
                <Box display="flex" alignItems="center" gap={1}>
                  <Avatar sx={{ width: 32, height: 32 }}>
                    {bracket.fighter2_name?.charAt(0)}
                  </Avatar>
                  <Typography variant="body2" fontWeight={bracket.winner_id === bracket.fighter2_id ? 'bold' : 'normal'}>
                    {bracket.fighter2_name || 'TBD'}
                  </Typography>
                  {bracket.winner_id === bracket.fighter2_id && (
                    <EmojiEvents fontSize="small" color="warning" />
                  )}
                </Box>
                {bracket.fighter2_check_in && (
                  <CheckCircle fontSize="small" color="success" />
                )}
                {canCheckIn(bracket) && isFighter2 && (
                  <Button
                    size="small"
                    variant="outlined"
                    onClick={() => handleCheckIn(bracket.id)}
                    disabled={loading}
                  >
                    Check In
                  </Button>
                )}
              </Box>
            </Box>
          ) : (
            <Box
              sx={{
                p: 1,
                borderRadius: 1,
                backgroundColor: 'action.hover',
              }}
            >
              <Typography variant="body2" color="text.secondary" fontStyle="italic">
                BYE
              </Typography>
            </Box>
          )}

          {/* Match Info */}
          <Box mt={2} pt={1} borderTop="1px solid" borderColor="divider">
            {bracket.scheduled_date && (
              <Box display="flex" alignItems="center" gap={0.5} mb={0.5}>
                <Schedule fontSize="small" />
                <Typography variant="caption" color="text.secondary">
                  Scheduled: {formatDate(bracket.scheduled_date)}
                </Typography>
              </Box>
            )}
            <Box display="flex" alignItems="center" gap={0.5}>
              <Schedule fontSize="small" />
              <Typography
                variant="caption"
                color={isDeadlinePassed(bracket.deadline_date) ? 'error' : 'text.secondary'}
              >
                Deadline: {formatDate(bracket.deadline_date)}
                {isDeadlinePassed(bracket.deadline_date) && ' (Passed)'}
              </Typography>
            </Box>
          </Box>

          {/* BYE Warning */}
          {bracket.status === 'Pending' && 
           isDeadlinePassed(bracket.deadline_date) && 
           !bracket.winner_id && (
            <Alert severity="warning" sx={{ mt: 1 }}>
              Deadline passed. Check-in determines winner by BYE.
            </Alert>
          )}
        </CardContent>
      </Card>
    );
  };

  if (brackets.length === 0) {
    return (
      <Alert severity="info">
        {tournament.status === 'Open'
          ? 'Brackets will be generated when tournament starts.'
          : 'No brackets available for this tournament.'}
      </Alert>
    );
  }

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h6">Tournament Bracket</Typography>
        <Chip label={tournament.status} color={tournament.status === 'Completed' ? 'success' : 'primary'} />
      </Box>

      {/* Render brackets by round */}
      <Box sx={{ display: 'grid', gridTemplateColumns: `repeat(${rounds.length}, 1fr)`, gap: 2 }}>
        {rounds.map((round) => {
          const roundBrackets = bracketsByRound[round].sort((a, b) => a.match_number - b.match_number);
          const isFinal = round === rounds[rounds.length - 1];

          return (
            <Box key={round}>
              <Typography variant="h6" gutterBottom align="center">
                {isFinal ? 'Final' : round === 1 ? 'Round 1' : `Round ${round}`}
              </Typography>
              {roundBrackets.map((bracket) => (
                <RenderMatch key={bracket.id} bracket={bracket} />
              ))}
            </Box>
          );
        })}
      </Box>

      {/* Tournament Results */}
      {tournament.status === 'Completed' && tournament.winner_id && (
        <Card sx={{ mt: 3, backgroundColor: 'success.light' }}>
          <CardContent>
            <Box display="flex" alignItems="center" gap={2}>
              <EmojiEvents sx={{ fontSize: 40, color: 'warning.main' }} />
              <Box>
                <Typography variant="h6">Tournament Champion</Typography>
                <Typography variant="body1" fontWeight="bold">
                  {brackets.find(b => b.winner_id === tournament.winner_id)?.winner_name || 'Unknown'}
                </Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      )}
    </Box>
  );
};

export default TournamentBracketView;

