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
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  IconButton,
  Tooltip,
  Alert,
  Checkbox,
  FormControlLabel,
  Autocomplete,
  CircularProgress,
} from '@mui/material';
import {
  Add,
  Edit,
  Delete,
  CalendarToday,
  SportsMma,
  EmojiEvents,
  Mic,
  Campaign,
  Podcasts,
  AutoAwesome,
} from '@mui/icons-material';
import { CalendarService, CalendarEvent, CreateEventRequest } from '../../services/calendarService';
import { supabase, TABLES } from '../../services/supabase';

interface FighterOption {
  id: string;
  name: string;
  tier: string;
  points: number;
}

const CalendarEventManagement: React.FC = () => {
  const [events, setEvents] = useState<CalendarEvent[]>([]);
  const [loading, setLoading] = useState(false);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState<CalendarEvent | null>(null);
  const [eventToDelete, setEventToDelete] = useState<string | null>(null);
  const [fighterOptions, setFighterOptions] = useState<FighterOption[]>([]);
  const [formData, setFormData] = useState<CreateEventRequest>({
    name: '',
    date: '',
    timezone: 'UTC',
    event_type: 'Fight Card',
    description: '',
    location: '',
    poster_url: '',
    theme: '',
    broadcast_url: '',
    is_auto_scheduled: false,
  });
  const [posterFile, setPosterFile] = useState<File | null>(null);
  const [posterPreview, setPosterPreview] = useState<string | null>(null);
  const [uploadingPoster, setUploadingPoster] = useState(false);
  const [selectedFighters, setSelectedFighters] = useState<string[]>([]);
  const [eventStatus, setEventStatus] = useState<'Scheduled' | 'Live' | 'Completed' | 'Cancelled'>('Scheduled');

  useEffect(() => {
    loadEvents();
    loadFighterOptions();
  }, []);

  const loadEvents = async () => {
    try {
      setLoading(true);
      const now = new Date();
      const futureDate = new Date();
      futureDate.setMonth(futureDate.getMonth() + 3); // Load next 3 months
      
      const eventsData = await CalendarService.getEventsForDateRange(
        now.toISOString(),
        futureDate.toISOString()
      );
      setEvents(eventsData);
    } catch (error) {
      console.error('Error loading events:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadFighterOptions = async () => {
    try {
      const { data, error } = await supabase
        .from(TABLES.FIGHTER_PROFILES)
        .select('id, name, tier, points')
        .order('points', { ascending: false })
        .limit(100);

      if (error) throw error;
      setFighterOptions(data || []);
    } catch (error) {
      console.error('Error loading fighters:', error);
    }
  };

  const handleCreateEvent = () => {
    setSelectedEvent(null);
    setFormData({
      name: '',
      date: '',
      timezone: 'UTC',
      event_type: 'Fight Card',
      description: '',
      location: '',
      poster_url: '',
      theme: '',
      broadcast_url: '',
      is_auto_scheduled: false,
    });
    setSelectedFighters([]);
    setEventStatus('Scheduled');
    setPosterFile(null);
    setPosterPreview(null);
    setDialogOpen(true);
  };

  const handleEditEvent = (event: CalendarEvent) => {
    setSelectedEvent(event);
    setFormData({
      name: event.name,
      date: new Date(event.date).toISOString().slice(0, 16),
      timezone: event.timezone,
      event_type: event.event_type,
      description: event.description || '',
      location: event.location || '',
      poster_url: event.poster_url || '',
      theme: event.theme || '',
      broadcast_url: event.broadcast_url || '',
      is_auto_scheduled: event.is_auto_scheduled || false,
    });
    setSelectedFighters(event.featured_fighter_ids || []);
    setEventStatus(event.status);
    setPosterFile(null);
    setPosterPreview(event.poster_url || null);
    setDialogOpen(true);
  };

  const handleAutoSelectFighters = async () => {
    try {
      const fighterIds = await CalendarService.autoSelectInterviewFighters(5);
      setSelectedFighters(fighterIds);
      setFormData({
        ...formData,
        is_auto_scheduled: true,
      });
    } catch (error) {
      console.error('Error auto-selecting fighters:', error);
      alert('Failed to auto-select fighters');
    }
  };

  const handlePosterFileSelect = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    // Validate file type
    if (!file.type.startsWith('image/')) {
      alert('Please select an image file');
      return;
    }

    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      alert('File size must be less than 5MB');
      return;
    }

    setPosterFile(file);
    
    // Create preview
    const reader = new FileReader();
    reader.onloadend = () => {
      setPosterPreview(reader.result as string);
    };
    reader.readAsDataURL(file);
  };

  const handleSaveEvent = async () => {
    try {
      let posterUrl = formData.poster_url;

      // Upload poster image if a file was selected
      if (posterFile) {
        setUploadingPoster(true);
        try {
          const fileExt = posterFile.name.split('.').pop();
          const fileName = `${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`;
          
          // Try event-posters bucket first (most likely to exist)
          let uploadData, uploadError, bucketUsed;
          
          const { data: eventPostersData, error: eventPostersError } = await supabase.storage
            .from('event-posters')
            .upload(fileName, posterFile, {
              cacheControl: '3600',
              upsert: false,
            });

          if (eventPostersError) {
            // Check if it's an RLS error (bucket exists but permissions wrong)
            const isRLSError = 
              eventPostersError.message?.includes('row-level security') ||
              eventPostersError.message?.includes('RLS') ||
              eventPostersError.message?.includes('policy');
            
            // Check if bucket not found
            const isBucketNotFound = 
              eventPostersError.message?.includes('Bucket not found') || 
              eventPostersError.message?.includes('not found') ||
              eventPostersError.message?.includes('Bucket') ||
              (eventPostersError as any)?.status === 400;
            
            if (isRLSError) {
              // RLS error - throw to show dialog
              throw { 
                isRLSError: true,
                message: 'Storage bucket RLS policy error. Please run create-event-posters-storage-bucket.sql in Supabase SQL Editor.',
                uploadError: eventPostersError
              };
            }
            
            if (!isBucketNotFound) {
              // Some other error - throw it
              throw new Error(`Failed to upload image: ${eventPostersError.message}`);
            }
            
            // If event-posters bucket doesn't exist, try 'media-assets' bucket
            const { data: mediaAssetsData, error: mediaAssetsError } = await supabase.storage
              .from('media-assets')
              .upload(`event-posters/${fileName}`, posterFile, {
                cacheControl: '3600',
                upsert: false,
              });

            if (mediaAssetsError) {
              // Both buckets failed
              const isRLSError2 = 
                mediaAssetsError.message?.includes('row-level security') ||
                mediaAssetsError.message?.includes('RLS') ||
                mediaAssetsError.message?.includes('policy');
              
              const isBucketNotFound2 = 
                mediaAssetsError.message?.includes('Bucket not found') || 
                mediaAssetsError.message?.includes('not found') ||
                mediaAssetsError.message?.includes('Bucket') ||
                (mediaAssetsError as any)?.status === 400;
              
              if (isRLSError2) {
                throw { 
                  isRLSError: true,
                  message: 'Storage bucket RLS policy error. Please run create-event-posters-storage-bucket.sql in Supabase SQL Editor.',
                  uploadError: eventPostersError,
                  altUploadError: mediaAssetsError
                };
              }
              
              if (isBucketNotFound2) {
                throw { 
                  isBucketNotFound: true,
                  message: 'Storage bucket not found',
                  uploadError: eventPostersError,
                  altUploadError: mediaAssetsError
                };
              }
              
              throw new Error(`Failed to upload image: ${mediaAssetsError.message}`);
            }
            
            // media-assets bucket worked
            uploadData = mediaAssetsData;
            uploadError = null;
            bucketUsed = 'media-assets';
          } else {
            // event-posters bucket worked
            uploadData = eventPostersData;
            uploadError = null;
            bucketUsed = 'event-posters';
          }

          // Get public URL
          if (uploadData && !uploadError) {
            const { data: urlData } = supabase.storage
              .from(bucketUsed === 'event-posters' ? 'event-posters' : 'media-assets')
              .getPublicUrl(bucketUsed === 'event-posters' ? fileName : `event-posters/${fileName}`);
            
            posterUrl = urlData.publicUrl;
          }

        } catch (uploadErr: any) {
          console.error('Error uploading poster:', uploadErr);
          
          // Check if it's an RLS policy error
          const isRLSError = 
            uploadErr.isRLSError ||
            uploadErr.message?.includes('row-level security') ||
            uploadErr.message?.includes('RLS') ||
            uploadErr.message?.includes('policy') ||
            (uploadErr as any)?.uploadError?.message?.includes('row-level security') ||
            (uploadErr as any)?.altUploadError?.message?.includes('row-level security');
          
          // Check if it's a bucket not found error
          const isBucketNotFound = 
            uploadErr.isBucketNotFound ||
            uploadErr.message?.includes('Bucket not found') || 
            uploadErr.message?.includes('not found') || 
            uploadErr.message?.includes('Bucket') ||
            (uploadErr as any)?.status === 400 ||
            (uploadErr as any)?.uploadError?.message?.includes('Bucket') ||
            (uploadErr as any)?.altUploadError?.message?.includes('Bucket');
          
          if (isRLSError) {
            const rlsInstructions = 
              '⚠️ Storage bucket RLS policy error!\n\n' +
              'The bucket exists but permissions need to be set up.\n\n' +
              'To fix this:\n\n' +
              '1. Go to Supabase Dashboard → SQL Editor\n' +
              '2. Run: create-event-posters-storage-bucket.sql\n' +
              '3. This will set up the necessary RLS policies\n\n' +
              'For now, you can:\n' +
              '• Click OK to continue with Poster URL (remove uploaded image)\n' +
              '• Click Cancel to fix RLS policies first';
            
            const userChoice = window.confirm(rlsInstructions);
            
            if (userChoice) {
              // User wants to use URL instead - clear the file and continue
              setPosterFile(null);
              setPosterPreview(null);
              setUploadingPoster(false);
              // Continue with formData.poster_url (which might be empty)
            } else {
              // User wants to fix RLS first
              setUploadingPoster(false);
              alert('Please run create-event-posters-storage-bucket.sql in Supabase SQL Editor to fix RLS policies, then try uploading again.');
              return;
            }
          } else if (isBucketNotFound) {
            const instructions = 
              '⚠️ Storage bucket not found!\n\n' +
              'To enable image uploads, create a storage bucket:\n\n' +
              '1. Go to Supabase Dashboard → Storage\n' +
              '2. Click "New bucket"\n' +
              '3. Name: "event-posters" (or "media-assets")\n' +
              '4. Public: Yes\n' +
              '5. File size limit: 5MB\n' +
              '6. Allowed MIME types: image/*\n\n' +
              'For now, you can:\n' +
              '• Click OK to continue with Poster URL (remove uploaded image)\n' +
              '• Click Cancel to create the bucket first';
            
            const userChoice = window.confirm(instructions);
            
            if (userChoice) {
              // User wants to use URL instead - clear the file and continue
              setPosterFile(null);
              setPosterPreview(null);
              setUploadingPoster(false);
              // Continue with formData.poster_url (which might be empty)
              // Don't return - let the event creation continue
            } else {
              // User wants to create bucket first
              setUploadingPoster(false);
              alert('Please create the storage bucket first, then try uploading again.');
              return;
            }
          } else {
            const errorMessage = uploadErr.message || 'Unknown error';
            alert(`Failed to upload poster image: ${errorMessage}\n\nYou can still use a Poster URL instead by removing the uploaded image and entering a URL.`);
            setUploadingPoster(false);
            return;
          }
        } finally {
          if (uploadingPoster) {
            setUploadingPoster(false);
          }
        }
      }

      const eventData: any = {
        ...formData,
        poster_url: posterUrl,
        featured_fighter_ids: selectedFighters,
        date: new Date(formData.date).toISOString(),
      };

      // Include status if editing
      if (selectedEvent) {
        eventData.status = eventStatus;
        await CalendarService.updateEvent(selectedEvent.id, eventData);
      } else {
        await CalendarService.createEvent(eventData);
      }

      setDialogOpen(false);
      setPosterFile(null);
      setPosterPreview(null);
      loadEvents();
      alert(selectedEvent ? 'Event updated successfully!' : 'Event created successfully!');
    } catch (error: any) {
      console.error('Error saving event:', error);
      alert(`Failed to save event: ${error.message || 'Unknown error'}`);
    }
  };

  const handleDeleteEvent = async () => {
    if (!eventToDelete) return;

    try {
      await CalendarService.deleteEvent(eventToDelete);
      setDeleteDialogOpen(false);
      setEventToDelete(null);
      loadEvents();
      alert('Event deleted successfully!');
    } catch (error) {
      console.error('Error deleting event:', error);
      alert('Failed to delete event');
    }
  };

  const getEventIcon = (eventType: CalendarEvent['event_type']) => {
    switch (eventType) {
      case 'Fight Card':
        return <SportsMma />;
      case 'Tournament':
        return <EmojiEvents />;
      case 'Interview':
        return <Mic />;
      case 'Press Conference':
        return <Campaign />;
      case 'Podcast':
        return <Podcasts />;
      default:
        return <CalendarToday />;
    }
  };

  return (
    <Card>
      <CardContent>
        <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
          <Box display="flex" alignItems="center">
            <CalendarToday sx={{ mr: 1 }} />
            <Typography variant="h6">TBC Promotions Calendar Events</Typography>
          </Box>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={handleCreateEvent}
          >
            Create Event
          </Button>
        </Box>

        {loading ? (
          <Typography>Loading events...</Typography>
        ) : events.length === 0 ? (
          <Alert severity="info">No events scheduled</Alert>
        ) : (
          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Type</TableCell>
                  <TableCell>Name</TableCell>
                  <TableCell>Date & Time</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {events.map((event) => (
                  <TableRow key={event.id}>
                    <TableCell>
                      <Box display="flex" alignItems="center" gap={1}>
                        {getEventIcon(event.event_type)}
                        <Chip label={event.event_type} size="small" />
                      </Box>
                    </TableCell>
                    <TableCell>{event.name}</TableCell>
                    <TableCell>
                      {new Date(event.date).toLocaleString('en-US', {
                        year: 'numeric',
                        month: 'short',
                        day: 'numeric',
                        hour: 'numeric',
                        minute: '2-digit',
                      })}
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={event.status}
                        size="small"
                        color={
                          event.status === 'Live' ? 'error' :
                          event.status === 'Completed' ? 'success' :
                          event.status === 'Cancelled' ? 'default' :
                          'primary'
                        }
                      />
                    </TableCell>
                    <TableCell>
                      <Tooltip title="Edit Event">
                        <IconButton
                          size="small"
                          onClick={() => handleEditEvent(event)}
                        >
                          <Edit />
                        </IconButton>
                      </Tooltip>
                      <Tooltip title="Delete Event">
                        <IconButton
                          size="small"
                          color="error"
                          onClick={() => {
                            setEventToDelete(event.id);
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

      {/* Create/Edit Event Dialog */}
      <Dialog 
        open={dialogOpen} 
        onClose={() => setDialogOpen(false)} 
        maxWidth="md" 
        fullWidth
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
        keepMounted={false}
      >
        <DialogTitle>
          {selectedEvent ? 'Edit Event' : 'Create New Event'}
        </DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
            <TextField
              fullWidth
              label="Event Name"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              required
            />

            <FormControl fullWidth required>
              <InputLabel>Event Type</InputLabel>
              <Select
                value={formData.event_type}
                onChange={(e) => setFormData({ ...formData, event_type: e.target.value as any })}
              >
                <MenuItem value="Fight Card">Fight Card</MenuItem>
                <MenuItem value="Tournament">Tournament</MenuItem>
                <MenuItem value="Interview">Interview</MenuItem>
                <MenuItem value="Press Conference">Press Conference</MenuItem>
                <MenuItem value="Podcast">Podcast</MenuItem>
              </Select>
            </FormControl>

            <TextField
              fullWidth
              label="Date & Time"
              type="datetime-local"
              value={formData.date}
              onChange={(e) => setFormData({ ...formData, date: e.target.value })}
              InputLabelProps={{ shrink: true }}
              required
            />

            <TextField
              fullWidth
              label="Timezone"
              value={formData.timezone}
              onChange={(e) => setFormData({ ...formData, timezone: e.target.value })}
            />

            <TextField
              fullWidth
              label="Location"
              value={formData.location}
              onChange={(e) => setFormData({ ...formData, location: e.target.value })}
            />

            <TextField
              fullWidth
              label="Description"
              multiline
              rows={3}
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            />

            <Box>
              <Typography variant="subtitle2" gutterBottom>
                Event Poster
              </Typography>
              <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
                <Button
                  variant="outlined"
                  component="label"
                  disabled={uploadingPoster}
                  startIcon={uploadingPoster ? <CircularProgress size={20} /> : undefined}
                >
                  {posterFile ? 'Change Image' : 'Upload Image'}
                  <input
                    type="file"
                    hidden
                    accept="image/*"
                    onChange={handlePosterFileSelect}
                  />
                </Button>
                {posterFile && (
                  <Button
                    variant="text"
                    color="error"
                    onClick={() => {
                      setPosterFile(null);
                      setPosterPreview(null);
                    }}
                  >
                    Remove
                  </Button>
                )}
              </Box>
              {posterPreview && (
                <Box sx={{ mb: 2 }}>
                  <img
                    src={posterPreview}
                    alt="Poster preview"
                    style={{
                      maxWidth: '100%',
                      maxHeight: '300px',
                      objectFit: 'contain',
                      borderRadius: '4px',
                      border: '1px solid #ddd',
                    }}
                  />
                </Box>
              )}
              <TextField
                fullWidth
                label="Or enter Poster URL"
                value={formData.poster_url}
                onChange={(e) => setFormData({ ...formData, poster_url: e.target.value })}
                placeholder="https://example.com/poster.jpg"
                helperText="Upload an image above or paste a URL here"
                disabled={!!posterFile}
                sx={{ mt: 1 }}
              />
            </Box>

            <TextField
              fullWidth
              label="Broadcast URL"
              value={formData.broadcast_url}
              onChange={(e) => setFormData({ ...formData, broadcast_url: e.target.value })}
            />

            {/* Status field - only for editing existing events */}
            {selectedEvent && (
              <FormControl fullWidth>
                <InputLabel>Status</InputLabel>
                <Select
                  value={eventStatus}
                  onChange={(e) => setEventStatus(e.target.value as any)}
                >
                  <MenuItem value="Scheduled">Scheduled</MenuItem>
                  <MenuItem value="Live">Live</MenuItem>
                  <MenuItem value="Completed">Completed</MenuItem>
                  <MenuItem value="Cancelled">Cancelled</MenuItem>
                </Select>
              </FormControl>
            )}

            {/* Auto-select fighters for interviews */}
            {formData.event_type === 'Interview' && (
              <Box>
                <Box display="flex" justifyContent="space-between" alignItems="center" mb={1}>
                  <Typography variant="subtitle2">Featured Fighters/Champions</Typography>
                  <Button
                    size="small"
                    startIcon={<AutoAwesome />}
                    onClick={handleAutoSelectFighters}
                  >
                    Auto-Select by Performance
                  </Button>
                </Box>
                <Autocomplete
                  multiple
                  options={fighterOptions}
                  getOptionLabel={(option) => `${option.name} (${option.tier} - ${option.points} pts)`}
                  value={fighterOptions.filter(f => selectedFighters.includes(f.id))}
                  onChange={(_, newValue) => {
                    setSelectedFighters(newValue.map(f => f.id));
                  }}
                  renderInput={(params) => (
                    <TextField
                      {...params}
                      label="Select Fighters"
                      placeholder="Choose fighters for interview"
                      inputProps={{
                        ...params.inputProps,
                        'aria-label': 'Select fighters for interview',
                      }}
                    />
                  )}
                  renderOption={(props, option) => {
                    const { key, ...optionProps } = props;
                    const textValue = `${option.name} (${option.tier} - ${option.points} pts)`;
                    return (
                      <li {...optionProps} key={key} aria-label={textValue}>
                        <Box>
                          <Typography variant="body2">{option.name}</Typography>
                          <Typography variant="caption" color="text.secondary">
                            {option.tier} • {option.points} points
                          </Typography>
                        </Box>
                      </li>
                    );
                  }}
                />
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={formData.is_auto_scheduled || false}
                      onChange={(e) => setFormData({ ...formData, is_auto_scheduled: e.target.checked })}
                    />
                  }
                  label="Auto-scheduled based on performance"
                />
              </Box>
            )}
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleSaveEvent} variant="contained">
            {selectedEvent ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog 
        open={deleteDialogOpen} 
        onClose={() => setDeleteDialogOpen(false)}
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
        keepMounted={false}
      >
        <DialogTitle>Delete Event</DialogTitle>
        <DialogContent>
          <Typography>
            Are you sure you want to delete this event? This action cannot be undone.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleDeleteEvent} color="error" variant="contained">
            Delete
          </Button>
        </DialogActions>
      </Dialog>
    </Card>
  );
};

export default CalendarEventManagement;

