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
  Alert,
  Paper,
  Divider,
  Link,
  Tabs,
  Tab,
  IconButton,
  CircularProgress,
  Snackbar,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
} from '@mui/material';
import {
  Link as LinkIcon,
  CheckCircle,
  Cancel,
  Visibility,
  Edit,
  Person,
  CalendarToday,
  SportsMma,
  EmojiEvents,
  DeleteForever,
} from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';
import { fightUrlSubmissionService } from '../../services/fightUrlSubmissionService';
import { FightUrlSubmission } from '../../types';
import { supabase } from '../../services/supabase';

const FightUrlSubmissionManagement: React.FC = () => {
  const { user } = useAuth();
  const [submissions, setSubmissions] = useState<FightUrlSubmission[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedSubmission, setSelectedSubmission] = useState<FightUrlSubmission | null>(null);
  const [reviewDialogOpen, setReviewDialogOpen] = useState(false);
  const [adminNotes, setAdminNotes] = useState('');
  const [status, setStatus] = useState<'Pending' | 'Reviewed' | 'Rejected' | 'Approved'>('Pending');
  const [activeTab, setActiveTab] = useState(0);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });
  const [reviewing, setReviewing] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    loadSubmissions();

    // Subscribe to real-time changes in fight_url_submissions table
    const channelName = 'fight_url_submissions_changes_admin';
    const submissionsChannel = supabase
      .channel(channelName)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'fight_url_submissions',
        },
        (payload) => {
          console.log('Fight URL submission changed (real-time) in Admin:', payload);
          console.log('Event type:', payload.eventType);
          console.log('Full payload:', JSON.stringify(payload, null, 2));
          
          // For DELETE events, immediately filter out the deleted submission for instant UI update
          if (payload.eventType === 'DELETE') {
            const deletedId = payload.old?.id;
            const deletedStatus = payload.old?.status;
            
            if (deletedId) {
              setSubmissions(prevSubmissions => {
                const filtered = prevSubmissions.filter(s => s.id !== deletedId);
                console.log('Admin: Filtered out deleted submission ID:', deletedId, 'Remaining:', filtered.length);
                return filtered;
              });
            } else if (deletedStatus === 'Approved' || deletedStatus === 'Rejected') {
              // If we can't get the ID, filter by status instead (fallback for bulk deletes)
              console.log('Admin: DELETE event received but no ID found, filtering all approved/rejected submissions');
              setSubmissions(prevSubmissions => {
                const filtered = prevSubmissions.filter(s => s.status !== 'Approved' && s.status !== 'Rejected');
                console.log('Admin: Filtered out approved/rejected submissions. Remaining:', filtered.length);
                return filtered;
              });
            }
          }
          
          // Always reload to ensure consistency (especially for bulk deletions)
          setTimeout(() => {
            console.log('Admin: Reloading submissions after real-time event');
            loadSubmissions();
          }, 200);
        }
      )
      .subscribe();

    // Cleanup subscription on unmount
    return () => {
      supabase.removeChannel(submissionsChannel);
    };
  }, []);

  const loadSubmissions = async () => {
    try {
      setLoading(true);
      const allSubmissions = await fightUrlSubmissionService.getAllSubmissions();
      setSubmissions(allSubmissions);
    } catch (error: any) {
      console.error('Error loading submissions:', error);
      setSnackbar({ open: true, message: 'Failed to load submissions', severity: 'error' });
    } finally {
      setLoading(false);
    }
  };

  const handleViewSubmission = (submission: FightUrlSubmission) => {
    setSelectedSubmission(submission);
    setAdminNotes(submission.admin_notes || '');
    setStatus(submission.status);
    setReviewDialogOpen(true);
  };

  const handleReviewSubmission = async () => {
    if (!selectedSubmission || !user?.id) return;

    try {
      setReviewing(true);
      await fightUrlSubmissionService.updateSubmission(selectedSubmission.id, {
        status,
        admin_notes: adminNotes.trim() || undefined,
        reviewed_by: user.id,
      });
      setReviewDialogOpen(false);
      setSelectedSubmission(null);
      setAdminNotes('');
      await loadSubmissions();
      setSnackbar({ 
        open: true, 
        message: `Submission ${status.toLowerCase()} successfully`, 
        severity: 'success' 
      });
    } catch (error: any) {
      console.error('Error reviewing submission:', error);
      setSnackbar({ open: true, message: 'Failed to review submission', severity: 'error' });
    } finally {
      setReviewing(false);
    }
  };

  const handleDeleteAllApprovedAndRejected = async () => {
    try {
      setDeleting(true);
      console.log('Starting deletion of approved/rejected submissions...');
      
      const deletedCount = await fightUrlSubmissionService.deleteAllApprovedAndRejected();
      console.log('Deletion completed, deleted count:', deletedCount);
      
      setDeleteDialogOpen(false);
      
      // Immediately filter out approved/rejected submissions from current state
      setSubmissions(prevSubmissions => {
        const filtered = prevSubmissions.filter(s => s.status !== 'Approved' && s.status !== 'Rejected');
        console.log('Admin: Immediately filtered out approved/rejected submissions. Remaining:', filtered.length);
        return filtered;
      });
      
      // Force multiple reloads to ensure consistency
      // Sometimes real-time events don't fire immediately, so we reload manually
      await new Promise(resolve => setTimeout(resolve, 200));
      await loadSubmissions();
      
      // Multiple reloads at different intervals to catch any delayed updates
      setTimeout(async () => {
        console.log('Admin: Second reload after deletion');
        await loadSubmissions();
      }, 500);
      
      setTimeout(async () => {
        console.log('Admin: Third reload after deletion');
        await loadSubmissions();
      }, 1500);
      
      setTimeout(async () => {
        console.log('Admin: Final reload after deletion');
        await loadSubmissions();
      }, 3000);
      
      setSnackbar({ 
        open: true, 
        message: `Successfully deleted ${deletedCount} approved/rejected submission${deletedCount !== 1 ? 's' : ''}`, 
        severity: 'success' 
      });
    } catch (error: any) {
      console.error('Error deleting approved/rejected submissions:', error);
      console.error('Error details:', JSON.stringify(error, null, 2));
      setSnackbar({ 
        open: true, 
        message: `Failed to delete submissions: ${error?.message || 'Unknown error'}`, 
        severity: 'error' 
      });
    } finally {
      setDeleting(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Approved': return 'success';
      case 'Rejected': return 'error';
      case 'Reviewed': return 'info';
      default: return 'default';
    }
  };

  const filteredSubmissions = submissions.filter((submission) => {
    if (activeTab === 0) return submission.status === 'Pending';
    if (activeTab === 1) return submission.status === 'Reviewed';
    if (activeTab === 2) return submission.status === 'Approved';
    if (activeTab === 3) return submission.status === 'Rejected';
    return true;
  });

  return (
    <Card>
      <CardContent>
        <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
          <Typography variant="h5" sx={{ fontWeight: 'bold' }}>
            Fight URL Submissions
          </Typography>
        </Box>

        <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
          Review and manage fight URLs submitted by fighters for Live Events and Tournaments.
        </Typography>

        {/* Tabs for filtering */}
        <Box display="flex" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
          <Tabs value={activeTab} onChange={(_, newValue) => setActiveTab(newValue)}>
            <Tab label={`Pending (${submissions.filter(s => s.status === 'Pending').length})`} />
            <Tab label={`Reviewed (${submissions.filter(s => s.status === 'Reviewed').length})`} />
            <Tab label={`Approved (${submissions.filter(s => s.status === 'Approved').length})`} />
            <Tab label={`Rejected (${submissions.filter(s => s.status === 'Rejected').length})`} />
            <Tab label={`All (${submissions.length})`} />
          </Tabs>
          {(submissions.filter(s => s.status === 'Approved' || s.status === 'Rejected').length > 0) && (
            <Button
              variant="outlined"
              color="error"
              startIcon={<DeleteForever />}
              onClick={(e) => {
                e.currentTarget.blur();
                setDeleteDialogOpen(true);
              }}
            >
              Delete All Approved & Rejected ({submissions.filter(s => s.status === 'Approved' || s.status === 'Rejected').length})
            </Button>
          )}
        </Box>

        {/* Submissions List */}
        {loading ? (
          <Box display="flex" justifyContent="center" p={4}>
            <CircularProgress />
          </Box>
        ) : filteredSubmissions.length === 0 ? (
          <Alert severity="info">
            No {activeTab === 0 ? 'pending' : activeTab === 1 ? 'reviewed' : activeTab === 2 ? 'approved' : activeTab === 3 ? 'rejected' : ''} submissions found.
          </Alert>
        ) : (
          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Fighter</TableCell>
                  <TableCell>Event Type</TableCell>
                  <TableCell>Fight URL</TableCell>
                  <TableCell>Description</TableCell>
                  <TableCell>Related To</TableCell>
                  <TableCell>Submitted</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {filteredSubmissions.map((submission) => (
                  <TableRow key={submission.id}>
                    <TableCell>
                      <Box display="flex" alignItems="center" gap={1}>
                        <Person sx={{ fontSize: 20 }} />
                        <Typography variant="body2">
                          {submission.fighter?.name || 'Unknown'}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={submission.event_type}
                        size="small"
                        icon={submission.event_type === 'Tournament' ? <EmojiEvents /> : <SportsMma />}
                        color={submission.event_type === 'Tournament' ? 'warning' : 'primary'}
                      />
                    </TableCell>
                    <TableCell>
                      <Link
                        href={submission.fight_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}
                      >
                        <LinkIcon sx={{ fontSize: 16 }} />
                        <Typography variant="body2" sx={{ maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis' }}>
                          {submission.fight_url}
                        </Typography>
                      </Link>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" sx={{ maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis' }}>
                        {submission.description || 'N/A'}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      {submission.scheduled_fight && (
                        <Box>
                          <Typography variant="caption" display="block">
                            Scheduled Fight
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {submission.scheduled_fight.weight_class}
                          </Typography>
                        </Box>
                      )}
                      {submission.tournament && (
                        <Box>
                          <Typography variant="caption" display="block">
                            Tournament
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {submission.tournament.name}
                          </Typography>
                        </Box>
                      )}
                      {!submission.scheduled_fight && !submission.tournament && (
                        <Typography variant="caption" color="text.secondary">
                          N/A
                        </Typography>
                      )}
                    </TableCell>
                    <TableCell>
                      <Typography variant="caption" display="block">
                        {new Date(submission.submitted_at).toLocaleDateString()}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {new Date(submission.submitted_at).toLocaleTimeString()}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={submission.status}
                        size="small"
                        color={getStatusColor(submission.status)}
                      />
                    </TableCell>
                    <TableCell>
                      <IconButton
                        size="small"
                        color="primary"
                        onClick={() => handleViewSubmission(submission)}
                        title="View & Review"
                      >
                        <Visibility />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </CardContent>

      {/* Review Dialog */}
      <Dialog
        open={reviewDialogOpen}
        onClose={reviewing ? undefined : () => {
          setReviewDialogOpen(false);
          setSelectedSubmission(null);
          setAdminNotes('');
        }}
        maxWidth="md"
        fullWidth
        disableEscapeKeyDown={reviewing}
        disableEnforceFocus={reviewing}
        disableAutoFocus={reviewing}
        disableRestoreFocus={false}
        keepMounted={false}
        aria-labelledby="review-dialog-title"
      >
        <DialogTitle id="review-dialog-title">
          Review Fight URL Submission
        </DialogTitle>
        <DialogContent>
          {selectedSubmission && (
            <Box sx={{ mt: 2 }}>
              <Box mb={2}>
                <Typography variant="subtitle2" color="text.secondary">Fighter</Typography>
                <Typography variant="body1" sx={{ mb: 2 }}>
                  {selectedSubmission.fighter?.name || 'Unknown'}
                </Typography>
              </Box>

              <Box mb={2}>
                <Typography variant="subtitle2" color="text.secondary">Event Type</Typography>
                <Chip
                  label={selectedSubmission.event_type}
                  size="small"
                  icon={selectedSubmission.event_type === 'Tournament' ? <EmojiEvents /> : <SportsMma />}
                  color={selectedSubmission.event_type === 'Tournament' ? 'warning' : 'primary'}
                  sx={{ mt: 1 }}
                />
              </Box>

              <Box mb={2}>
                <Typography variant="subtitle2" color="text.secondary">Fight URL</Typography>
                <Link
                  href={selectedSubmission.fight_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 1 }}
                >
                  <LinkIcon />
                  <Typography variant="body2">{selectedSubmission.fight_url}</Typography>
                </Link>
              </Box>

              {selectedSubmission.description && (
                <Box mb={2}>
                  <Typography variant="subtitle2" color="text.secondary">Description</Typography>
                  <Typography variant="body2" sx={{ mt: 1 }}>
                    {selectedSubmission.description}
                  </Typography>
                </Box>
              )}

              {selectedSubmission.scheduled_fight && (
                <Box mb={2}>
                  <Typography variant="subtitle2" color="text.secondary">Scheduled Fight</Typography>
                  <Typography variant="body2" sx={{ mt: 1 }}>
                    {selectedSubmission.scheduled_fight.weight_class} • {new Date(selectedSubmission.scheduled_fight.scheduled_date).toLocaleDateString()}
                  </Typography>
                </Box>
              )}

              {selectedSubmission.tournament && (
                <Box mb={2}>
                  <Typography variant="subtitle2" color="text.secondary">Tournament</Typography>
                  <Typography variant="body2" sx={{ mt: 1 }}>
                    {selectedSubmission.tournament.name} • {selectedSubmission.tournament.weight_class}
                  </Typography>
                </Box>
              )}

              <Box mb={2}>
                <Typography variant="subtitle2" color="text.secondary">Submitted</Typography>
                <Typography variant="body2" sx={{ mt: 1 }}>
                  {new Date(selectedSubmission.submitted_at).toLocaleString()}
                </Typography>
              </Box>

              <Divider sx={{ my: 2 }} />

              <FormControl fullWidth sx={{ mb: 2 }}>
                <InputLabel id="status-label">Status</InputLabel>
                <Select
                  value={status}
                  onChange={(e) => setStatus(e.target.value as any)}
                  label="Status"
                  labelId="status-label"
                >
                  <MenuItem value="Pending">Pending</MenuItem>
                  <MenuItem value="Reviewed">Reviewed</MenuItem>
                  <MenuItem value="Approved">Approved</MenuItem>
                  <MenuItem value="Rejected">Rejected</MenuItem>
                </Select>
              </FormControl>

              <TextField
                fullWidth
                multiline
                rows={4}
                label="Admin Notes"
                value={adminNotes}
                onChange={(e) => setAdminNotes(e.target.value)}
                placeholder="Add notes about this submission..."
                helperText="These notes will be visible to the fighter"
              />
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button
            onClick={() => {
              setReviewDialogOpen(false);
              setSelectedSubmission(null);
              setAdminNotes('');
            }}
            disabled={reviewing}
          >
            Cancel
          </Button>
          <Button
            variant="contained"
            onClick={handleReviewSubmission}
            disabled={reviewing}
            startIcon={reviewing ? <CircularProgress size={16} /> : <CheckCircle />}
          >
            {reviewing ? 'Saving...' : 'Save Review'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete All Approved/Rejected Dialog */}
      <Dialog
        open={deleteDialogOpen}
        onClose={deleting ? undefined : () => setDeleteDialogOpen(false)}
        aria-labelledby="delete-dialog-title"
        disableEscapeKeyDown={deleting}
        disableEnforceFocus={deleting}
        disableAutoFocus={deleting}
        disableRestoreFocus={false}
        keepMounted={false}
      >
        <DialogTitle id="delete-dialog-title">
          Delete All Approved & Rejected Submissions
        </DialogTitle>
        <DialogContent>
          <Typography>
            Are you sure you want to delete all approved and rejected submissions? 
            This will permanently delete {submissions.filter(s => s.status === 'Approved' || s.status === 'Rejected').length} submission(s).
            This action cannot be undone.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button
            onClick={() => setDeleteDialogOpen(false)}
            disabled={deleting}
          >
            Cancel
          </Button>
          <Button
            onClick={handleDeleteAllApprovedAndRejected}
            color="error"
            variant="contained"
            disabled={deleting}
            startIcon={deleting ? <CircularProgress size={20} /> : <DeleteForever />}
          >
            {deleting ? 'Deleting...' : 'Delete All'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar for notifications */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
        message={snackbar.message}
      />
    </Card>
  );
};

export default FightUrlSubmissionManagement;

