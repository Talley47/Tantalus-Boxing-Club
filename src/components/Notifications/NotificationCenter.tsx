import React from 'react';
import { Box, Typography, Card, CardContent } from '@mui/material';

const NotificationCenter: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Notifications
      </Typography>
      <Card>
        <CardContent>
          <Typography variant="body1">
            Notification center coming soon...
          </Typography>
        </CardContent>
      </Card>
    </Box>
  );
};

export default NotificationCenter;