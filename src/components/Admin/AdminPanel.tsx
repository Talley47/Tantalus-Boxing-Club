import React, { useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
} from '@mui/material';
import { Settings as SettingsIcon } from '@mui/icons-material';
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

const AdminPanel: React.FC = () => {
  const [fightRecordsDialogOpen, setFightRecordsDialogOpen] = useState(false);
  const [scheduledFightsDialogOpen, setScheduledFightsDialogOpen] = useState(false);
  const [trainingCampsDialogOpen, setTrainingCampsDialogOpen] = useState(false);
  const [calloutsDialogOpen, setCalloutsDialogOpen] = useState(false);
  const [chatMessagesDialogOpen, setChatMessagesDialogOpen] = useState(false);

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Admin Panel
      </Typography>

      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 3 }}>
        {/* User Management - Using dedicated component */}
        <Box sx={{ gridColumn: { xs: '1', md: '1 / -1' } }}>
          <UserManagement />
        </Box>

        {/* Dispute Resolution */}
        <Box sx={{ gridColumn: { xs: '1', md: '1 / -1' } }}>
          <DisputeManagement />
        </Box>

        {/* Fight URL Submissions */}
        <Box sx={{ gridColumn: { xs: '1', md: '1 / -1' } }}>
          <FightUrlSubmissionManagement />
        </Box>
      </Box>

      {/* Calendar Event Management */}
      <Box sx={{ mt: 3 }}>
        <CalendarEventManagement />
      </Box>

      {/* Tournament Management */}
      <Box sx={{ mt: 3 }}>
        <TournamentManagement />
      </Box>

      {/* News & Announcements Management */}
      <Box sx={{ mt: 3 }}>
        <NewsManagement />
      </Box>

      {/* League Analytics Dashboard */}
      <Box sx={{ mt: 3 }}>
        <AdminAnalytics />
      </Box>

      {/* System Settings */}
      <Card sx={{ mt: 3 }}>
        <CardContent>
          <Box display="flex" alignItems="center" mb={2}>
            <SettingsIcon sx={{ mr: 1 }} />
            <Typography variant="h6">System Settings</Typography>
          </Box>
          <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
            <Button 
              variant="contained" 
              fullWidth
              onClick={(e) => {
                e.currentTarget.blur();
                setFightRecordsDialogOpen(true);
              }}
            >
              Manage Fight Records
            </Button>
            <Button 
              variant="contained" 
              color="warning"
              fullWidth
              onClick={(e) => {
                e.currentTarget.blur();
                setScheduledFightsDialogOpen(true);
              }}
            >
              Manage Scheduled Fights
            </Button>
            <Button 
              variant="contained" 
              color="error"
              fullWidth
              onClick={(e) => {
                e.currentTarget.blur();
                setTrainingCampsDialogOpen(true);
              }}
            >
              Manage Training Camps
            </Button>
            <Button 
              variant="contained" 
              color="error"
              fullWidth
              onClick={(e) => {
                e.currentTarget.blur();
                setCalloutsDialogOpen(true);
              }}
            >
              Manage Callouts
            </Button>
            <Button 
              variant="contained" 
              color="error"
              fullWidth
              onClick={(e) => {
                e.currentTarget.blur();
                setChatMessagesDialogOpen(true);
              }}
            >
              Manage Chat Messages
            </Button>
          </Box>
        </CardContent>
      </Card>

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
    </Box>
  );
};

export default AdminPanel;
