import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
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
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  IconButton,
  Tooltip,
  Chip,
  Alert,
  CircularProgress,
  Switch,
  FormControlLabel,
} from '@mui/material';
import {
  Add,
  Edit,
  Delete,
  EmojiEvents,
  SportsMma,
} from '@mui/icons-material';
import { TournamentService, Tournament } from '../../services/tournamentService';
import { useRealtime } from '../../contexts/RealtimeContext';

const TournamentManagement: React.FC = () => {
  const [tournaments, setTournaments] = useState<Tournament[]>([]);
  const [loading, setLoading] = useState(false);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedTournament, setSelectedTournament] = useState<Tournament | null>(null);
  const [tournamentToDelete, setTournamentToDelete] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    format: 'Single Elimination' as Tournament['format'],
    weight_class: '',
    max_participants: 16,
    entry_fee: 0,
    prize_pool: 0,
    start_date: '',
    end_date: '',
    registration_deadline: '',
    check_in_deadline: '',
    min_tier: '',
    min_points: 0,
    min_rank: undefined as number | undefined,
  });

  const { subscribeToFightRecords } = useRealtime();

  useEffect(() => {
    loadTournaments();
  }, []);

  // Real-time updates
  useEffect(() => {
    const unsubscribe = subscribeToFightRecords(() => {
      loadTournaments();
    });
    return () => unsubscribe();
  }, []);

  const loadTournaments = async () => {
    try {
      setLoading(true);
      const data = await TournamentService.getTournaments();
      setTournaments(data);
    } catch (error) {
      console.error('Error loading tournaments:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateTournament = () => {
    setSelectedTournament(null);
    setFormData({
      name: '',
      description: '',
      format: 'Single Elimination',
      weight_class: '',
      max_participants: 16,
      entry_fee: 0,
      prize_pool: 0,
      start_date: '',
      end_date: '',
      registration_deadline: '',
      check_in_deadline: '',
      min_tier: '',
      min_points: 0,
      min_rank: undefined,
    });
    setDialogOpen(true);
  };

  const handleEditTournament = (tournament: Tournament) => {
    setSelectedTournament(tournament);
    setFormData({
      name: tournament.name,
      description: tournament.description || '',
      format: tournament.format,
      weight_class: tournament.weight_class,
      max_participants: tournament.max_participants,
      entry_fee: tournament.entry_fee,
      prize_pool: tournament.prize_pool,
      start_date: tournament.start_date.split('T')[0],
      end_date: tournament.end_date.split('T')[0],
      registration_deadline: tournament.registration_deadline?.split('T')[0] || '',
      check_in_deadline: tournament.check_in_deadline?.split('T')[0] || '',
      min_tier: tournament.min_tier || '',
      min_points: tournament.min_points || 0,
      min_rank: tournament.min_rank,
    });
    setDialogOpen(true);
  };

  const handleSaveTournament = async () => {
    try {
      const tournamentData: any = {
        name: formData.name,
        description: formData.description,
        format: formData.format,
        weight_class: formData.weight_class,
        max_participants: formData.max_participants,
        entry_fee: formData.entry_fee,
        prize_pool: formData.prize_pool,
        start_date: new Date(formData.start_date).toISOString(),
        end_date: new Date(formData.end_date).toISOString(),
        registration_deadline: formData.registration_deadline
          ? new Date(formData.registration_deadline).toISOString()
          : undefined,
        check_in_deadline: formData.check_in_deadline
          ? new Date(formData.check_in_deadline).toISOString()
          : undefined,
        min_tier: formData.min_tier || undefined,
        min_points: formData.min_points || undefined,
        min_rank: formData.min_rank || undefined,
        status: 'Open',
      };

      if (selectedTournament) {
        await TournamentService.updateTournament(selectedTournament.id, tournamentData);
      } else {
        await TournamentService.createTournament(tournamentData);
      }

      setDialogOpen(false);
      loadTournaments();
      alert(selectedTournament ? 'Tournament updated successfully!' : 'Tournament created successfully!');
    } catch (error: any) {
      console.error('Error saving tournament:', error);
      alert('Failed to save tournament: ' + (error.message || 'Unknown error'));
    }
  };

  const handleDeleteTournament = async () => {
    if (!tournamentToDelete) return;

    try {
      await TournamentService.deleteTournament(tournamentToDelete);
      setDeleteDialogOpen(false);
      setTournamentToDelete(null);
      loadTournaments();
      alert('Tournament deleted successfully!');
    } catch (error) {
      console.error('Error deleting tournament:', error);
      alert('Failed to delete tournament');
    }
  };

  const handleGenerateBrackets = async (tournamentId: string) => {
    try {
      await TournamentService.generateBrackets(tournamentId);
      alert('Brackets generated successfully!');
      loadTournaments();
    } catch (error: any) {
      alert('Failed to generate brackets: ' + (error.message || 'Unknown error'));
    }
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

  return (
    <Card>
      <CardContent>
        <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
          <Box display="flex" alignItems="center">
            <EmojiEvents sx={{ mr: 1 }} />
            <Typography variant="h6">Tournament Management</Typography>
          </Box>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={(e) => {
              e.currentTarget.blur(); // Remove focus from button before opening dialog
              handleCreateTournament();
            }}
          >
            Create Tournament
          </Button>
        </Box>

        {loading ? (
          <Box display="flex" justifyContent="center" p={4}>
            <CircularProgress />
          </Box>
        ) : tournaments.length === 0 ? (
          <Alert severity="info">No tournaments created yet</Alert>
        ) : (
          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Name</TableCell>
                  <TableCell>Format</TableCell>
                  <TableCell>Weight Class</TableCell>
                  <TableCell>Start Date</TableCell>
                  <TableCell>End Date</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Participants</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {tournaments.map((tournament) => (
                  <TableRow key={tournament.id}>
                    <TableCell>{tournament.name}</TableCell>
                    <TableCell>{tournament.format}</TableCell>
                    <TableCell>{tournament.weight_class}</TableCell>
                    <TableCell>{new Date(tournament.start_date).toLocaleDateString()}</TableCell>
                    <TableCell>{new Date(tournament.end_date).toLocaleDateString()}</TableCell>
                    <TableCell>
                      <Chip
                        label={tournament.status}
                        size="small"
                        color={getStatusColor(tournament.status) as any}
                      />
                    </TableCell>
                    <TableCell>
                      {tournament.current_participants || 0}/{tournament.max_participants}
                    </TableCell>
                    <TableCell>
                      <Tooltip title="Edit Tournament">
                        <IconButton
                          size="small"
                          onClick={(e) => {
                            e.currentTarget.blur(); // Remove focus from button before opening dialog
                            handleEditTournament(tournament);
                          }}
                        >
                          <Edit />
                        </IconButton>
                      </Tooltip>
                      {tournament.status === 'Open' && tournament.current_participants && tournament.current_participants >= 2 && (
                        <Tooltip title="Generate Brackets">
                          <IconButton
                            size="small"
                            onClick={() => handleGenerateBrackets(tournament.id)}
                          >
                            <SportsMma />
                          </IconButton>
                        </Tooltip>
                      )}
                      <Tooltip title="Delete Tournament">
                        <IconButton
                          size="small"
                          color="error"
                          onClick={(e) => {
                            e.currentTarget.blur(); // Remove focus from button before opening dialog
                            setTournamentToDelete(tournament.id);
                            setDeleteDialogOpen(true);
                          }}
                        >
                          <Delete />
                        </IconButton>
                      </Tooltip>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </CardContent>

      {/* Create/Edit Tournament Dialog */}
      <Dialog 
        open={dialogOpen} 
        onClose={() => setDialogOpen(false)} 
        maxWidth="md" 
        fullWidth
        keepMounted={false}
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
      >
        <DialogTitle>
          {selectedTournament ? 'Edit Tournament' : 'Create New Tournament'}
        </DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
            <TextField
              fullWidth
              label="Tournament Name"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              required
            />

            <TextField
              fullWidth
              label="Description"
              multiline
              rows={3}
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            />

            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2 }}>
              <FormControl fullWidth required>
                <InputLabel>Format</InputLabel>
                <Select
                  value={formData.format}
                  onChange={(e) => setFormData({ ...formData, format: e.target.value as any })}
                >
                  <MenuItem value="Single Elimination">Single Elimination</MenuItem>
                  <MenuItem value="Double Elimination">Double Elimination</MenuItem>
                  <MenuItem value="Group Stage">Group Stage</MenuItem>
                  <MenuItem value="Swiss">Swiss</MenuItem>
                  <MenuItem value="Round Robin">Round Robin</MenuItem>
                </Select>
              </FormControl>

              <FormControl fullWidth required>
                <InputLabel>Weight Class</InputLabel>
                <Select
                  value={formData.weight_class}
                  onChange={(e) => setFormData({ ...formData, weight_class: e.target.value })}
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

              <TextField
                fullWidth
                label="Max Participants"
                type="number"
                value={formData.max_participants}
                onChange={(e) => setFormData({ ...formData, max_participants: Number(e.target.value) })}
                required
              />

              <TextField
                fullWidth
                label="Entry Fee ($)"
                type="number"
                value={formData.entry_fee}
                onChange={(e) => setFormData({ ...formData, entry_fee: Number(e.target.value) })}
              />

              <TextField
                fullWidth
                label="Prize Pool ($)"
                type="number"
                value={formData.prize_pool}
                onChange={(e) => setFormData({ ...formData, prize_pool: Number(e.target.value) })}
              />
            </Box>

            <TextField
              fullWidth
              label="Start Date"
              type="datetime-local"
              value={formData.start_date}
              onChange={(e) => setFormData({ ...formData, start_date: e.target.value })}
              InputLabelProps={{ shrink: true }}
              required
            />

            <TextField
              fullWidth
              label="End Date"
              type="datetime-local"
              value={formData.end_date}
              onChange={(e) => setFormData({ ...formData, end_date: e.target.value })}
              InputLabelProps={{ shrink: true }}
              required
            />

            <TextField
              fullWidth
              label="Registration Deadline"
              type="datetime-local"
              value={formData.registration_deadline}
              onChange={(e) => setFormData({ ...formData, registration_deadline: e.target.value })}
              InputLabelProps={{ shrink: true }}
            />

            <TextField
              fullWidth
              label="Check-In Deadline"
              type="datetime-local"
              value={formData.check_in_deadline}
              onChange={(e) => setFormData({ ...formData, check_in_deadline: e.target.value })}
              InputLabelProps={{ shrink: true }}
            />

            <Typography variant="h6" sx={{ mt: 2 }}>Eligibility Requirements</Typography>

            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2 }}>
              <FormControl fullWidth>
                <InputLabel>Minimum Tier</InputLabel>
                <Select
                  value={formData.min_tier}
                  onChange={(e) => setFormData({ ...formData, min_tier: e.target.value })}
                >
                  <MenuItem value="">No minimum</MenuItem>
                  <MenuItem value="Amateur">Amateur</MenuItem>
                  <MenuItem value="Semi-Pro">Semi-Pro</MenuItem>
                  <MenuItem value="Pro">Pro</MenuItem>
                  <MenuItem value="Contender">Contender</MenuItem>
                  <MenuItem value="Elite">Elite</MenuItem>
                </Select>
              </FormControl>

              <TextField
                fullWidth
                label="Minimum Points"
                type="number"
                value={formData.min_points}
                onChange={(e) => setFormData({ ...formData, min_points: Number(e.target.value) })}
              />

              <TextField
                fullWidth
                label="Minimum Rank"
                type="number"
                value={formData.min_rank || ''}
                onChange={(e) => setFormData({ ...formData, min_rank: e.target.value ? Number(e.target.value) : undefined })}
              />
            </Box>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleSaveTournament} variant="contained">
            {selectedTournament ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog 
        open={deleteDialogOpen} 
        onClose={() => setDeleteDialogOpen(false)}
        keepMounted={false}
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
      >
        <DialogTitle>Delete Tournament</DialogTitle>
        <DialogContent>
          <Typography>
            Are you sure you want to delete this tournament? This action cannot be undone.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleDeleteTournament} color="error" variant="contained">
            Delete
          </Button>
        </DialogActions>
      </Dialog>
    </Card>
  );
};

export default TournamentManagement;

