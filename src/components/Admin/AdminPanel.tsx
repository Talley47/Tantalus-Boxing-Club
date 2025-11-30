import React, { useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Divider,
} from '@mui/material';
import {
  Settings as SettingsIcon,
  People as PeopleIcon,
  Gavel as GavelIcon,
  Link as LinkIcon,
  CalendarToday as CalendarIcon,
  EmojiEvents as TournamentIcon,
  Article as ArticleIcon,
  Analytics as AnalyticsIcon,
  SportsMma as FightIcon,
  FitnessCenter as TrainingIcon,
  Chat as ChatIcon,
  Message as MessageIcon,
  ExpandMore as ExpandMoreIcon,
  AdminPanelSettings as AdminIcon,
} from '@mui/icons-material';
import CalendarEventManagement from './CalendarEventManagement';
import TournamentManagement from './TournamentManagement';
import NewsManagement from './NewsManagement';
import AdminAnalytics from './AdminAnalytics';
import UserManagement from './UserManagement';
import DisputeManagement from './DisputeManagement';
import FightRecordsManagement from './FightRecordsManagement';
import FightUrlSubmissionManagement from './FightUrlSubmissionManagement';
import ScheduledFightsManagement from './ScheduledFightsManagement';
import TrainingCampsManagement from './TrainingCampsManagement';
import CalloutsManagement from './CalloutsManagement';
import ChatMessagesManagement from './ChatMessagesManagement';
import ChampionshipBeltManagement from './ChampionshipBeltManagement';
import AdminDirectMessages from './AdminDirectMessages';
// Import Analytics page background
import analyticsBackground from '../../Analytics page.png';

const AdminPanel: React.FC = () => {
  const [fightRecordsDialogOpen, setFightRecordsDialogOpen] = useState(false);
  const [scheduledFightsDialogOpen, setScheduledFightsDialogOpen] = useState(false);
  const [trainingCampsDialogOpen, setTrainingCampsDialogOpen] = useState(false);
  const [calloutsDialogOpen, setCalloutsDialogOpen] = useState(false);
  const [chatMessagesDialogOpen, setChatMessagesDialogOpen] = useState(false);
  const [championshipBeltDialogOpen, setChampionshipBeltDialogOpen] = useState(false);
  const [adminDirectMessagesDialogOpen, setAdminDirectMessagesDialogOpen] = useState(false);
  const [expandedCategory, setExpandedCategory] = useState<string | false>('userManagement');

  const handleCategoryChange = (category: string) => (event: React.SyntheticEvent, isExpanded: boolean) => {
    setExpandedCategory(isExpanded ? category : false);
  };

  return (
    <>
      {/* Full-screen background layer */}
      <Box
        component="div"
        sx={{
          position: 'fixed',
          top: 0,
          left: { xs: 0, sm: '200px' },
          right: 0,
          bottom: 0,
          width: { xs: '100%', sm: 'calc(100% - 200px)' },
          height: '100vh',
          backgroundImage: analyticsBackground ? `url("${analyticsBackground}")` : 'url("/Analytics page.png")',
          backgroundSize: '100% 100%',
          backgroundPosition: 'center center',
          backgroundRepeat: 'no-repeat',
          backgroundAttachment: 'fixed',
          zIndex: -1,
          display: 'block',
          '&::after': {
            content: '""',
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.2)',
            pointerEvents: 'none',
            zIndex: 1,
          },
        }}
      />
      {/* Content layer */}
      <Box sx={{ position: 'relative', zIndex: 0, py: 4, px: 3, minHeight: '100vh' }}>
        <Box display="flex" alignItems="center" mb={3}>
          <AdminIcon sx={{ mr: 2, fontSize: 40, color: 'primary.main' }} />
          <Typography variant="h4" sx={{ fontWeight: 'bold', color: 'white' }}>
            Admin Panel
          </Typography>
        </Box>

      <Box sx={{ mb: 4 }}>
        {/* User Management Category */}
        <Accordion 
          expanded={expandedCategory === 'userManagement'} 
          onChange={handleCategoryChange('userManagement')}
          sx={{ mb: 2 }}
        >
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Box display="flex" alignItems="center" sx={{ width: '100%' }}>
              <PeopleIcon sx={{ mr: 2, color: 'primary.main' }} />
              <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                User Management
              </Typography>
            </Box>
          </AccordionSummary>
          <AccordionDetails>
            <UserManagement />
          </AccordionDetails>
        </Accordion>

        {/* Content Management Category */}
        <Accordion 
          expanded={expandedCategory === 'contentManagement'} 
          onChange={handleCategoryChange('contentManagement')}
          sx={{ mb: 2 }}
        >
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Box display="flex" alignItems="center" sx={{ width: '100%' }}>
              <ArticleIcon sx={{ mr: 2, color: 'primary.main' }} />
              <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                Content Management
              </Typography>
            </Box>
          </AccordionSummary>
          <AccordionDetails>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              <Box>
                <Box display="flex" alignItems="center" mb={2}>
                  <CalendarIcon sx={{ mr: 1, color: 'primary.main' }} />
                  <Typography variant="h6">Fight Calendar & Events</Typography>
                </Box>
                <Divider sx={{ mb: 2 }} />
                <CalendarEventManagement />
              </Box>
              <Box>
                <Box display="flex" alignItems="center" mb={2}>
                  <TournamentIcon sx={{ mr: 1, color: 'primary.main' }} />
                  <Typography variant="h6">Tournaments</Typography>
                </Box>
                <Divider sx={{ mb: 2 }} />
                <TournamentManagement />
              </Box>
              <Box>
                <Box display="flex" alignItems="center" mb={2}>
                  <ArticleIcon sx={{ mr: 1, color: 'primary.main' }} />
                  <Typography variant="h6">News & Announcements</Typography>
                </Box>
                <Divider sx={{ mb: 2 }} />
                <NewsManagement />
              </Box>
            </Box>
          </AccordionDetails>
        </Accordion>

        {/* Fight Management Category */}
        <Accordion 
          expanded={expandedCategory === 'fightManagement'} 
          onChange={handleCategoryChange('fightManagement')}
          sx={{ mb: 2 }}
        >
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Box display="flex" alignItems="center" sx={{ width: '100%' }}>
              <FightIcon sx={{ mr: 2, color: 'primary.main' }} />
              <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                Fight Management
              </Typography>
            </Box>
          </AccordionSummary>
          <AccordionDetails>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              <Box>
                <Box display="flex" alignItems="center" mb={2}>
                  <LinkIcon sx={{ mr: 1, color: 'primary.main' }} />
                  <Typography variant="h6">Fight URL Submissions</Typography>
                </Box>
                <Divider sx={{ mb: 2 }} />
                <FightUrlSubmissionManagement />
              </Box>
              <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
                <Card variant="outlined" sx={{ flex: { xs: '1 1 100%', sm: '1 1 calc(50% - 8px)' } }}>
                  <CardContent>
                    <Typography variant="h6" gutterBottom>
                      Fight Records
                    </Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                      Manage and reset fighter fight records
                    </Typography>
                    <Button 
                      variant="contained" 
                      fullWidth
                      onClick={() => setFightRecordsDialogOpen(true)}
                    >
                      Manage Fight Records
                    </Button>
                  </CardContent>
                </Card>
                <Card variant="outlined" sx={{ flex: { xs: '1 1 100%', sm: '1 1 calc(50% - 8px)' } }}>
                  <CardContent>
                    <Typography variant="h6" gutterBottom>
                      Scheduled Fights
                    </Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                      Manage all scheduled fights
                    </Typography>
                    <Button 
                      variant="contained" 
                      color="warning"
                      fullWidth
                      onClick={() => setScheduledFightsDialogOpen(true)}
                    >
                      Manage Scheduled Fights
                    </Button>
                  </CardContent>
                </Card>
              </Box>
            </Box>
          </AccordionDetails>
        </Accordion>

        {/* Training & Matchmaking Category */}
        <Accordion 
          expanded={expandedCategory === 'trainingMatchmaking'} 
          onChange={handleCategoryChange('trainingMatchmaking')}
          sx={{ mb: 2 }}
        >
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Box display="flex" alignItems="center" sx={{ width: '100%' }}>
              <TrainingIcon sx={{ mr: 2, color: 'primary.main' }} />
              <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                Training & Matchmaking
              </Typography>
            </Box>
          </AccordionSummary>
          <AccordionDetails>
            <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
              <Card variant="outlined" sx={{ flex: { xs: '1 1 100%', sm: '1 1 calc(50% - 8px)' } }}>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Training Camps
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                    Manage training camp invitations and active camps
                  </Typography>
                  <Button 
                    variant="contained" 
                    color="error"
                    fullWidth
                    onClick={() => setTrainingCampsDialogOpen(true)}
                  >
                    Manage Training Camps
                  </Button>
                </CardContent>
              </Card>
              <Card variant="outlined" sx={{ flex: { xs: '1 1 100%', sm: '1 1 calc(50% - 8px)' } }}>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Callouts & Rematches
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                    Manage callout requests and scheduled rematches
                  </Typography>
                  <Button 
                    variant="contained" 
                    color="error"
                    fullWidth
                    onClick={() => setCalloutsDialogOpen(true)}
                  >
                    Manage Callouts
                  </Button>
                </CardContent>
              </Card>
            </Box>
          </AccordionDetails>
        </Accordion>

        {/* Communication Category */}
        <Accordion 
          expanded={expandedCategory === 'communication'} 
          onChange={handleCategoryChange('communication')}
          sx={{ mb: 2 }}
        >
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Box display="flex" alignItems="center" sx={{ width: '100%' }}>
              <ChatIcon sx={{ mr: 2, color: 'primary.main' }} />
              <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                Communication
              </Typography>
            </Box>
          </AccordionSummary>
          <AccordionDetails>
            <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
              <Card variant="outlined" sx={{ flex: { xs: '1 1 100%', sm: '1 1 calc(50% - 8px)' } }}>
                <CardContent>
                  <Box display="flex" alignItems="center" mb={1}>
                    <ChatIcon sx={{ mr: 1, color: 'primary.main' }} />
                    <Typography variant="h6">League Chat</Typography>
                  </Box>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                    Manage all League Chat Room messages
                  </Typography>
                  <Button 
                    variant="contained" 
                    color="error"
                    fullWidth
                    onClick={() => setChatMessagesDialogOpen(true)}
                  >
                    Manage Chat Messages
                  </Button>
                </CardContent>
              </Card>
              <Card variant="outlined" sx={{ flex: { xs: '1 1 100%', sm: '1 1 calc(50% - 8px)' } }}>
                <CardContent>
                  <Box display="flex" alignItems="center" mb={1}>
                    <MessageIcon sx={{ mr: 1, color: 'primary.main' }} />
                    <Typography variant="h6">Direct Messages</Typography>
                  </Box>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                    Send messages to fighters about events and tournaments
                  </Typography>
                  <Button 
                    variant="contained" 
                    color="info"
                    fullWidth
                    onClick={() => setAdminDirectMessagesDialogOpen(true)}
                  >
                    Send Direct Messages
                  </Button>
                </CardContent>
              </Card>
            </Box>
          </AccordionDetails>
        </Accordion>

        {/* Disputes & Moderation Category */}
        <Accordion 
          expanded={expandedCategory === 'disputesModeration'} 
          onChange={handleCategoryChange('disputesModeration')}
          sx={{ mb: 2 }}
        >
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Box display="flex" alignItems="center" sx={{ width: '100%' }}>
              <GavelIcon sx={{ mr: 2, color: 'primary.main' }} />
              <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                Disputes & Moderation
              </Typography>
            </Box>
          </AccordionSummary>
          <AccordionDetails>
            <DisputeManagement />
          </AccordionDetails>
        </Accordion>

        {/* Analytics & Reports Category */}
        <Accordion 
          expanded={expandedCategory === 'analytics'} 
          onChange={handleCategoryChange('analytics')}
          sx={{ mb: 2 }}
        >
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Box display="flex" alignItems="center" sx={{ width: '100%' }}>
              <AnalyticsIcon sx={{ mr: 2, color: 'primary.main' }} />
              <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                Analytics & Reports
              </Typography>
            </Box>
          </AccordionSummary>
          <AccordionDetails>
            <AdminAnalytics />
          </AccordionDetails>
        </Accordion>

        {/* System Settings Category */}
        <Accordion 
          expanded={expandedCategory === 'systemSettings'} 
          onChange={handleCategoryChange('systemSettings')}
          sx={{ mb: 2 }}
        >
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Box display="flex" alignItems="center" sx={{ width: '100%' }}>
              <SettingsIcon sx={{ mr: 2, color: 'primary.main' }} />
              <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                System Settings
              </Typography>
            </Box>
          </AccordionSummary>
          <AccordionDetails>
            <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
              <Card variant="outlined" sx={{ flex: { xs: '1 1 100%', sm: '1 1 calc(50% - 8px)', md: '1 1 calc(33.333% - 11px)' } }}>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Championship Belts
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                    Manage championship belts and titles
                  </Typography>
                  <Button 
                    variant="contained" 
                    color="primary"
                    fullWidth
                    onClick={() => setChampionshipBeltDialogOpen(true)}
                  >
                    Manage Belts
                  </Button>
                </CardContent>
              </Card>
            </Box>
          </AccordionDetails>
        </Accordion>
      </Box>

      {/* Fight Records Management Dialog */}
      <FightRecordsManagement
        open={fightRecordsDialogOpen}
        onClose={() => setFightRecordsDialogOpen(false)}
      />

      {/* Scheduled Fights Management Dialog */}
      <ScheduledFightsManagement
        open={scheduledFightsDialogOpen}
        onClose={() => setScheduledFightsDialogOpen(false)}
      />

      {/* Training Camps Management Dialog */}
      <TrainingCampsManagement
        open={trainingCampsDialogOpen}
        onClose={() => setTrainingCampsDialogOpen(false)}
      />

      {/* Callouts Management Dialog */}
      <CalloutsManagement
        open={calloutsDialogOpen}
        onClose={() => setCalloutsDialogOpen(false)}
      />

      {/* Chat Messages Management Dialog */}
      <ChatMessagesManagement
        open={chatMessagesDialogOpen}
        onClose={() => setChatMessagesDialogOpen(false)}
      />

      {/* Championship Belt Management Dialog */}
      <ChampionshipBeltManagement
        open={championshipBeltDialogOpen}
        onClose={() => setChampionshipBeltDialogOpen(false)}
      />

      {/* Admin Direct Messages Dialog */}
      <AdminDirectMessages
        open={adminDirectMessagesDialogOpen}
        onClose={() => setAdminDirectMessagesDialogOpen(false)}
      />
      </Box>
    </>
  );
};

export default AdminPanel;
