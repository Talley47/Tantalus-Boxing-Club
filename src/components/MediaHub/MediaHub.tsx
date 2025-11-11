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
  ListItemAvatar,
  ListItemText,
  ListItemSecondaryAction,
  IconButton,
  Avatar,
  Alert,
  Paper,
  Divider,
  Grid,
  LinearProgress,
  Tabs,
  Tab,
} from '@mui/material';
import {
  Add,
  VideoLibrary,
  PhotoLibrary,
  Mic,
  Campaign,
  Share,
  ThumbUp,
  Comment,
  Visibility,
  Download,
  Edit,
  Delete,
  PlayArrow,
  Pause,
  Stop,
  Star,
  StarBorder,
} from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';
import { mediaService } from '../../services/mediaService';
import { MediaAsset, Interview, PressConference, SocialLink } from '../../types';
// Import Logo1.png
import logo1 from '../../Logo1.png';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;
  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`media-tabpanel-${index}`}
      aria-labelledby={`media-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ p: 3 }}>{children}</Box>}
    </div>
  );
}

const MediaHub: React.FC = () => {
  const { fighterProfile, user } = useAuth();
  const [mediaAssets, setMediaAssets] = useState<MediaAsset[]>([]);
  const [interviews, setInterviews] = useState<Interview[]>([]);
  const [pressConferences, setPressConferences] = useState<PressConference[]>([]);
  const [socialLinks, setSocialLinks] = useState<SocialLink[]>([]);
  const [loading, setLoading] = useState(false);
  const [tabValue, setTabValue] = useState(0);
  const [uploadDialogOpen, setUploadDialogOpen] = useState(false);
  const [interviewDialogOpen, setInterviewDialogOpen] = useState(false);
  const [pressDialogOpen, setPressDialogOpen] = useState(false);
  const [socialDialogOpen, setSocialDialogOpen] = useState(false);
  const [uploadForm, setUploadForm] = useState({
    title: '',
    description: '',
    type: 'video' as 'video' | 'photo',
    file_url: '',
    tags: [] as string[]
  });
  const [interviewForm, setInterviewForm] = useState({
    title: '',
    description: '',
    scheduled_date: '',
    interviewer: '',
    platform: 'YouTube'
  });
  const [pressForm, setPressForm] = useState({
    title: '',
    description: '',
    scheduled_date: '',
    location: '',
    attendees: [] as string[]
  });
  const [socialForm, setSocialForm] = useState({
    platform: 'Twitter' as 'Twitter' | 'Instagram' | 'YouTube' | 'Twitch' | 'TikTok' | 'Facebook',
    url: '',
    handle: ''
  });

  useEffect(() => {
    if (fighterProfile) {
      loadMediaData();
    }
  }, [fighterProfile]);

  const loadMediaData = async () => {
    if (!fighterProfile) return;
    
    try {
      setLoading(true);
      
      // Load media assets
      const assets = await mediaService.getMediaAssets(fighterProfile.id);
      setMediaAssets(assets);
      
      // Load interviews
      const interviewData = await mediaService.getInterviews(fighterProfile.id);
      setInterviews(interviewData);
      
      // Load press conferences
      const pressData = await mediaService.getPressConferences(fighterProfile.id);
      setPressConferences(pressData);
      
      // Load social links
      const socialData = await mediaService.getSocialLinks(fighterProfile.id);
      setSocialLinks(socialData);
    } catch (error) {
      console.error('Error loading media data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleUploadMedia = async () => {
    if (!fighterProfile) return;
    
    try {
      await mediaService.uploadMediaAsset({
        fighter_id: fighterProfile.id,
        title: uploadForm.title,
        description: uploadForm.description,
        type: uploadForm.type,
        file_url: uploadForm.file_url,
        tags: uploadForm.tags
      });
      
      setUploadDialogOpen(false);
      setUploadForm({
        title: '',
        description: '',
        type: 'video',
        file_url: '',
        tags: []
      });
      loadMediaData();
      alert('Media uploaded successfully!');
    } catch (error) {
      console.error('Error uploading media:', error);
      alert('Failed to upload media');
    }
  };

  const handleScheduleInterview = async () => {
    if (!fighterProfile) return;
    
    try {
      await mediaService.scheduleInterview({
        fighter_id: fighterProfile.id,
        title: interviewForm.title,
        description: interviewForm.description,
        scheduled_date: interviewForm.scheduled_date,
        interviewer: interviewForm.interviewer,
        platform: interviewForm.platform
      });
      
      setInterviewDialogOpen(false);
      setInterviewForm({
        title: '',
        description: '',
        scheduled_date: '',
        interviewer: '',
        platform: 'YouTube'
      });
      loadMediaData();
      alert('Interview scheduled successfully!');
    } catch (error) {
      console.error('Error scheduling interview:', error);
      alert('Failed to schedule interview');
    }
  };

  const handleSchedulePressConference = async () => {
    if (!fighterProfile) return;
    
    try {
      await mediaService.schedulePressConference({
        fighter_id: fighterProfile.id,
        title: pressForm.title,
        description: pressForm.description,
        scheduled_date: pressForm.scheduled_date,
        location: pressForm.location,
        attendees: pressForm.attendees
      });
      
      setPressDialogOpen(false);
      setPressForm({
        title: '',
        description: '',
        scheduled_date: '',
        location: '',
        attendees: []
      });
      loadMediaData();
      alert('Press conference scheduled successfully!');
    } catch (error) {
      console.error('Error scheduling press conference:', error);
      alert('Failed to schedule press conference');
    }
  };

  const handleAddSocialLink = async () => {
    if (!fighterProfile) return;
    
    try {
      await mediaService.addSocialLink({
        fighter_id: fighterProfile.id,
        platform: socialForm.platform,
        url: socialForm.url,
        handle: socialForm.handle
      });
      
      setSocialDialogOpen(false);
      setSocialForm({
        platform: 'Twitter' as 'Twitter' | 'Instagram' | 'YouTube' | 'Twitch' | 'TikTok' | 'Facebook',
        url: '',
        handle: ''
      });
      loadMediaData();
      alert('Social link added successfully!');
    } catch (error) {
      console.error('Error adding social link:', error);
      alert('Failed to add social link');
    }
  };

  const getPlatformIcon = (platform: string) => {
    switch (platform.toLowerCase()) {
      case 'twitter': return '🐦';
      case 'instagram': return '📷';
      case 'youtube': return '📺';
      case 'twitch': return '🎮';
      case 'tiktok': return '🎵';
      case 'facebook': return '👥';
      default: return '🔗';
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

  const isEliteTier = fighterProfile?.tier === 'Elite';

  if (!isEliteTier) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="info" sx={{ mb: 3 }}>
          <Typography variant="h6" gutterBottom>
            Elite Tier Required
          </Typography>
          <Typography variant="body1">
            Media Hub features are only available to Elite tier fighters (150+ points).
            Keep fighting to reach Elite tier and unlock these exclusive features!
          </Typography>
        </Alert>
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Box display="flex" alignItems="center" gap={2}>
          <Box
            component="img"
            src={logo1}
            alt="Tantalus Boxing League Logo"
            sx={{
              height: { xs: 50, md: 70 },
              width: 'auto',
              objectFit: 'contain',
            }}
          />
          <Typography variant="h4">
            Media Hub
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={() => setUploadDialogOpen(true)}
        >
          Upload Media
        </Button>
      </Box>

      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        Manage your media presence, schedule interviews, and connect with fans through your social platforms.
      </Typography>

      <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
        <Tabs value={tabValue} onChange={(e, newValue) => setTabValue(newValue)}>
          <Tab label="Media Library" />
          <Tab label="Interviews" />
          <Tab label="Press Conferences" />
          <Tab label="Social Links" />
        </Tabs>
      </Box>

      {/* Media Library Tab */}
      <TabPanel value={tabValue} index={0}>
        <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
          <Typography variant="h6">Media Library</Typography>
          <Button
            variant="outlined"
            startIcon={<Add />}
            onClick={() => setUploadDialogOpen(true)}
          >
            Upload New
          </Button>
        </Box>
        
        {mediaAssets.length === 0 ? (
          <Alert severity="info">No media assets uploaded yet</Alert>
        ) : (
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr', md: '1fr 1fr 1fr' }, gap: 2 }}>
            {mediaAssets.map((asset) => (
              <Card key={asset.id}>
                <CardContent>
                  <Box display="flex" alignItems="center" mb={2}>
                    {asset.type === 'video' ? <VideoLibrary /> : <PhotoLibrary />}
                    <Typography variant="h6" sx={{ ml: 1 }}>
                      {asset.title}
                    </Typography>
                  </Box>
                  <Typography variant="body2" color="text.secondary" mb={2}>
                    {asset.description}
                  </Typography>
                  <Box display="flex" justifyContent="space-between" alignItems="center">
                    <Chip label={asset.type} size="small" />
                    <Box display="flex" gap={1}>
                      <IconButton size="small">
                        <Visibility />
                      </IconButton>
                      <IconButton size="small">
                        <ThumbUp />
                      </IconButton>
                      <IconButton size="small">
                        <Share />
                      </IconButton>
                    </Box>
                  </Box>
                </CardContent>
              </Card>
            ))}
          </Box>
        )}
      </TabPanel>

      {/* Interviews Tab */}
      <TabPanel value={tabValue} index={1}>
        <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
          <Typography variant="h6">Interviews</Typography>
          <Button
            variant="outlined"
            startIcon={<Mic />}
            onClick={() => setInterviewDialogOpen(true)}
          >
            Schedule Interview
          </Button>
        </Box>
        
        {interviews.length === 0 ? (
          <Alert severity="info">No interviews scheduled</Alert>
        ) : (
          <List>
            {interviews.map((interview) => (
              <ListItem key={interview.id}>
                <ListItemText
                  primary={interview.title}
                  secondary={
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        {interview.description}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Scheduled: {formatDate(interview.scheduled_date)}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Interviewer: {interview.interviewer} • Platform: {interview.platform}
                      </Typography>
                    </Box>
                  }
                />
                <ListItemSecondaryAction>
                  <Chip label={interview.status} color="primary" size="small" />
                </ListItemSecondaryAction>
              </ListItem>
            ))}
          </List>
        )}
      </TabPanel>

      {/* Press Conferences Tab */}
      <TabPanel value={tabValue} index={2}>
        <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
          <Typography variant="h6">Press Conferences</Typography>
          <Button
            variant="outlined"
            startIcon={<Campaign />}
            onClick={() => setPressDialogOpen(true)}
          >
            Schedule Press Conference
          </Button>
        </Box>
        
        {pressConferences.length === 0 ? (
          <Alert severity="info">No press conferences scheduled</Alert>
        ) : (
          <List>
            {pressConferences.map((press) => (
              <ListItem key={press.id}>
                <ListItemText
                  primary={press.title}
                  secondary={
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        {press.description}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Scheduled: {formatDate(press.scheduled_date)}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Location: {press.location}
                      </Typography>
                    </Box>
                  }
                />
                <ListItemSecondaryAction>
                  <Chip label={press.status} color="primary" size="small" />
                </ListItemSecondaryAction>
              </ListItem>
            ))}
          </List>
        )}
      </TabPanel>

      {/* Social Links Tab */}
      <TabPanel value={tabValue} index={3}>
        <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
          <Typography variant="h6">Social Links</Typography>
          <Button
            variant="outlined"
            startIcon={<Share />}
            onClick={() => setSocialDialogOpen(true)}
          >
            Add Social Link
          </Button>
        </Box>
        
        {socialLinks.length === 0 ? (
          <Alert severity="info">No social links added</Alert>
        ) : (
          <List>
            {socialLinks.map((link) => (
              <ListItem key={link.id}>
                <ListItemAvatar>
                  <Avatar>
                    {getPlatformIcon(link.platform)}
                  </Avatar>
                </ListItemAvatar>
                <ListItemText
                  primary={link.platform}
                  secondary={
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        @{link.handle}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {link.url}
                      </Typography>
                    </Box>
                  }
                />
                <ListItemSecondaryAction>
                  <IconButton
                    href={link.url}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <Share />
                  </IconButton>
                </ListItemSecondaryAction>
              </ListItem>
            ))}
          </List>
        )}
      </TabPanel>

      {/* Upload Media Dialog */}
      <Dialog open={uploadDialogOpen} onClose={() => setUploadDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Upload Media</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr' }, gap: 2, mt: 1 }}>
            <TextField
              fullWidth
              label="Title"
              value={uploadForm.title}
              onChange={(e) => setUploadForm({ ...uploadForm, title: e.target.value })}
            />
            <TextField
              fullWidth
              label="Description"
              multiline
              rows={3}
              value={uploadForm.description}
              onChange={(e) => setUploadForm({ ...uploadForm, description: e.target.value })}
            />
            <FormControl fullWidth>
              <InputLabel>Type</InputLabel>
              <Select
                value={uploadForm.type}
                onChange={(e) => setUploadForm({ ...uploadForm, type: e.target.value as any })}
              >
                <MenuItem value="video">Video</MenuItem>
                <MenuItem value="photo">Photo</MenuItem>
              </Select>
            </FormControl>
            <TextField
              fullWidth
              label="File URL"
              value={uploadForm.file_url}
              onChange={(e) => setUploadForm({ ...uploadForm, file_url: e.target.value })}
              placeholder="Paste your video or image URL here"
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setUploadDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleUploadMedia} variant="contained">
            Upload
          </Button>
        </DialogActions>
      </Dialog>

      {/* Schedule Interview Dialog */}
      <Dialog open={interviewDialogOpen} onClose={() => setInterviewDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Schedule Interview</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr' }, gap: 2, mt: 1 }}>
            <TextField
              fullWidth
              label="Interview Title"
              value={interviewForm.title}
              onChange={(e) => setInterviewForm({ ...interviewForm, title: e.target.value })}
            />
            <TextField
              fullWidth
              label="Description"
              multiline
              rows={3}
              value={interviewForm.description}
              onChange={(e) => setInterviewForm({ ...interviewForm, description: e.target.value })}
            />
            <TextField
              fullWidth
              label="Scheduled Date"
              type="datetime-local"
              value={interviewForm.scheduled_date}
              onChange={(e) => setInterviewForm({ ...interviewForm, scheduled_date: e.target.value })}
              InputLabelProps={{ shrink: true }}
            />
            <TextField
              fullWidth
              label="Interviewer"
              value={interviewForm.interviewer}
              onChange={(e) => setInterviewForm({ ...interviewForm, interviewer: e.target.value })}
            />
            <FormControl fullWidth>
              <InputLabel>Platform</InputLabel>
              <Select
                value={interviewForm.platform}
                onChange={(e) => setInterviewForm({ ...interviewForm, platform: e.target.value })}
              >
                <MenuItem value="YouTube">YouTube</MenuItem>
                <MenuItem value="Twitch">Twitch</MenuItem>
                <MenuItem value="Instagram">Instagram</MenuItem>
                <MenuItem value="TikTok">TikTok</MenuItem>
              </Select>
            </FormControl>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setInterviewDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleScheduleInterview} variant="contained">
            Schedule
          </Button>
        </DialogActions>
      </Dialog>

      {/* Schedule Press Conference Dialog */}
      <Dialog open={pressDialogOpen} onClose={() => setPressDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Schedule Press Conference</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr' }, gap: 2, mt: 1 }}>
            <TextField
              fullWidth
              label="Press Conference Title"
              value={pressForm.title}
              onChange={(e) => setPressForm({ ...pressForm, title: e.target.value })}
            />
            <TextField
              fullWidth
              label="Description"
              multiline
              rows={3}
              value={pressForm.description}
              onChange={(e) => setPressForm({ ...pressForm, description: e.target.value })}
            />
            <TextField
              fullWidth
              label="Scheduled Date"
              type="datetime-local"
              value={pressForm.scheduled_date}
              onChange={(e) => setPressForm({ ...pressForm, scheduled_date: e.target.value })}
              InputLabelProps={{ shrink: true }}
            />
            <TextField
              fullWidth
              label="Location"
              value={pressForm.location}
              onChange={(e) => setPressForm({ ...pressForm, location: e.target.value })}
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setPressDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleSchedulePressConference} variant="contained">
            Schedule
          </Button>
        </DialogActions>
      </Dialog>

      {/* Add Social Link Dialog */}
      <Dialog open={socialDialogOpen} onClose={() => setSocialDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Add Social Link</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr' }, gap: 2, mt: 1 }}>
            <FormControl fullWidth>
              <InputLabel>Platform</InputLabel>
              <Select
                value={socialForm.platform}
                onChange={(e) => setSocialForm({ ...socialForm, platform: e.target.value })}
              >
                <MenuItem value="Twitter">Twitter</MenuItem>
                <MenuItem value="Instagram">Instagram</MenuItem>
                <MenuItem value="YouTube">YouTube</MenuItem>
                <MenuItem value="Twitch">Twitch</MenuItem>
                <MenuItem value="TikTok">TikTok</MenuItem>
                <MenuItem value="Facebook">Facebook</MenuItem>
              </Select>
            </FormControl>
            <TextField
              fullWidth
              label="Handle"
              value={socialForm.handle}
              onChange={(e) => setSocialForm({ ...socialForm, handle: e.target.value })}
              placeholder="@username"
            />
            <TextField
              fullWidth
              label="URL"
              value={socialForm.url}
              onChange={(e) => setSocialForm({ ...socialForm, url: e.target.value })}
              placeholder="https://..."
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSocialDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleAddSocialLink} variant="contained">
            Add Link
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default MediaHub;