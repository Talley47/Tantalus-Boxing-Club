import React from 'react';
import { Box, Tooltip } from '@mui/material';
import { Circle } from '@mui/icons-material';

const RealtimeStatus: React.FC = () => {
  return (
    <Tooltip title="Real-time connection active">
      <Box>
        <Circle sx={{ color: 'success.main', fontSize: 12 }} />
      </Box>
    </Tooltip>
  );
};

export default RealtimeStatus;