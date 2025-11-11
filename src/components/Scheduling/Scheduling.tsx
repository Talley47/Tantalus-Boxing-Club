import React, { useState, useEffect } from 'react';
import { Box, Typography, CircularProgress, Alert } from '@mui/material';
import CalendarView from './CalendarView';
import { CalendarService, CalendarEvent } from '../../services/calendarService';
// Import July Schedule.png background image
import schedulingBackground from '../../July Schedule.png';
// Import Logo1.png
import logo1 from '../../Logo1.png';

// Debug log
console.log('Scheduling background image path:', schedulingBackground);

const Scheduling: React.FC = () => {
  const [events, setEvents] = useState<CalendarEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [currentDate, setCurrentDate] = useState<Date>(new Date());

  useEffect(() => {
    loadEvents();
  }, [currentDate]);

  const loadEvents = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const year = currentDate.getFullYear();
      const month = currentDate.getMonth() + 1;
      
      const startDate = new Date(year, month - 1, 1);
      const endDate = new Date(year, month, 0, 23, 59, 59);
      
      const eventsData = await CalendarService.getEventsForDateRange(
        startDate.toISOString(),
        endDate.toISOString()
      );
      
      setEvents(eventsData);
    } catch (err) {
      console.error('Error loading events:', err);
      setError('Failed to load calendar events');
    } finally {
      setLoading(false);
    }
  };

  const handleDateChange = (date: Date) => {
    setCurrentDate(date);
  };

  const handleEventClick = (event: CalendarEvent) => {
    console.log('Event clicked:', event);
  };

  return (
    <>
      {/* Full-screen background layer */}
      <Box
        component="div"
        sx={{
          position: 'fixed',
          top: 0,
          left: { xs: 0, sm: '240px' },
          right: 0,
          bottom: 0,
          width: { xs: '100%', sm: 'calc(100% - 240px)' },
          height: '100vh',
          backgroundImage: schedulingBackground ? `url("${schedulingBackground}")` : 'url("/July Schedule.png")',
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          backgroundRepeat: 'no-repeat',
          backgroundAttachment: 'fixed',
          zIndex: -1,
          display: 'block',
          backgroundColor: 'transparent',
          '&::after': {
            content: '""',
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.3)',
            zIndex: 1,
            pointerEvents: 'none',
          },
        }}
      />
      {/* Content layer */}
      <Box 
        sx={{ 
          position: 'relative',
          zIndex: 0,
          py: 4,
          m: -3,
          px: 3,
          minHeight: '100vh',
          // Ensure content is readable over background
          '& .MuiCard-root': {
            backgroundColor: 'rgba(255, 255, 255, 0.92)',
            backdropFilter: 'blur(5px)',
          },
          '& .MuiAlert-root': {
            backgroundColor: 'rgba(255, 255, 255, 0.92)',
            backdropFilter: 'blur(5px)',
          },
        }}
      >
        <Box mb={4}>
          <Box display="flex" alignItems="center" gap={2} mb={2}>
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
            <Typography 
              variant="h4" 
              gutterBottom 
              sx={{ 
                fontWeight: 'bold',
                color: 'white',
                textShadow: '2px 2px 4px rgba(0,0,0,0.8)',
                mb: 0,
              }}
            >
              TBC Promotions Fight Calendar
            </Typography>
          </Box>
          <Typography 
            variant="body1" 
            sx={{ 
              color: 'white',
              textShadow: '1px 1px 2px rgba(0,0,0,0.8)',
            }}
          >
            View all scheduled events including Fight Cards, Tournaments, Interviews, Press Conferences, and Podcast Shows
          </Typography>
        </Box>

        {loading ? (
          <Box display="flex" justifyContent="center" alignItems="center" minHeight={400}>
            <CircularProgress />
          </Box>
        ) : error ? (
          <Alert severity="error">{error}</Alert>
        ) : (
          <CalendarView
            events={events}
            currentDate={currentDate}
            onDateChange={handleDateChange}
            onEventClick={handleEventClick}
          />
        )}
      </Box>
    </>
  );
};

export default Scheduling;
