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
  Chip,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  Alert,
  Paper,
  Divider,
  Link,
  Tabs,
  Tab,
  IconButton,
  CircularProgress,
  Snackbar,
} from '@mui/material';
import {
  Gavel,
  Warning,
  CheckCircle,
  Cancel,
  Info,
  Person,
  SportsMma,
  Schedule,
  Description,
  Send,
  Close,
  OpenInNew,
  DeleteForever,
} from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';
import { disputeService } from '../../services/disputeService';
import { Dispute, DisputeMessage } from '../../types';
import { supabase } from '../../services/supabase';

const DisputeManagement: React.FC = () => {
  const { user } = useAuth();
  const [disputes, setDisputes] = useState<Dispute[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedDispute, setSelectedDispute] = useState<Dispute | null>(null);
  const [disputeDialogOpen, setDisputeDialogOpen] = useState(false);
  const [messages, setMessages] = useState<DisputeMessage[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [messageToDisputer, setMessageToDisputer] = useState('');
  const [messageToOpponent, setMessageToOpponent] = useState('');
  const [sendingMessage, setSendingMessage] = useState(false);
  const [resolution, setResolution] = useState('');
  const [resolutionType, setResolutionType] = useState<'warning' | 'give_win_to_submitter' | 'one_week_suspension' | 'two_week_suspension' | 'one_month_suspension' | 'banned_from_league' | 'dispute_invalid' | 'other'>('other');
  const [adminNotes, setAdminNotes] = useState('');
  const [activeTab, setActiveTab] = useState(0);
  const [disputeDialogTab, setDisputeDialogTab] = useState(0);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    loadDisputes();

    // Subscribe to real-time changes in disputes table
    const channelName = 'disputes_changes_admin';
    const disputesChannel = supabase
      .channel(channelName)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'disputes',
        },
        (payload) => {
          console.log('Dispute changed (real-time) in Admin:', payload);
          console.log('Event type:', payload.eventType);
          console.log('Full payload:', JSON.stringify(payload, null, 2));
          
          // For DELETE events, immediately filter out the deleted dispute for instant UI update
          if (payload.eventType === 'DELETE') {
            const deletedId = payload.old?.id;
            if (deletedId) {
              setDisputes(prevDisputes => {
                const filtered = prevDisputes.filter(d => d.id !== deletedId);
                console.log('Admin: Filtered out deleted dispute ID:', deletedId, 'Remaining:', filtered.length);
                return filtered;
              });
            } else {
              // If we can't get the ID, filter by status instead (fallback for bulk deletes)
              console.log('Admin: DELETE event received but no ID found, filtering all resolved disputes');
              setDisputes(prevDisputes => {
                const filtered = prevDisputes.filter(d => d.status !== 'Resolved');
                console.log('Admin: Filtered out resolved disputes. Remaining:', filtered.length);
                return filtered;
              });
            }
          }
          
          // Always reload to ensure consistency (especially for bulk deletions)
          setTimeout(() => {
            console.log('Admin: Reloading disputes after real-time event');
            loadDisputes();
          }, 200);
        }
      )
      .subscribe();

    // Cleanup subscription on unmount
    return () => {
      supabase.removeChannel(disputesChannel);
    };
  }, []);

  useEffect(() => {
    if (selectedDispute) {
      loadMessages(selectedDispute.id);
    }
  }, [selectedDispute]);

  const loadDisputes = async () => {
    try {
      setLoading(true);
      const disputesData = await disputeService.getDisputes();
      // Force state update by creating a new array reference
      setDisputes([...disputesData]);
      console.log('Disputes reloaded:', disputesData.length, 'total disputes');
    } catch (error: any) {
      console.error('Error loading disputes:', error);
      setSnackbar({ open: true, message: 'Failed to load disputes', severity: 'error' });
    } finally {
      setLoading(false);
    }
  };

  const loadMessages = async (disputeId: string) => {
    try {
      const messagesData = await disputeService.getDisputeMessages(disputeId);
      setMessages(messagesData);
    } catch (error: any) {
      console.error('Error loading messages:', error);
    }
  };

  const handleViewDispute = async (dispute: Dispute) => {
    try {
      const fullDispute = await disputeService.getDispute(dispute.id, true); // Pass isAdmin=true
      if (fullDispute) {
        setSelectedDispute(fullDispute);
        setDisputeDialogOpen(true);
        setDisputeDialogTab(0);
      } else {
        alert('Dispute not found');
      }
    } catch (error: any) {
      console.error('Error fetching dispute details:', error);
      
      // Better error message handling
      let errorMessage = 'Unknown error occurred';
      if (error instanceof Error) {
        errorMessage = error.message;
      } else if (typeof error === 'string') {
        errorMessage = error;
      } else if (error?.message) {
        errorMessage = error.message;
      } else if (error?.code) {
        errorMessage = `Error ${error.code}: ${error.message || 'Database error'}`;
      }
      
      alert('Failed to load dispute details: ' + errorMessage);
    }
  };

  const handleSendMessage = async () => {
    if (!selectedDispute || !newMessage.trim() || !user) return;

    try {
      setSendingMessage(true);
      await disputeService.sendMessage(
        {
          dispute_id: selectedDispute.id,
          message: newMessage.trim(),
        },
        user.id,
        'admin'
      );
      setNewMessage('');
      await loadMessages(selectedDispute.id);
      setSnackbar({ open: true, message: 'Message sent successfully', severity: 'success' });
    } catch (error: any) {
      console.error('Error sending message:', error);
      setSnackbar({ open: true, message: 'Failed to send message', severity: 'error' });
    } finally {
      setSendingMessage(false);
    }
  };

  const handleResolveDispute = async () => {
    if (!selectedDispute || !resolution.trim() || !user) return;

    try {
      await disputeService.resolveDispute(
        selectedDispute.id,
        resolutionType,
        resolution,
        adminNotes,
        messageToDisputer || undefined,
        messageToOpponent || undefined,
        user.id
      );
      setDisputeDialogOpen(false);
      setResolution('');
      setResolutionType('other');
      setAdminNotes('');
      setMessageToDisputer('');
      setMessageToOpponent('');
      setSelectedDispute(null);
      await loadDisputes();
      setSnackbar({ open: true, message: 'Dispute resolved successfully', severity: 'success' });
    } catch (error: any) {
      console.error('Error resolving dispute:', error);
      setSnackbar({ open: true, message: 'Failed to resolve dispute', severity: 'error' });
    }
  };

  const handleDeleteAllResolved = async () => {
    try {
      setDeleting(true);
      const deletedCount = await disputeService.deleteAllResolvedDisputes();
      setDeleteDialogOpen(false);
      
      // Switch to Active tab if we're on Resolved tab (do this first)
      if (activeTab === 1) {
        setActiveTab(0);
      }
      
      // Immediately remove resolved disputes from current state for instant UI update
      setDisputes(prevDisputes => {
        const filtered = prevDisputes.filter(d => d.status !== 'Resolved');
        console.log('Admin: Immediately filtered out resolved disputes. Remaining:', filtered.length);
        return filtered;
      });
      
      // Force multiple reloads to ensure consistency
      // Sometimes real-time events don't fire immediately, so we reload manually
      await new Promise(resolve => setTimeout(resolve, 200));
      await loadDisputes();
      
      // One more reload after a short delay to catch any delayed updates
      setTimeout(async () => {
        await loadDisputes();
      }, 500);
      
      setSnackbar({ 
        open: true, 
        message: `Successfully deleted ${deletedCount} resolved dispute${deletedCount !== 1 ? 's' : ''}`, 
        severity: 'success' 
      });
    } catch (error: any) {
      console.error('Error deleting resolved disputes:', error);
      setSnackbar({ open: true, message: 'Failed to delete resolved disputes', severity: 'error' });
    } finally {
      setDeleting(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Open': return 'warning';
      case 'In Review': return 'info';
      case 'Resolved': return 'success';
      default: return 'default';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'Open': return <Warning />;
      case 'In Review': return <Info />;
      case 'Resolved': return <CheckCircle />;
      default: return <Cancel />;
    }
  };

  const getCategoryLabel = (category?: string) => {
    const labels: Record<string, string> = {
      cheating: 'Cheating',
      spamming: 'Spamming',
      exploits: 'Game Exploits',
      excessive_punches: 'Excessive Punches',
      stamina_draining: 'Stamina Draining',
      power_punches: 'Power Punches',
      other: 'Other',
    };
    return labels[category || 'other'] || 'Other';
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const filteredDisputes = disputes.filter((d) => {
    if (activeTab === 0) return d.status === 'Open' || d.status === 'In Review';
    if (activeTab === 1) return d.status === 'Resolved';
    return true;
  });

  return (
    <Box sx={{ p: 3 }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">Dispute Resolution</Typography>
      </Box>

      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        Review and resolve fighter disputes. Review evidence, communicate with fighters, and provide resolutions.
      </Typography>

      {/* Tabs for filtering */}
      <Box display="flex" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
        <Tabs value={activeTab} onChange={(_, newValue) => setActiveTab(newValue)}>
          <Tab label={`Active (${disputes.filter(d => d.status === 'Open' || d.status === 'In Review').length})`} />
          <Tab label={`Resolved (${disputes.filter(d => d.status === 'Resolved').length})`} />
          <Tab label={`All (${disputes.length})`} />
        </Tabs>
        {activeTab === 1 && disputes.filter(d => d.status === 'Resolved').length > 0 && (
          <Button
            variant="outlined"
            color="error"
            startIcon={<DeleteForever />}
            onClick={(e) => {
              console.log('Delete button clicked, opening dialog');
              e.currentTarget.blur(); // Remove focus from button before opening dialog
              setDeleteDialogOpen(true);
            }}
          >
            Delete All Resolved ({disputes.filter(d => d.status === 'Resolved').length})
          </Button>
        )}
      </Box>

      {/* Disputes List */}
      {loading ? (
        <Box display="flex" justifyContent="center" p={4}>
          <CircularProgress />
        </Box>
      ) : filteredDisputes.length === 0 ? (
        <Alert severity="info">No disputes found</Alert>
      ) : (
        <Card>
          <CardContent>
            <List>
              {filteredDisputes.map((dispute) => (
                <ListItem key={dispute.id} sx={{ borderBottom: '1px solid rgba(0,0,0,0.12)' }}>
                  <ListItemText
                    primary={
                      <Box display="flex" alignItems="center" gap={1} flexWrap="wrap">
                        {getStatusIcon(dispute.status)}
                        <Typography variant="subtitle1">
                          Dispute #{dispute.id.slice(-8)}
                        </Typography>
                        <Chip
                          label={dispute.status}
                          color={getStatusColor(dispute.status)}
                          size="small"
                        />
                        {dispute.dispute_category && (
                          <Chip
                            label={getCategoryLabel(dispute.dispute_category)}
                            size="small"
                            variant="outlined"
                          />
                        )}
                      </Box>
                    }
                    secondary={
                      <>
                        <Typography variant="body2" color="text.secondary" component="span" display="block">
                          <strong>Fighters:</strong>{' '}
                          {dispute.fighter1_name || dispute.disputer?.name || 'N/A'} vs{' '}
                          {dispute.fighter2_name || dispute.opponent?.name || 'N/A'}
                        </Typography>
                        <Typography variant="body2" color="text.secondary" component="span" display="block">
                          <strong>Reason:</strong> {dispute.reason}
                        </Typography>
                        <Typography variant="body2" color="text.secondary" component="span" display="block">
                          Created: {formatDate(dispute.created_at)}
                        </Typography>
                      </>
                    }
                  />
                  <ListItemSecondaryAction>
                    <Button
                      size="small"
                      variant="contained"
                      onClick={() => handleViewDispute(dispute)}
                    >
                      View & Resolve
                    </Button>
                  </ListItemSecondaryAction>
                </ListItem>
              ))}
            </List>
          </CardContent>
        </Card>
      )}

      {/* Dispute Details Dialog */}
      <Dialog
        open={disputeDialogOpen}
        onClose={() => setDisputeDialogOpen(false)}
        maxWidth="md"
        fullWidth
        aria-labelledby="dispute-details-dialog-title"
        aria-describedby="dispute-details-dialog-description"
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
        keepMounted={false}
      >
        <DialogTitle id="dispute-details-dialog-title">
          <Box display="flex" justifyContent="space-between" alignItems="center">
            <Typography variant="h6">Dispute Details</Typography>
            <IconButton onClick={() => setDisputeDialogOpen(false)} size="small">
              <Close />
            </IconButton>
          </Box>
        </DialogTitle>
        <DialogContent>
          {selectedDispute && (
            <Box>
              <Tabs value={disputeDialogTab} onChange={(_, newValue) => setDisputeDialogTab(newValue)} sx={{ mb: 2 }}>
                <Tab label="Details" />
                <Tab label="Messages" />
                <Tab label="Resolve" />
              </Tabs>

              {/* Details Tab */}
              {disputeDialogTab === 0 && (
                <Box>
                  <Paper sx={{ p: 2, mb: 2 }}>
                    <Typography variant="h6" gutterBottom>
                      Dispute Information
                    </Typography>
                    <Box display="flex" alignItems="center" gap={2} flexWrap="wrap" mb={2}>
                      <Chip
                        label={selectedDispute.status}
                        color={getStatusColor(selectedDispute.status)}
                        icon={getStatusIcon(selectedDispute.status)}
                      />
                      {selectedDispute.dispute_category && (
                        <Chip
                          label={getCategoryLabel(selectedDispute.dispute_category)}
                          variant="outlined"
                        />
                      )}
                    </Box>
                    <Typography variant="body2" mb={1}>
                      <strong>Created:</strong> {formatDate(selectedDispute.created_at)}
                    </Typography>
                    {selectedDispute.resolved_at && (
                      <Typography variant="body2" mb={1}>
                        <strong>Resolved:</strong> {formatDate(selectedDispute.resolved_at)}
                      </Typography>
                    )}
                  </Paper>

                  <Paper sx={{ p: 2, mb: 2 }}>
                    <Typography variant="h6" gutterBottom>
                      Fighter Information
                    </Typography>
                    <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 2 }}>
                      {/* Disputer Info */}
                      <Box>
                        <Typography variant="subtitle2" fontWeight="bold" mb={1}>
                          Disputer (Submitter)
                        </Typography>
                        <Typography variant="body2" mb={0.5}>
                          <strong>Name:</strong> {selectedDispute.fighter1_name ||
                            selectedDispute.disputer?.name ||
                            'Unknown'}
                        </Typography>
                        {selectedDispute.disputer && (
                          <>
                            <Typography variant="body2" mb={0.5}>
                              <strong>Weight Class:</strong> {selectedDispute.disputer.weight_class || 'N/A'}
                            </Typography>
                            <Typography variant="body2" mb={0.5}>
                              <strong>Tier:</strong> {selectedDispute.disputer.tier || 'N/A'}
                            </Typography>
                            {selectedDispute.disputer.height_feet && selectedDispute.disputer.height_inches && (
                              <Typography variant="body2" mb={0.5}>
                                <strong>Height:</strong> {selectedDispute.disputer.height_feet}'{selectedDispute.disputer.height_inches}"
                              </Typography>
                            )}
                            {selectedDispute.disputer.weight && (
                              <Typography variant="body2" mb={0.5}>
                                <strong>Weight:</strong> {selectedDispute.disputer.weight} lbs
                              </Typography>
                            )}
                            {selectedDispute.disputer.reach && (
                              <Typography variant="body2" mb={0.5}>
                                <strong>Reach:</strong> {selectedDispute.disputer.reach}"
                              </Typography>
                            )}
                            {selectedDispute.disputer.stance && (
                              <Typography variant="body2" mb={0.5}>
                                <strong>Stance:</strong> {selectedDispute.disputer.stance}
                              </Typography>
                            )}
                            {selectedDispute.disputer.platform && (
                              <Typography variant="body2" mb={0.5}>
                                <strong>Platform:</strong> {selectedDispute.disputer.platform}
                              </Typography>
                            )}
                          </>
                        )}
                      </Box>
                      {/* Opponent Info */}
                      <Box>
                        <Typography variant="subtitle2" fontWeight="bold" mb={1}>
                          Opponent (Being Disputed Against)
                        </Typography>
                        <Typography variant="body2" mb={0.5}>
                          <strong>Name:</strong> {selectedDispute.fighter2_name ||
                            selectedDispute.opponent?.name ||
                            'Unknown'}
                        </Typography>
                        {selectedDispute.opponent && (
                          <>
                            <Typography variant="body2" mb={0.5}>
                              <strong>Weight Class:</strong> {selectedDispute.opponent.weight_class || 'N/A'}
                            </Typography>
                            <Typography variant="body2" mb={0.5}>
                              <strong>Tier:</strong> {selectedDispute.opponent.tier || 'N/A'}
                            </Typography>
                            {selectedDispute.opponent.height_feet && selectedDispute.opponent.height_inches && (
                              <Typography variant="body2" mb={0.5}>
                                <strong>Height:</strong> {selectedDispute.opponent.height_feet}'{selectedDispute.opponent.height_inches}"
                              </Typography>
                            )}
                            {selectedDispute.opponent.weight && (
                              <Typography variant="body2" mb={0.5}>
                                <strong>Weight:</strong> {selectedDispute.opponent.weight} lbs
                              </Typography>
                            )}
                            {selectedDispute.opponent.reach && (
                              <Typography variant="body2" mb={0.5}>
                                <strong>Reach:</strong> {selectedDispute.opponent.reach}"
                              </Typography>
                            )}
                            {selectedDispute.opponent.stance && (
                              <Typography variant="body2" mb={0.5}>
                                <strong>Stance:</strong> {selectedDispute.opponent.stance}
                              </Typography>
                            )}
                            {selectedDispute.opponent.platform && (
                              <Typography variant="body2" mb={0.5}>
                                <strong>Platform:</strong> {selectedDispute.opponent.platform}
                              </Typography>
                            )}
                          </>
                        )}
                      </Box>
                    </Box>
                    {selectedDispute.fight_link && (
                      <Box mt={2}>
                        <Typography variant="body2" mb={1}>
                          <strong>Fight Link:</strong>
                        </Typography>
                        <Link
                          href={selectedDispute.fight_link}
                          target="_blank"
                          rel="noopener noreferrer"
                          sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}
                        >
                          {selectedDispute.fight_link}
                          <OpenInNew fontSize="small" />
                        </Link>
                      </Box>
                    )}
                  </Paper>

                  <Paper sx={{ p: 2, mb: 2 }}>
                    <Typography variant="h6" gutterBottom>
                      Dispute Reason
                    </Typography>
                    <Typography variant="body2">{selectedDispute.reason}</Typography>
                  </Paper>

                  {selectedDispute.evidence_urls && selectedDispute.evidence_urls.length > 0 && (
                    <Paper sx={{ p: 2 }}>
                      <Typography variant="h6" gutterBottom>
                        Evidence Links
                      </Typography>
                      <List>
                        {selectedDispute.evidence_urls.map((url, index) => (
                          <ListItem key={index}>
                            <Link
                              href={url}
                              target="_blank"
                              rel="noopener noreferrer"
                              sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}
                            >
                              <Description sx={{ mr: 1 }} />
                              Evidence #{index + 1}
                              <OpenInNew fontSize="small" />
                            </Link>
                          </ListItem>
                        ))}
                      </List>
                    </Paper>
                  )}

                  {selectedDispute.resolution && (
                    <Paper sx={{ p: 2, mt: 2 }}>
                      <Typography variant="h6" gutterBottom>
                        Resolution
                      </Typography>
                      <Typography variant="body2" mb={1}>
                        {selectedDispute.resolution}
                      </Typography>
                      {selectedDispute.admin_notes && (
                        <Typography variant="body2" color="text.secondary">
                          <strong>Admin Notes:</strong> {selectedDispute.admin_notes}
                        </Typography>
                      )}
                    </Paper>
                  )}
                </Box>
              )}

              {/* Messages Tab */}
              {disputeDialogTab === 1 && (
                <Box>
                  <Paper sx={{ p: 2, mb: 2, maxHeight: 400, overflow: 'auto' }}>
                    <Typography variant="h6" gutterBottom>
                      Messages
                    </Typography>
                    {messages.length === 0 ? (
                      <Alert severity="info">No messages yet</Alert>
                    ) : (
                      <List>
                        {messages.map((message) => (
                          <ListItem key={message.id} sx={{ flexDirection: 'column', alignItems: 'flex-start' }}>
                            <Box
                              sx={{
                                p: 1.5,
                                borderRadius: 1,
                                bgcolor:
                                  message.sender_type === 'admin'
                                    ? 'primary.light'
                                    : 'grey.200',
                                width: '100%',
                                mb: 1,
                              }}
                            >
                              <Box display="flex" justifyContent="space-between" mb={0.5}>
                                <Typography variant="caption" fontWeight="bold">
                                  {message.sender_type === 'admin'
                                    ? 'Admin'
                                    : message.sender?.email || 'Fighter'}
                                </Typography>
                                <Typography variant="caption" color="text.secondary">
                                  {formatDate(message.created_at)}
                                </Typography>
                              </Box>
                              <Typography variant="body2">{message.message}</Typography>
                            </Box>
                          </ListItem>
                        ))}
                      </List>
                    )}
                  </Paper>

                  {selectedDispute.status !== 'Resolved' && (
                    <Box>
                      <TextField
                        fullWidth
                        multiline
                        rows={3}
                        label="Send a message to the fighter"
                        value={newMessage}
                        onChange={(e) => setNewMessage(e.target.value)}
                        placeholder="Type your message here..."
                        sx={{ mb: 1 }}
                      />
                      <Button
                        variant="contained"
                        startIcon={<Send />}
                        onClick={handleSendMessage}
                        disabled={!newMessage.trim() || sendingMessage}
                      >
                        {sendingMessage ? 'Sending...' : 'Send Message'}
                      </Button>
                    </Box>
                  )}
                </Box>
              )}

              {/* Resolve Tab */}
              {disputeDialogTab === 2 && selectedDispute.status !== 'Resolved' && (
                <Box>
                  <FormControl fullWidth sx={{ mb: 2 }}>
                    <InputLabel id="resolution-type-label">Resolution Type</InputLabel>
                    <Select
                      value={resolutionType}
                      onChange={(e) => setResolutionType(e.target.value as any)}
                      label="Resolution Type"
                      labelId="resolution-type-label"
                      aria-labelledby="resolution-type-label"
                    >
                      <MenuItem value="warning" aria-label="Warning">Warning</MenuItem>
                      <MenuItem value="give_win_to_submitter" aria-label="Give Win to Submitter (Update Records)">Give Win to Submitter (Update Records)</MenuItem>
                      <MenuItem value="one_week_suspension" aria-label="One Week Suspension">One Week Suspension</MenuItem>
                      <MenuItem value="two_week_suspension" aria-label="Two Week Suspension">Two Week Suspension</MenuItem>
                      <MenuItem value="one_month_suspension" aria-label="One Month Suspension">One Month Suspension</MenuItem>
                      <MenuItem value="banned_from_league" aria-label="Banned from League">Banned from League</MenuItem>
                      <MenuItem value="dispute_invalid" aria-label="Dispute Invalid">Dispute Invalid</MenuItem>
                      <MenuItem value="other" aria-label="Other">Other</MenuItem>
                    </Select>
                  </FormControl>
                  <TextField
                    fullWidth
                    multiline
                    rows={3}
                    label="Resolution Details"
                    value={resolution}
                    onChange={(e) => setResolution(e.target.value)}
                    placeholder="Describe the resolution..."
                    sx={{ mb: 2 }}
                    required
                  />
                  <TextField
                    fullWidth
                    multiline
                    rows={3}
                    label="Message to Disputer (Optional)"
                    value={messageToDisputer}
                    onChange={(e) => setMessageToDisputer(e.target.value)}
                    placeholder="Message to send to the fighter who submitted the dispute..."
                    sx={{ mb: 2 }}
                  />
                  <TextField
                    fullWidth
                    multiline
                    rows={3}
                    label="Message to Opponent (Optional)"
                    value={messageToOpponent}
                    onChange={(e) => setMessageToOpponent(e.target.value)}
                    placeholder="Message to send to the opponent being disputed against..."
                    sx={{ mb: 2 }}
                  />
                  <TextField
                    fullWidth
                    multiline
                    rows={4}
                    label="Admin Notes (Optional)"
                    value={adminNotes}
                    onChange={(e) => setAdminNotes(e.target.value)}
                    placeholder="Additional notes about the resolution..."
                    sx={{ mb: 2 }}
                  />
                  <Alert severity="info" sx={{ mb: 2 }}>
                    {resolutionType === 'give_win_to_submitter' && 
                      'This will create fight records for both fighters and update their stats in real-time.'}
                    {resolutionType === 'one_week_suspension' && 
                      'The opponent will be suspended for 7 days.'}
                    {resolutionType === 'two_week_suspension' && 
                      'The opponent will be suspended for 14 days.'}
                    {resolutionType === 'one_month_suspension' && 
                      'The opponent will be suspended for 30 days.'}
                    {resolutionType === 'banned_from_league' && 
                      'The opponent will be permanently banned from the league.'}
                  </Alert>
                  <Button
                    variant="contained"
                    color="success"
                    onClick={handleResolveDispute}
                    disabled={!resolution.trim()}
                    fullWidth
                  >
                    Resolve Dispute
                  </Button>
                </Box>
              )}
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDisputeDialogOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>

      {/* Delete All Resolved Dialog */}
      <Dialog
        open={deleteDialogOpen}
        onClose={() => {
          if (!deleting) {
            console.log('Closing delete dialog');
            setDeleteDialogOpen(false);
          }
        }}
        aria-labelledby="delete-dialog-title"
        aria-describedby="delete-dialog-description"
        keepMounted={false}
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
      >
        <DialogTitle id="delete-dialog-title">
          Delete All Resolved Disputes?
        </DialogTitle>
        <DialogContent>
          <Alert severity="warning" sx={{ mb: 2 }}>
            This action cannot be undone!
          </Alert>
          <Typography id="delete-dialog-description">
            You are about to delete all {disputes.filter(d => d.status === 'Resolved').length} resolved disputes and their associated messages.
            This action is permanent and cannot be reversed.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button 
            onClick={() => {
              console.log('Cancel button clicked');
              setDeleteDialogOpen(false);
            }} 
            disabled={deleting}
          >
            Cancel
          </Button>
          <Button
            onClick={() => {
              console.log('Delete All button clicked, calling handleDeleteAllResolved');
              handleDeleteAllResolved();
            }}
            color="error"
            variant="contained"
            disabled={deleting}
            startIcon={deleting ? <CircularProgress size={20} /> : <DeleteForever />}
          >
            {deleting ? 'Deleting...' : 'Delete All'}
          </Button>
        </DialogActions>
      </Dialog>

      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
        message={snackbar.message}
      />
    </Box>
  );
};

export default DisputeManagement;

