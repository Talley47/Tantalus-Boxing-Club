import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Box,
  Alert,
  CircularProgress,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Autocomplete,
  Chip,
  Card,
  CardContent,
  Divider,
  IconButton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Snackbar,
} from '@mui/material';
import {
  Send as SendIcon,
  Delete as DeleteIcon,
  Refresh as RefreshIcon,
  Close as CloseIcon,
} from '@mui/icons-material';
import { adminMessageService, AdminDirectMessage, FighterOption, SendAdminMessageRequest } from '../../services/adminMessageService';

interface AdminDirectMessagesProps {
  open: boolean;
  onClose: () => void;
}

const AdminDirectMessages: React.FC<AdminDirectMessagesProps> = ({ open, onClose }) => {
  const [loading, setLoading] = useState(false);
  const [loadingFighters, setLoadingFighters] = useState(false);
  const [fighters, setFighters] = useState<FighterOption[]>([]);
  const [selectedFighters, setSelectedFighters] = useState<FighterOption[]>([]);
  const [messages, setMessages] = useState<AdminDirectMessage[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });

  // Form state
  const [formData, setFormData] = useState<SendAdminMessageRequest>({
    fighter_id: '',
    subject: 'Live Event Selection',
    message: '',
    message_type: 'live_event_selection',
    event_name: '',
    event_type: 'live_event',
  });

  // Load fighters and messages when dialog opens
  useEffect(() => {
    if (open) {
      loadFighters();
      loadMessages();
    }
  }, [open]);

  const loadFighters = async () => {
    try {
      setLoadingFighters(true);
      const fighterList = await adminMessageService.getFightersForSelection();
      setFighters(fighterList);
    } catch (err: any) {
      console.error('Error loading fighters:', err);
      showSnackbar('Failed to load fighters list', 'error');
    } finally {
      setLoadingFighters(false);
    }
  };

  const loadMessages = async () => {
    try {
      setLoading(true);
      const messageList = await adminMessageService.getAllMessages(50);
      setMessages(messageList);
    } catch (err: any) {
      console.error('Error loading messages:', err);
      showSnackbar('Failed to load messages', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleSendMessage = async () => {
    if (selectedFighters.length === 0) {
      setError('Please select at least one fighter');
      return;
    }

    if (!formData.subject.trim()) {
      setError('Subject is required');
      return;
    }

    if (!formData.message.trim()) {
      setError('Message is required');
      return;
    }

    try {
      setLoading(true);
      setError(null);

      const messageRequest: Omit<SendAdminMessageRequest, 'fighter_id'> = {
        subject: formData.subject.trim(),
        message: formData.message.trim(),
        message_type: formData.message_type,
        event_name: formData.event_name?.trim() || undefined,
        event_type: formData.event_type,
      };

      if (selectedFighters.length === 1) {
        // Single message
        await adminMessageService.sendMessage({
          ...messageRequest,
          fighter_id: selectedFighters[0].user_id,
        });
        showSnackbar('Message sent successfully!', 'success');
      } else {
        // Bulk message
        const fighterIds = selectedFighters.map(f => f.user_id);
        await adminMessageService.sendBulkMessage(fighterIds, messageRequest);
        showSnackbar(`Message sent to ${selectedFighters.length} fighters!`, 'success');
      }

      // Reset form
      setFormData({
        fighter_id: '',
        subject: 'Live Event Selection',
        message: '',
        message_type: 'live_event_selection',
        event_name: '',
        event_type: 'live_event',
      });
      setSelectedFighters([]);
      
      // Reload messages
      await loadMessages();
    } catch (err: any) {
      console.error('Error sending message:', err);
      setError(err.message || 'Failed to send message');
      showSnackbar('Failed to send message', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteMessage = async (messageId: string) => {
    if (!window.confirm('Are you sure you want to delete this message?')) {
      return;
    }

    try {
      setLoading(true);
      await adminMessageService.deleteMessage(messageId);
      showSnackbar('Message deleted successfully', 'success');
      await loadMessages();
    } catch (err: any) {
      console.error('Error deleting message:', err);
      showSnackbar('Failed to delete message', 'error');
    } finally {
      setLoading(false);
    }
  };

  const showSnackbar = (message: string, severity: 'success' | 'error') => {
    setSnackbar({ open: true, message, severity });
  };

  const handleClose = () => {
    setFormData({
      fighter_id: '',
      subject: 'Live Event Selection',
      message: '',
      message_type: 'live_event_selection',
      event_name: '',
      event_type: 'live_event',
    });
    setSelectedFighters([]);
    setError(null);
    setSuccess(null);
    onClose();
  };

  const getMessageTypeLabel = (type: string) => {
    const labels: Record<string, string> = {
      live_event_selection: 'Live Event Selection',
      tournament_selection: 'Tournament Selection',
      general: 'General',
      announcement: 'Announcement',
    };
    return labels[type] || type;
  };

  return (
    <>
      <Dialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
        <DialogTitle>
          <Box display="flex" justifyContent="space-between" alignItems="center">
            <Typography variant="h6">Admin Direct Messages</Typography>
            <IconButton onClick={handleClose} size="small">
              <CloseIcon />
            </IconButton>
          </Box>
        </DialogTitle>
        <DialogContent>
          <Box sx={{ mt: 2 }}>
            {/* Send Message Form */}
            <Card sx={{ mb: 3 }}>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Send Message to Fighters
                </Typography>
                <Divider sx={{ my: 2 }} />

                {/* Fighter Selection */}
                <Box sx={{ mb: 2 }}>
                  <Autocomplete
                    multiple
                    options={fighters}
                    getOptionLabel={(option) => `${option.name} (@${option.handle}) - ${option.tier} - ${option.weight_class}`}
                    value={selectedFighters}
                    onChange={(_, newValue) => setSelectedFighters(newValue)}
                    loading={loadingFighters}
                    renderInput={(params) => (
                      <TextField
                        {...params}
                        label="Select Fighters"
                        placeholder="Search and select fighters..."
                      />
                    )}
                    renderTags={(value, getTagProps) =>
                      value.map((option, index) => (
                        <Chip
                          {...getTagProps({ index })}
                          key={option.user_id}
                          label={`${option.name} (@${option.handle})`}
                        />
                      ))
                    }
                  />
                </Box>

                {/* Subject */}
                <TextField
                  fullWidth
                  label="Subject"
                  value={formData.subject}
                  onChange={(e) => setFormData({ ...formData, subject: e.target.value })}
                  sx={{ mb: 2 }}
                  required
                />

                {/* Message Type */}
                <FormControl fullWidth sx={{ mb: 2 }}>
                  <InputLabel>Message Type</InputLabel>
                  <Select
                    value={formData.message_type}
                    label="Message Type"
                    onChange={(e) => setFormData({ ...formData, message_type: e.target.value as any })}
                  >
                    <MenuItem value="live_event_selection">Live Event Selection</MenuItem>
                    <MenuItem value="tournament_selection">Tournament Selection</MenuItem>
                    <MenuItem value="general">General</MenuItem>
                    <MenuItem value="announcement">Announcement</MenuItem>
                  </Select>
                </FormControl>

                {/* Event Name */}
                <TextField
                  fullWidth
                  label="Event Name (Optional)"
                  value={formData.event_name}
                  onChange={(e) => setFormData({ ...formData, event_name: e.target.value })}
                  placeholder="e.g., King of the Hill Event"
                  sx={{ mb: 2 }}
                />

                {/* Event Type */}
                {formData.message_type === 'live_event_selection' || formData.message_type === 'tournament_selection' ? (
                  <FormControl fullWidth sx={{ mb: 2 }}>
                    <InputLabel>Event Type</InputLabel>
                    <Select
                      value={formData.event_type}
                      label="Event Type"
                      onChange={(e) => setFormData({ ...formData, event_type: e.target.value as any })}
                    >
                      <MenuItem value="live_event">Live Event</MenuItem>
                      <MenuItem value="tournament">Tournament</MenuItem>
                    </Select>
                  </FormControl>
                ) : null}

                {/* Message */}
                <TextField
                  fullWidth
                  label="Message"
                  value={formData.message}
                  onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                  multiline
                  rows={4}
                  sx={{ mb: 2 }}
                  required
                  placeholder="Enter your message to notify the fighter..."
                />

                {error && (
                  <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
                    {error}
                  </Alert>
                )}

                {success && (
                  <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccess(null)}>
                    {success}
                  </Alert>
                )}

                <Button
                  variant="contained"
                  startIcon={<SendIcon />}
                  onClick={handleSendMessage}
                  disabled={loading || selectedFighters.length === 0}
                  fullWidth
                >
                  {loading ? 'Sending...' : `Send Message${selectedFighters.length > 1 ? ` to ${selectedFighters.length} Fighters` : ''}`}
                </Button>
              </CardContent>
            </Card>

            {/* Message History */}
            <Card>
              <CardContent>
                <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                  <Typography variant="h6">Message History</Typography>
                  <IconButton onClick={loadMessages} size="small" disabled={loading}>
                    <RefreshIcon />
                  </IconButton>
                </Box>
                <Divider sx={{ mb: 2 }} />

                {loading && messages.length === 0 ? (
                  <Box display="flex" justifyContent="center" p={3}>
                    <CircularProgress />
                  </Box>
                ) : messages.length === 0 ? (
                  <Alert severity="info">No messages sent yet.</Alert>
                ) : (
                  <TableContainer component={Paper} variant="outlined">
                    <Table size="small">
                      <TableHead>
                        <TableRow>
                          <TableCell>Fighter</TableCell>
                          <TableCell>Subject</TableCell>
                          <TableCell>Type</TableCell>
                          <TableCell>Event</TableCell>
                          <TableCell>Date</TableCell>
                          <TableCell>Status</TableCell>
                          <TableCell>Actions</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {messages.map((msg) => (
                          <TableRow key={msg.id}>
                            <TableCell>
                              <Box>
                                <Typography variant="body2" fontWeight="bold">
                                  {msg.fighter_name || 'Unknown'}
                                </Typography>
                                <Typography variant="caption" color="text.secondary">
                                  @{msg.fighter_handle || 'unknown'}
                                </Typography>
                              </Box>
                            </TableCell>
                            <TableCell>{msg.subject}</TableCell>
                            <TableCell>
                              <Chip
                                label={getMessageTypeLabel(msg.message_type)}
                                size="small"
                                color={msg.message_type === 'live_event_selection' ? 'primary' : 'default'}
                              />
                            </TableCell>
                            <TableCell>{msg.event_name || '-'}</TableCell>
                            <TableCell>
                              {new Date(msg.created_at).toLocaleDateString()}
                            </TableCell>
                            <TableCell>
                              {msg.read_at ? (
                                <Chip label="Read" size="small" color="success" />
                              ) : (
                                <Chip label="Unread" size="small" color="warning" />
                              )}
                            </TableCell>
                            <TableCell>
                              <IconButton
                                size="small"
                                color="error"
                                onClick={() => handleDeleteMessage(msg.id)}
                                disabled={loading}
                              >
                                <DeleteIcon fontSize="small" />
                              </IconButton>
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
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose}>Close</Button>
        </DialogActions>
      </Dialog>

      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
        message={snackbar.message}
      />
    </>
  );
};

export default AdminDirectMessages;

