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
  Avatar,
  Alert,
  Paper,
  Divider,
  Grid,
  LinearProgress,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  CircularProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
} from '@mui/material';
import {
  Gavel,
  Warning,
  CheckCircle,
  Cancel,
  Info,
  ExpandMore,
  Person,
  SportsMma,
  Schedule,
  Description,
  Send,
  DeleteForever,
} from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';
import { disputeService } from '../../services/disputeService';
import { supabase } from '../../services/supabase';
import { Dispute, ScheduledFight, DisputeMessage } from '../../types';

const DisputeResolution: React.FC = () => {
  const { fighterProfile, user } = useAuth();
  const [disputes, setDisputes] = useState<Dispute[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedDispute, setSelectedDispute] = useState<Dispute | null>(null);
  const [resolutionDialogOpen, setResolutionDialogOpen] = useState(false);
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [resolution, setResolution] = useState('');
  const [adminNotes, setAdminNotes] = useState('');
  const [newDispute, setNewDispute] = useState({
    fight_id: '',
    reason: '',
    evidence_urls: [] as string[],
    fighter1_name: '',
    fighter2_name: ''
  });
  const [evidenceUrl, setEvidenceUrl] = useState('');
  const [messages, setMessages] = useState<DisputeMessage[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [sendingMessage, setSendingMessage] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    loadDisputes();

    // Subscribe to real-time changes in disputes table
    // Use a unique channel name per component instance to avoid conflicts
    const channelName = `disputes_changes_fighter_${fighterProfile?.id || 'default'}`;
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
          console.log('Dispute changed (real-time) in FighterProfile:', payload);
          console.log('Event type:', payload.eventType);
          console.log('Full payload:', JSON.stringify(payload, null, 2));
          
          // For DELETE events, immediately filter out the deleted dispute for instant UI update
          if (payload.eventType === 'DELETE') {
            const deletedId = payload.old?.id;
            const deletedDisputerId = payload.old?.disputer_id;
            const deletedOpponentId = payload.old?.opponent_id;
            const currentFighterId = fighterProfile?.id;
            
            // Check if the deleted dispute belongs to this fighter
            const belongsToFighter = currentFighterId && (
              deletedDisputerId === currentFighterId || 
              deletedOpponentId === currentFighterId
            );
            
            if (deletedId && belongsToFighter) {
              setDisputes(prevDisputes => {
                const filtered = prevDisputes.filter(d => d.id !== deletedId);
                console.log('Fighter: Filtered out deleted dispute ID:', deletedId, 'Remaining:', filtered.length);
                return filtered;
              });
            } else if (!deletedId || belongsToFighter) {
              // If we can't get the ID or it belongs to this fighter, filter by status (fallback for bulk deletes)
              console.log('Fighter: DELETE event received, filtering all resolved disputes');
              setDisputes(prevDisputes => {
                const filtered = prevDisputes.filter(d => d.status !== 'Resolved');
                console.log('Fighter: Filtered out resolved disputes. Remaining:', filtered.length);
                return filtered;
              });
            }
            
            // Always reload for DELETE events to ensure consistency
            // Use multiple delays to catch any delayed updates
            setTimeout(() => {
              console.log('Fighter: Reloading disputes after DELETE event');
              loadDisputes();
            }, 100);
            
            setTimeout(() => {
              console.log('Fighter: Second reload after DELETE event');
              loadDisputes();
            }, 500);
            
            setTimeout(() => {
              console.log('Fighter: Third reload after DELETE event (final check)');
              loadDisputes();
            }, 1500);
          } else {
            // For other events (INSERT, UPDATE), reload after a short delay
            setTimeout(() => {
              console.log('Fighter: Reloading disputes after real-time event');
              loadDisputes();
            }, 200);
          }
        }
      )
      .subscribe();

    // Set up polling as a fallback (every 3 seconds) to catch deletions that real-time might miss
    // This is especially important for bulk deletes
    const pollInterval = setInterval(() => {
      console.log('Fighter: Polling for dispute updates...');
      loadDisputes();
    }, 3000);

    // Also reload when the window/tab regains focus (in case real-time events were missed)
    const handleFocus = () => {
      console.log('Fighter: Window regained focus, reloading disputes');
      loadDisputes();
    };
    window.addEventListener('focus', handleFocus);

    // Cleanup subscription and intervals on unmount
    return () => {
      supabase.removeChannel(disputesChannel);
      clearInterval(pollInterval);
      window.removeEventListener('focus', handleFocus);
    };
  }, [fighterProfile?.id]); // Re-subscribe if fighter profile changes

  const loadDisputes = async () => {
    try {
      setLoading(true);
      // Get the fighter profile ID (primary key from fighter_profiles table)
      if (!fighterProfile?.user_id) {
        console.warn('No fighter profile user_id available');
        setDisputes([]);
        return;
      }

      const { data: profile } = await supabase
        .from('fighter_profiles')
        .select('id')
        .eq('user_id', fighterProfile.user_id)
        .single();

      if (!profile?.id) {
        console.warn('Unable to find fighter profile ID');
        setDisputes([]);
        return;
      }

      const fighterId = profile.id;
      console.log('Loading disputes for fighter profile ID:', fighterId);
      const disputesData = await disputeService.getDisputes(fighterId);
      
      // Force state update by creating a new array reference
      // The database query should already exclude deleted disputes, but we ensure it here
      setDisputes([...disputesData]);
      console.log('Fighter: Disputes reloaded:', disputesData.length, 'total disputes');
      console.log('Fighter: Resolved disputes:', disputesData.filter(d => d.status === 'Resolved').length);
      console.log('Fighter: Active disputes:', disputesData.filter(d => d.status !== 'Resolved').length);
      console.log('Fighter: All dispute IDs:', disputesData.map(d => ({ id: d.id, status: d.status, disputer_id: d.disputer_id, opponent_id: d.opponent_id })));
    } catch (error) {
      console.error('Error loading disputes:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadMessages = async (disputeId: string) => {
    try {
      const messagesData = await disputeService.getDisputeMessages(disputeId);
      setMessages(messagesData);
    } catch (error) {
      console.error('Error loading messages:', error);
    }
  };

  const handleResolveDispute = async (disputeId: string) => {
    if (!user) return;
    
    try {
      // Map old resolution values to new resolution types
      let resolutionType: 'warning' | 'give_win_to_submitter' | 'one_week_suspension' | 'two_week_suspension' | 'one_month_suspension' | 'banned_from_league' | 'dispute_invalid' | 'other' = 'other';
      
      if (resolution.includes('Wins')) {
        resolutionType = 'give_win_to_submitter';
      } else if (resolution === 'Dispute Invalid') {
        resolutionType = 'dispute_invalid';
      } else if (resolution === 'No Contest') {
        resolutionType = 'other';
      }
      
      await disputeService.resolveDispute(
        disputeId,
        resolutionType,
        resolution,
        adminNotes,
        undefined, // messageToDisputer
        undefined, // messageToOpponent
        user.id
      );
      setResolutionDialogOpen(false);
      setResolution('');
      setAdminNotes('');
      setSelectedDispute(null);
      loadDisputes();
      alert('Dispute resolved successfully!');
    } catch (error) {
      console.error('Error resolving dispute:', error);
      alert('Failed to resolve dispute');
    }
  };

  const handleViewDispute = async (dispute: Dispute) => {
    const fullDispute = await disputeService.getDispute(dispute.id);
    setSelectedDispute(fullDispute);
    setResolutionDialogOpen(true);
    if (fullDispute) {
      await loadMessages(fullDispute.id);
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
        'fighter'
      );
      setNewMessage('');
      await loadMessages(selectedDispute.id);
      await loadDisputes();
    } catch (error: any) {
      console.error('Error sending message:', error);
      alert('Failed to send message');
    } finally {
      setSendingMessage(false);
    }
  };

  const handleCreateDispute = async () => {
    if (!fighterProfile) return;
    
    try {
      // Get the fighter profile ID (primary key from fighter_profiles table)
      const { data: profile } = await supabase
        .from('fighter_profiles')
        .select('id')
        .eq('user_id', fighterProfile.user_id)
        .single();

      if (!profile?.id) {
        throw new Error('Unable to find fighter profile ID');
      }

      const disputerFighterProfileId = profile.id;

      // Validate fight_id if provided - it must be a valid UUID
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      let validFightId: string | undefined = undefined;

      if (newDispute.fight_id && newDispute.fight_id.trim()) {
        if (uuidRegex.test(newDispute.fight_id.trim())) {
          validFightId = newDispute.fight_id.trim();
        } else {
          // If it's not a valid UUID, it might be a fight description - make fight_id optional
          console.warn('Fight ID provided is not a valid UUID, creating dispute without fight_id:', newDispute.fight_id);
        }
      }

      await disputeService.createDispute({
        fight_id: validFightId,
        reason: newDispute.reason,
        evidence_urls: newDispute.evidence_urls,
        dispute_category: 'other',
        fighter1_name: newDispute.fighter1_name.trim() || fighterProfile?.name || undefined,
        fighter2_name: newDispute.fighter2_name.trim() || undefined,
      }, disputerFighterProfileId);
      setCreateDialogOpen(false);
      setNewDispute({
        fight_id: '',
        reason: '',
        evidence_urls: [],
        fighter1_name: '',
        fighter2_name: ''
      });
      setEvidenceUrl('');
      loadDisputes();
      alert('Dispute created successfully!');
    } catch (error: any) {
      console.error('Error creating dispute:', error);
      
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
      } else if (typeof error === 'object') {
        // Try to extract meaningful information from error object
        errorMessage = JSON.stringify(error, null, 2);
      }
      
      alert('Failed to create dispute: ' + errorMessage);
    }
  };

  const addEvidenceUrl = () => {
    if (evidenceUrl.trim()) {
      setNewDispute({
        ...newDispute,
        evidence_urls: [...newDispute.evidence_urls, evidenceUrl.trim()]
      });
      setEvidenceUrl('');
    }
  };

  const removeEvidenceUrl = (index: number) => {
    setNewDispute({
      ...newDispute,
      evidence_urls: newDispute.evidence_urls.filter((_, i) => i !== index)
    });
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Open': return 'warning';
      case 'In Review': return 'info';
      case 'Resolved': return 'success';
      case 'Closed': return 'error';
      default: return 'default';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'Open': return <Warning />;
      case 'In Review': return <Info />;
      case 'Resolved': return <CheckCircle />;
      case 'Closed': return <Cancel />;
      default: return <Info />;
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const isAdmin = user?.role === 'admin';

  const handleDeleteAllResolved = async () => {
    try {
      setDeleting(true);
      const deletedCount = await disputeService.deleteAllResolvedDisputes();
      setDeleteDialogOpen(false);
      
      // Immediately remove resolved disputes from current state for instant UI update
      setDisputes(prevDisputes => {
        const filtered = prevDisputes.filter(d => d.status !== 'Resolved');
        console.log('Immediately filtered out resolved disputes. Remaining:', filtered.length);
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
      
      alert(`Successfully deleted ${deletedCount} resolved dispute${deletedCount !== 1 ? 's' : ''}`);
    } catch (error: any) {
      console.error('Error deleting resolved disputes:', error);
      alert('Failed to delete resolved disputes');
    } finally {
      setDeleting(false);
    }
  };

  const resolvedDisputesCount = disputes.filter(d => d.status === 'Resolved').length;

  return (
    <Box sx={{ p: 3 }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">
          Dispute Resolution
        </Typography>
        <Box display="flex" gap={2}>
          {isAdmin && resolvedDisputesCount > 0 && (
            <Button
              variant="outlined"
              color="error"
              startIcon={<DeleteForever />}
              onClick={(e) => {
                e.currentTarget.blur(); // Remove focus from button before opening dialog
                setDeleteDialogOpen(true);
              }}
            >
              Delete All Resolved ({resolvedDisputesCount})
            </Button>
          )}
          {!isAdmin && (
            <Button
              variant="contained"
              startIcon={<Gavel />}
              onClick={(e) => {
                e.currentTarget.blur();
                setCreateDialogOpen(true);
              }}
            >
              Create Dispute
            </Button>
          )}
        </Box>
      </Box>

      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        {isAdmin 
          ? 'Review and resolve fight disputes. Disputes occur when fighters submit conflicting results for the same fight.'
          : 'Create disputes for fights with conflicting results or other issues that need admin review.'
        }
      </Typography>

      {/* Disputes List */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            {isAdmin ? 'All Disputes' : 'Your Disputes'}
          </Typography>
          {disputes.length === 0 ? (
            <Alert severity="info">No disputes found</Alert>
          ) : (
            <List>
              {disputes.map((dispute) => (
                <ListItem key={dispute.id}>
                  <ListItemText
                    primary={
                      <Box display="flex" alignItems="center" gap={1}>
                        {getStatusIcon(dispute.status)}
                        <Typography variant="subtitle1">
                          Fight Dispute #{dispute.id.slice(-8)}
                        </Typography>
                        <Chip
                          label={dispute.status}
                          color={getStatusColor(dispute.status)}
                          size="small"
                        />
                      </Box>
                    }
                    secondary={
                      <>
                        <Typography variant="body2" color="text.secondary" component="span" display="block">
                          {dispute.reason}
                        </Typography>
                        <Typography variant="body2" color="text.secondary" component="span" display="block">
                          Created: {formatDate(dispute.created_at)}
                        </Typography>
                        {dispute.resolved_at && (
                          <Typography variant="body2" color="text.secondary" component="span" display="block">
                            Resolved: {formatDate(dispute.resolved_at)}
                          </Typography>
                        )}
                      </>
                    }
                  />
                  <ListItemSecondaryAction>
                    <Button
                      size="small"
                      onClick={() => handleViewDispute(dispute)}
                    >
                      {isAdmin ? 'Resolve' : 'View Details'}
                    </Button>
                  </ListItemSecondaryAction>
                </ListItem>
              ))}
            </List>
          )}
        </CardContent>
      </Card>

      {/* Dispute Details Dialog */}
      <Dialog 
        open={resolutionDialogOpen} 
        onClose={() => setResolutionDialogOpen(false)} 
        maxWidth="md" 
        fullWidth
        aria-labelledby="dispute-resolution-dialog-title"
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
        keepMounted={false}
      >
        <DialogTitle id="dispute-resolution-dialog-title">
          {isAdmin ? 'Resolve Dispute' : 'Dispute Details'}
        </DialogTitle>
        <DialogContent>
          {selectedDispute && (
            <Box>
              <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2, mb: 3 }}>
                <Paper sx={{ p: 2 }}>
                  <Typography variant="h6" gutterBottom>
                    Dispute Information
                  </Typography>
                  <Box display="flex" alignItems="center" mb={1}>
                    <Info sx={{ mr: 1 }} />
                    <Typography variant="body2">
                      <strong>Status:</strong> {selectedDispute.status}
                    </Typography>
                  </Box>
                  <Box display="flex" alignItems="center" mb={1}>
                    <Schedule sx={{ mr: 1 }} />
                    <Typography variant="body2">
                      <strong>Created:</strong> {formatDate(selectedDispute.created_at)}
                    </Typography>
                  </Box>
                  <Box display="flex" alignItems="center" mb={1}>
                    <Person sx={{ mr: 1 }} />
                    <Typography variant="body2">
                      <strong>Disputer:</strong>{' '}
                      {selectedDispute.fighter1_name || selectedDispute.disputer?.name || 'N/A'}
                    </Typography>
                  </Box>
                  {selectedDispute.fighter2_name && (
                    <Box display="flex" alignItems="center" mb={1}>
                      <Person sx={{ mr: 1 }} />
                      <Typography variant="body2">
                        <strong>Opponent:</strong> {selectedDispute.fighter2_name || selectedDispute.opponent?.name || 'N/A'}
                      </Typography>
                    </Box>
                  )}
                  {selectedDispute.fight_link && (
                    <Box display="flex" alignItems="center" mb={1}>
                      <Description sx={{ mr: 1 }} />
                      <Button
                        href={selectedDispute.fight_link}
                        target="_blank"
                        rel="noopener noreferrer"
                        size="small"
                      >
                        View Fight Link
                      </Button>
                    </Box>
                  )}
                </Paper>
                <Paper sx={{ p: 2 }}>
                  <Typography variant="h6" gutterBottom>
                    Dispute Details
                  </Typography>
                  <Box>
                    <Typography variant="body2" mb={1}>
                      <strong>Category:</strong>{' '}
                      {selectedDispute.dispute_category
                        ? selectedDispute.dispute_category.replace(/_/g, ' ').replace(/\b\w/g, (l) => l.toUpperCase())
                        : 'Other'}
                    </Typography>
                    <Typography variant="body2" mb={1}>
                      <strong>Status:</strong> {selectedDispute.status}
                    </Typography>
                    <Typography variant="body2" mb={1}>
                      <strong>Created:</strong> {formatDate(selectedDispute.created_at)}
                    </Typography>
                    {selectedDispute.resolved_at && (
                      <Typography variant="body2">
                        <strong>Resolved:</strong> {formatDate(selectedDispute.resolved_at)}
                      </Typography>
                    )}
                  </Box>
                </Paper>
              </Box>

              <Accordion>
                <AccordionSummary expandIcon={<ExpandMore />}>
                  <Typography variant="h6">Dispute Reason</Typography>
                </AccordionSummary>
                <AccordionDetails>
                  <Typography variant="body2">
                    {selectedDispute.reason}
                  </Typography>
                </AccordionDetails>
              </Accordion>

              {selectedDispute.evidence_urls && selectedDispute.evidence_urls.length > 0 && (
                <Accordion>
                  <AccordionSummary expandIcon={<ExpandMore />}>
                    <Typography variant="h6">Evidence</Typography>
                  </AccordionSummary>
                  <AccordionDetails>
                    <List>
                      {selectedDispute.evidence_urls.map((url, index) => (
                        <ListItem key={index}>
                          <ListItemText
                            primary={
                              <Button
                                href={url}
                                target="_blank"
                                rel="noopener noreferrer"
                                startIcon={<Description />}
                              >
                                Evidence #{index + 1}
                              </Button>
                            }
                          />
                        </ListItem>
                      ))}
                    </List>
                  </AccordionDetails>
                </Accordion>
              )}

              {/* Messages Section */}
              <Accordion defaultExpanded={!isAdmin}>
                <AccordionSummary expandIcon={<ExpandMore />}>
                  <Typography variant="h6">Messages</Typography>
                  {messages.length > 0 && (
                    <Chip label={messages.length} size="small" sx={{ ml: 1 }} />
                  )}
                </AccordionSummary>
                <AccordionDetails>
                  {messages.length === 0 ? (
                    <Alert severity="info">No messages yet</Alert>
                  ) : (
                    <Box sx={{ maxHeight: 300, overflow: 'auto', mb: 2 }}>
                      {messages.map((message) => (
                        <Paper
                          key={message.id}
                          sx={{
                            p: 1.5,
                            mb: 1,
                            bgcolor:
                              message.sender_type === 'admin'
                                ? 'primary.light'
                                : 'grey.200',
                          }}
                        >
                          <Box display="flex" justifyContent="space-between" mb={0.5}>
                            <Typography variant="caption" fontWeight="bold">
                              {message.sender_type === 'admin'
                                ? 'Admin'
                                : message.sender?.email || 'You'}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              {formatDate(message.created_at)}
                            </Typography>
                          </Box>
                          <Typography variant="body2">{message.message}</Typography>
                        </Paper>
                      ))}
                    </Box>
                  )}
                  {!isAdmin && selectedDispute.status !== 'Resolved' && (
                    <Box>
                      <TextField
                        fullWidth
                        multiline
                        rows={2}
                        label="Send a message"
                        value={newMessage}
                        onChange={(e) => setNewMessage(e.target.value)}
                        placeholder="Type your message here..."
                        sx={{ mb: 1 }}
                      />
                      <Button
                        variant="contained"
                        onClick={handleSendMessage}
                        disabled={!newMessage.trim() || sendingMessage}
                        startIcon={sendingMessage ? <CircularProgress size={16} /> : <Send />}
                      >
                        {sendingMessage ? 'Sending...' : 'Send'}
                      </Button>
                    </Box>
                  )}
                </AccordionDetails>
              </Accordion>

              {selectedDispute.resolution && (
                <Accordion>
                  <AccordionSummary expandIcon={<ExpandMore />}>
                    <Typography variant="h6">Resolution</Typography>
                  </AccordionSummary>
                  <AccordionDetails>
                    <Typography variant="body2" mb={2}>
                      {selectedDispute.resolution}
                    </Typography>
                    {selectedDispute.admin_notes && (
                      <Typography variant="body2" color="text.secondary">
                        <strong>Admin Notes:</strong> {selectedDispute.admin_notes}
                      </Typography>
                    )}
                  </AccordionDetails>
                </Accordion>
              )}

              {isAdmin && selectedDispute.status === 'Open' && (
                <Box sx={{ mt: 3 }}>
                  <Typography variant="h6" gutterBottom>
                    Resolve Dispute
                  </Typography>
                  <FormControl fullWidth sx={{ mb: 2 }}>
                    <InputLabel id="resolution-label">Resolution</InputLabel>
                    <Select
                      value={resolution}
                      onChange={(e) => setResolution(e.target.value)}
                      label="Resolution"
                      labelId="resolution-label"
                      aria-labelledby="resolution-label"
                    >
                      <MenuItem value="Fighter 1 Wins" aria-label="Fighter 1 Wins">Fighter 1 Wins</MenuItem>
                      <MenuItem value="Fighter 2 Wins" aria-label="Fighter 2 Wins">Fighter 2 Wins</MenuItem>
                      <MenuItem value="Draw" aria-label="Draw">Draw</MenuItem>
                      <MenuItem value="No Contest" aria-label="No Contest">No Contest</MenuItem>
                      <MenuItem value="Dispute Invalid" aria-label="Dispute Invalid">Dispute Invalid</MenuItem>
                    </Select>
                  </FormControl>
                  <TextField
                    fullWidth
                    label="Admin Notes"
                    multiline
                    rows={3}
                    value={adminNotes}
                    onChange={(e) => setAdminNotes(e.target.value)}
                    placeholder="Additional notes about the resolution..."
                  />
                </Box>
              )}
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setResolutionDialogOpen(false)}>
            {isAdmin ? 'Cancel' : 'Close'}
          </Button>
          {isAdmin && selectedDispute?.status === 'Open' && (
            <Button
              onClick={() => handleResolveDispute(selectedDispute.id)}
              variant="contained"
              disabled={!resolution}
            >
              Resolve Dispute
            </Button>
          )}
        </DialogActions>
      </Dialog>

      {/* Create Dispute Dialog */}
      <Dialog 
        open={createDialogOpen} 
        onClose={() => setCreateDialogOpen(false)} 
        maxWidth="md" 
        fullWidth
        aria-labelledby="create-dispute-dialog-title"
      >
        <DialogTitle id="create-dispute-dialog-title">Create New Dispute</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr' }, gap: 2, mt: 1 }}>
            <TextField
              fullWidth
              label="Your Name (Fighter)"
              value={newDispute.fighter1_name || fighterProfile?.name || ''}
              onChange={(e) => setNewDispute({ ...newDispute, fighter1_name: e.target.value })}
              placeholder="Enter your fighter name"
              helperText="Your name as the disputer (defaults to your profile name)"
            />
            <TextField
              fullWidth
              label="Opponent Name"
              required
              value={newDispute.fighter2_name}
              onChange={(e) => setNewDispute({ ...newDispute, fighter2_name: e.target.value })}
              placeholder="Enter the opponent's fighter name"
              helperText="The name of the fighter you are disputing against"
            />
            <TextField
              fullWidth
              label="Fight ID (Optional)"
              value={newDispute.fight_id}
              onChange={(e) => setNewDispute({ ...newDispute, fight_id: e.target.value })}
              placeholder="Enter the scheduled fight UUID (optional)"
              helperText="If disputing a specific scheduled fight, enter its UUID. Otherwise, leave blank for a general dispute."
            />
            <TextField
              fullWidth
              label="Reason for Dispute"
              multiline
              rows={3}
              required
              value={newDispute.reason}
              onChange={(e) => setNewDispute({ ...newDispute, reason: e.target.value })}
              placeholder="Explain why you're disputing this fight result..."
            />
            <Box>
              <Typography variant="h6" gutterBottom>
                Evidence URLs
              </Typography>
              <Box display="flex" gap={1} mb={2}>
                <TextField
                  fullWidth
                  label="Evidence URL"
                  value={evidenceUrl}
                  onChange={(e) => setEvidenceUrl(e.target.value)}
                  placeholder="Screenshot, video, or other proof URL"
                />
                <Button onClick={addEvidenceUrl} variant="outlined">
                  Add
                </Button>
              </Box>
              {newDispute.evidence_urls.map((url, index) => (
                <Box key={index} display="flex" alignItems="center" gap={1} mb={1}>
                  <Typography variant="body2" sx={{ flexGrow: 1, overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {url}
                  </Typography>
                  <Button
                    size="small"
                    color="error"
                    onClick={() => removeEvidenceUrl(index)}
                  >
                    Remove
                  </Button>
                </Box>
              ))}
            </Box>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCreateDialogOpen(false)}>Cancel</Button>
          <Button
            onClick={handleCreateDispute}
            variant="contained"
            disabled={!newDispute.reason.trim() || !newDispute.fighter2_name.trim()}
          >
            Create Dispute
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete All Resolved Dialog */}
      <Dialog
        open={deleteDialogOpen}
        onClose={() => !deleting && setDeleteDialogOpen(false)}
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
            You are about to delete all {resolvedDisputesCount} resolved disputes and their associated messages.
            This action is permanent and cannot be reversed.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)} disabled={deleting}>
            Cancel
          </Button>
          <Button
            onClick={handleDeleteAllResolved}
            color="error"
            variant="contained"
            disabled={deleting}
            startIcon={deleting ? <CircularProgress size={20} /> : <DeleteForever />}
          >
            {deleting ? 'Deleting...' : 'Delete All'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default DisputeResolution;
export {};