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
import { Delete, Warning, Forum } from '@mui/icons-material';
import { supabase } from '../../services/supabase';
import { AdminService } from '../../services/adminService';

interface ChatMessagesManagementProps {
  open: boolean;
  onClose: () => void;
}

const ChatMessagesManagement = ({ open, onClose }: ChatMessagesManagementProps) => {
  const [loading, setLoading] = useState(false);
  const [stats, setStats] = useState({
    totalMessages: 0,
  });

  const loadStats = useCallback(async () => {
    try {
      const { data: messages, error: messagesError } = await supabase
        .from('chat_messages')
        .select('id');

      if (messagesError) throw messagesError;

      const totalMessages = messages?.length || 0;

      setStats({ totalMessages });
    } catch (error) {
      console.error('Error loading stats:', error);
    }
  }, []);

  useEffect(() => {
    if (open) {
      loadStats();
    }
  }, [open, loadStats]);

  const deleteAllChatMessages = async () => {
    try {
      setLoading(true);
      const result = await AdminService.deleteAllChatMessages();

      await loadStats();
      alert(
        `Successfully deleted all chat messages:\n` +
        `- Total Messages Deleted: ${result.deletedCount}`
      );
    } catch (error: any) {
      console.error('Error deleting chat messages:', error);
      alert('Failed to delete chat messages: ' + (error.message || 'Unknown error'));
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteAll = () => {
    const confirmed = window.confirm(
      `⚠️ WARNING: This will permanently delete ALL messages from the League Chat Room.\n\n` +
      `- Total Messages: ${stats.totalMessages}\n\n` +
      `This action CANNOT be undone. Are you sure you want to proceed?`
    );

    if (confirmed) {
      deleteAllChatMessages();
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
          <Forum color="primary" />
          <Warning color="warning" />
          Manage League Chat Room Messages
        </Box>
      </DialogTitle>
      <DialogContent>
        <Stack spacing={2}>
          <Alert severity="info">
            This section allows you to manage all messages in the League Chat Room.
          </Alert>

          <Card variant="outlined">
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Current Statistics
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                <Typography variant="body1" sx={{ fontWeight: 'bold' }}>
                  <strong>Total Messages:</strong> {stats.totalMessages}
                </Typography>
              </Box>
            </CardContent>
          </Card>

          <Alert severity="warning">
            <Typography variant="body2" fontWeight="bold" gutterBottom>
              Delete All Chat Messages
            </Typography>
            <Box component="div">
              <Typography variant="body2" component="div">
                This will permanently delete all messages from the League Chat Room, including:
              </Typography>
              <ul style={{ marginTop: '8px', marginBottom: '8px', paddingLeft: '20px' }}>
                <li>All text messages</li>
                <li>All attachments (images, videos, files)</li>
                <li>All message history</li>
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
          disabled={loading || stats.totalMessages === 0}
        >
          {loading ? 'Deleting...' : 'Delete All Chat Messages'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default ChatMessagesManagement;

