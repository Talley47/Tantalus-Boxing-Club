import React, { useState, useEffect, useCallback } from 'react';
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
import { Delete, Warning, FitnessCenter } from '@mui/icons-material';
import { supabase } from '../../services/supabase';
import { AdminService } from '../../services/adminService';

interface TrainingCampsManagementProps {
  open: boolean;
  onClose: () => void;
}

const TrainingCampsManagement = ({ open, onClose }: TrainingCampsManagementProps) => {
  const [loading, setLoading] = useState(false);
  const [stats, setStats] = useState({
    pendingInvitations: 0,
    activeCamps: 0,
    total: 0,
  });

  const loadStats = useCallback(async () => {
    try {
      const { data: invitations, error: invitationsError } = await supabase
        .from('training_camp_invitations')
        .select('status');

      if (invitationsError) throw invitationsError;

      const pendingInvitations = invitations?.filter(i => i.status === 'pending').length || 0;
      const activeCamps = invitations?.filter(i => i.status === 'accepted').length || 0;
      const total = invitations?.length || 0;

      setStats({ pendingInvitations, activeCamps, total });
    } catch (error) {
      console.error('Error loading stats:', error);
    }
  }, []);

  useEffect(() => {
    if (open) {
      loadStats();
    }
  }, [open, loadStats]);

  const deleteAllTrainingCamps = async () => {
    try {
      setLoading(true);
      const result = await AdminService.deleteAllTrainingCamps();

      await loadStats();
      alert(
        `Successfully deleted all training camps:\n` +
        `- Pending Invitations: ${result.deletedInvitations}\n` +
        `- Active Training Camps: ${result.deletedActiveCamps}\n` +
        `- Total: ${result.deletedInvitations + result.deletedActiveCamps}`
      );
    } catch (error: any) {
      console.error('Error deleting training camps:', error);
      alert('Failed to delete training camps: ' + (error.message || 'Unknown error'));
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteAll = () => {
    const confirmed = window.confirm(
      `⚠️ WARNING: This will permanently delete ALL training camp invitations and active training camps.\n\n` +
      `- Pending Invitations: ${stats.pendingInvitations}\n` +
      `- Active Training Camps: ${stats.activeCamps}\n` +
      `- Total: ${stats.total}\n\n` +
      `This action CANNOT be undone. Are you sure you want to proceed?`
    );

    if (confirmed) {
      deleteAllTrainingCamps();
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
          <FitnessCenter color="primary" />
          <Warning color="warning" />
          Manage Training Camps
        </Box>
      </DialogTitle>
      <DialogContent>
        <Stack spacing={2}>
          <Alert severity="info">
            This section allows you to manage all training camp invitations and active training camps in the system.
          </Alert>

          <Card variant="outlined">
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Current Statistics
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                <Typography variant="body1">
                  <strong>Pending Invitations:</strong> {stats.pendingInvitations}
                </Typography>
                <Typography variant="body1">
                  <strong>Active Training Camps:</strong> {stats.activeCamps}
                </Typography>
                <Typography variant="body1" sx={{ fontWeight: 'bold', mt: 1 }}>
                  <strong>Total:</strong> {stats.total}
                </Typography>
              </Box>
            </CardContent>
          </Card>

          <Alert severity="warning">
            <Typography variant="body2" fontWeight="bold" gutterBottom>
              Delete All Training Camp Invitations and Active Training Camps
            </Typography>
            <Box component="div">
              <Typography variant="body2" component="div">
                This will permanently delete:
              </Typography>
              <ul style={{ marginTop: '8px', marginBottom: '8px', paddingLeft: '20px' }}>
                <li>All pending training camp invitations (status: pending)</li>
                <li>All active training camps (status: accepted)</li>
              </ul>
              <Typography variant="body2" component="div">
                This action cannot be undone. Use with extreme caution.
              </Typography>
            </Box>
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
          {loading ? 'Deleting...' : 'Delete All Training Camps'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default TrainingCampsManagement;

