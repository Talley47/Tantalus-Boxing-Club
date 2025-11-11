import React from 'react';
import { Box, Typography, Card, CardContent } from '@mui/material';

const LiveFeed: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Live Feed
      </Typography>
      <Card>
        <CardContent>
          <Typography variant="body1">
            Live activity feed coming soon...
          </Typography>
        </CardContent>
      </Card>
    </Box>
  );
};

export default LiveFeed;