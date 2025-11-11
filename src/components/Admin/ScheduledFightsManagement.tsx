import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Alert,
  Box,
  CircularProgress,
  Card,
  CardContent,
  Stack,
} from '@mui/material';
import { Delete, Warning } from '@mui/icons-material';
import { supabase } from '../../services/supabase';

interface ScheduledFightsManagementProps {
  open: boolean;
  onClose: () => void;
}

const ScheduledFightsManagement: React.FC<ScheduledFightsManagementProps> = ({ open, onClose }) => {
  const [loading, setLoading] = useState(false);
  const [stats, setStats] = useState({
    scheduled: 0,
    pending: 0,
    total: 0,
  });

  useEffect(() => {
    if (open) {
      loadStats();
    }
  }, [open]);

  const loadStats = async () => {
    try {
      const { data: fights, error } = await supabase
        .from('scheduled_fights')
        .select('status');

      if (error) throw error;

      const scheduled = fights?.filter(f => f.status === 'Scheduled').length || 0;
      const pending = fights?.filter(f => f.status === 'Pending').length || 0;
      const total = fights?.length || 0;

      setStats({ scheduled, pending, total });
    } catch (error) {
      console.error('Error loading stats:', error);
    }
  };

  const deleteAllScheduledFights = async () => {
    try {
      setLoading(true);
      const { error } = await supabase
        .from('scheduled_fights')
        .delete()
        .in('status', ['Scheduled', 'Pending']);

      if (error) throw error;

      await loadStats();
      alert(`Successfully deleted all scheduled fights and mandatory fight requests (${stats.scheduled + stats.pending} total).`);
    } catch (error: any) {
      console.error('Error deleting scheduled fights:', error);
      alert('Failed to delete scheduled fights: ' + (error.message || 'Unknown error'));
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteAll = () => {
    const confirmed = window.confirm(
      `⚠️ WARNING: This will permanently delete ALL scheduled fights and mandatory fight requests.\n\n` +
      `- Scheduled Fights: ${stats.scheduled}\n` +
      `- Pending Requests: ${stats.pending}\n` +
      `- Total: ${stats.total}\n\n` +
      `This action CANNOT be undone. Are you sure you want to proceed?`
    );

    if (confirmed) {
      deleteAllScheduledFights();
    }
  };

  return (
    <Dialog 
      open={open} 
      onClose={onClose} 
      maxWidth="sm" 
      fullWidth
      disableEnforceFocus={false}
      disableAutoFocus={false}
      disableRestoreFocus={false}
      keepMounted={false}
    >
      <DialogTitle>
        <Box display="flex" alignItems="center" gap={1}>
          <Warning color="warning" />
          Manage Scheduled Fights
        </Box>
      </DialogTitle>
      <DialogContent>
        <Stack spacing={2}>
          <Alert severity="info">
            This section allows you to manage all scheduled fights and mandatory fight requests in the system.
          </Alert>

          <Card variant="outlined">
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Current Statistics
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                <Typography variant="body1">
                  <strong>Scheduled Fights:</strong> {stats.scheduled}
                </Typography>
                <Typography variant="body1">
                  <strong>Pending Requests:</strong> {stats.pending}
                </Typography>
                <Typography variant="body1" sx={{ fontWeight: 'bold', mt: 1 }}>
                  <strong>Total:</strong> {stats.total}
                </Typography>
              </Box>
            </CardContent>
          </Card>

          <Alert severity="warning">
            <Typography variant="body2" fontWeight="bold" gutterBottom>
              Delete All Scheduled Fights and Mandatory Fight Requests
            </Typography>
            <Typography variant="body2">
              This will permanently delete all scheduled fights (status: Scheduled) and all mandatory fight requests (status: Pending).
              This action cannot be undone. Use with extreme caution.
            </Typography>
          </Alert>
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={loading}>
          Close
        </Button>
        <Button
          variant="contained"
          color="error"
          startIcon={loading ? <CircularProgress size={16} /> : <Delete />}
          onClick={handleDeleteAll}
          disabled={loading || stats.total === 0}
        >
          {loading ? 'Deleting...' : 'Delete All Scheduled Fights & Requests'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default ScheduledFightsManagement;

