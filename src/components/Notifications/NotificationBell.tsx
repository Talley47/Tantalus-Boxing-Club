import React from 'react';
import { IconButton, Badge } from '@mui/material';
import { Notifications } from '@mui/icons-material';

const NotificationBell: React.FC = () => {
  return (
    <IconButton color="inherit">
      <Badge badgeContent={0} color="error">
        <Notifications />
      </Badge>
    </IconButton>
  );
};

export default NotificationBell;