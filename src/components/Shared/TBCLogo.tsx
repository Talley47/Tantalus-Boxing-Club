import React, { useState } from 'react';
import { Box, Typography } from '@mui/material';
import introVideo from '../../intro.MP4';

const TBCLogo: React.FC = () => {
  const [videoError, setVideoError] = useState(false);

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', mb: 3 }}>
      {/* Logo Video */}
      <Box sx={{ mb: 2 }}>
        {!videoError ? (
          <video
            src={introVideo}
            autoPlay
            loop
            muted
            style={{
              width: '80px',
              height: '60px',
              objectFit: 'contain'
            }}
            onError={() => {
              console.log('Logo video failed to load, showing fallback');
              setVideoError(true);
            }}
          />
        ) : (
          <Box
            sx={{
              width: '80px',
              height: '60px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              background: '#f5f5f5',
              border: '2px solid #ddd',
              borderRadius: '8px',
              fontWeight: 'bold',
              color: '#666'
            }}
          >
            TBC
          </Box>
        )}
      </Box>
      
      {/* Powered By TBC Promotions */}
      <Typography 
        variant="body2" 
        color="text.secondary"
        sx={{ 
          fontWeight: 500,
          letterSpacing: '0.5px',
          textTransform: 'uppercase'
        }}
      >
        Powered By TBC Promotions
      </Typography>
    </Box>
  );
};

export default TBCLogo;
