import React from 'react';
import { Box, Typography, Card, CardContent } from '@mui/material';

const CardBuilder: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Card Builder
      </Typography>
      <Card>
        <CardContent>
          <Typography variant="body1">
            Fight night card builder coming soon...
          </Typography>
        </CardContent>
      </Card>
    </Box>
  );
};

export default CardBuilder;