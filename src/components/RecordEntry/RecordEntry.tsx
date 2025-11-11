import React from 'react';
import { Box, Typography, Card, CardContent } from '@mui/material';

const RecordEntry: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Record Entry
      </Typography>
      <Card>
        <CardContent>
          <Typography variant="body1">
            Fight record entry coming soon...
          </Typography>
        </CardContent>
      </Card>
    </Box>
  );
};

export default RecordEntry;