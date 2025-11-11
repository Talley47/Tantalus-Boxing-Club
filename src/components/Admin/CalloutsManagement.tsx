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
import { Delete, Warning, SportsMma } from '@mui/icons-material';
import { supabase } from '../../services/supabase';
import { AdminService } from '../../services/adminService';

interface CalloutsManagementProps {
  open: boolean;
  onClose: () => void;
}

const CalloutsManagement = ({ open, onClose }: CalloutsManagementProps) => {
  const [loading, setLoading] = useState(false);
  const [stats, setStats] = useState({
    pendingCallouts: 0,
    scheduledCallouts: 0,
    total: 0,
  });

  const loadStats = useCallback(async () => {
    try {
      const { data: callouts, error: calloutsError } = await supabase
        .from('callout_requests')
        .select('status');

      if (calloutsError) throw calloutsError;

      const pendingCallouts = callouts?.filter(c => c.status === 'pending').length || 0;
      const scheduledCallouts = callouts?.filter(c => c.status === 'scheduled').length || 0;
      const total = callouts?.length || 0;

      setStats({ pendingCallouts, scheduledCallouts, total });
    } catch (error) {
      console.error('Error loading stats:', error);
    }
  }, []);

  useEffect(() => {
    if (open) {
      loadStats();
    }
  }, [open, loadStats]);

  const deleteAllCallouts = async () => {
    try {
      setLoading(true);
      const result = await AdminService.deleteAllCallouts();

      await loadStats();
      alert(
        `Successfully deleted all callouts:\n` +
        `- Pending Callouts: ${result.deletedPending}\n` +
        `- Scheduled Callouts: ${result.deletedScheduled}\n` +
        `- Total: ${result.deletedPending + result.deletedScheduled}`
      );
    } catch (error: any) {
      console.error('Error deleting callouts:', error);
      alert('Failed to delete callouts: ' + (error.message || 'Unknown error'));
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteAll = () => {
    const confirmed = window.confirm(
      `⚠️ WARNING: This will permanently delete ALL callout requests and scheduled callouts.\n\n` +
      `- Pending Callouts: ${stats.pendingCallouts}\n` +
      `- Scheduled Callouts: ${stats.scheduledCallouts}\n` +
      `- Total: ${stats.total}\n\n` +
      `This action CANNOT be undone. Are you sure you want to proceed?`
    );

    if (confirmed) {
      deleteAllCallouts();
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
          <SportsMma color="primary" />
          <Warning color="warning" />
          Manage Callouts
        </Box>
      </DialogTitle>
      <DialogContent>
        <Stack spacing={2}>
          <Alert severity="info">
            This section allows you to manage all callout requests and scheduled callouts in the system.
          </Alert>

          <Card variant="outlined">
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Current Statistics
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                <Typography variant="body1">
                  <strong>Pending Callouts:</strong> {stats.pendingCallouts}
                </Typography>
                <Typography variant="body1">
                  <strong>Scheduled Callouts:</strong> {stats.scheduledCallouts}
                </Typography>
                <Typography variant="body1" sx={{ fontWeight: 'bold', mt: 1 }}>
                  <strong>Total:</strong> {stats.total}
                </Typography>
              </Box>
            </CardContent>
          </Card>

          <Alert severity="warning">
            <Typography variant="body2" fontWeight="bold" gutterBottom>
              Delete All Callout Requests and Scheduled Callouts
            </Typography>
            <Box component="div">
              <Typography variant="body2" component="div">
                This will permanently delete:
              </Typography>
              <ul style={{ marginTop: '8px', marginBottom: '8px', paddingLeft: '20px' }}>
                <li>All pending callout requests (status: pending)</li>
                <li>All scheduled callouts (status: scheduled)</li>
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
          {loading ? 'Deleting...' : 'Delete All Callouts'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default CalloutsManagement;

