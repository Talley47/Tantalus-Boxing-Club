import React from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Chip,
  IconButton,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
} from '@mui/material';
import {
  CalendarToday,
  SportsMma,
  EmojiEvents,
  Mic,
  Campaign,
  Podcasts,
  ChevronLeft,
  ChevronRight,
  Info,
} from '@mui/icons-material';
import { CalendarEvent } from '../../services/calendarService';

interface CalendarViewProps {
  events: CalendarEvent[];
  currentDate: Date;
  onDateChange: (date: Date) => void;
  onEventClick?: (event: CalendarEvent) => void;
}

const CalendarView: React.FC<CalendarViewProps> = ({
  events,
  currentDate,
  onDateChange,
  onEventClick,
}) => {
  const [selectedEvent, setSelectedEvent] = React.useState<CalendarEvent | null>(null);
  const [dialogOpen, setDialogOpen] = React.useState(false);

  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();

  // Get first day of month and number of days
  const firstDay = new Date(year, month, 1);
  const lastDay = new Date(year, month + 1, 0);
  const daysInMonth = lastDay.getDate();
  const startingDayOfWeek = firstDay.getDay();

  // Navigation
  const goToPreviousMonth = () => {
    onDateChange(new Date(year, month - 1, 1));
  };

  const goToNextMonth = () => {
    onDateChange(new Date(year, month + 1, 1));
  };

  // Get events for a specific date
  const getEventsForDate = (day: number): CalendarEvent[] => {
    const date = new Date(year, month, day);
    return events.filter(event => {
      const eventDate = new Date(event.date);
      return (
        eventDate.getFullYear() === date.getFullYear() &&
        eventDate.getMonth() === date.getMonth() &&
        eventDate.getDate() === date.getDate()
      );
    });
  };

  // Get event icon
  const getEventIcon = (eventType: CalendarEvent['event_type']) => {
    switch (eventType) {
      case 'Fight Card':
        return <SportsMma fontSize="small" />;
      case 'Tournament':
        return <EmojiEvents fontSize="small" />;
      case 'Interview':
        return <Mic fontSize="small" />;
      case 'Press Conference':
        return <Campaign fontSize="small" />;
      case 'Podcast':
        return <Podcasts fontSize="small" />;
      default:
        return <CalendarToday fontSize="small" />;
    }
  };

  // Get event color
  const getEventColor = (eventType: CalendarEvent['event_type']): 'primary' | 'secondary' | 'success' | 'warning' | 'error' => {
    switch (eventType) {
      case 'Fight Card':
        return 'error';
      case 'Tournament':
        return 'primary';
      case 'Interview':
        return 'success';
      case 'Press Conference':
        return 'warning';
      case 'Podcast':
        return 'secondary';
      default:
        return 'primary';
    }
  };

  // Format time
  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
    });
  };

  const handleEventClick = (event: CalendarEvent, element?: HTMLElement) => {
    // Blur the clicked element to prevent aria-hidden warning
    if (element) {
      element.blur();
    }
    setSelectedEvent(event);
    setDialogOpen(true);
    if (onEventClick) {
      onEventClick(event);
    }
  };

  const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  return (
    <>
      <Card>
        <CardContent>
          {/* Calendar Header */}
          <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
            <IconButton onClick={goToPreviousMonth}>
              <ChevronLeft />
            </IconButton>
            <Typography variant="h5" component="div" sx={{ fontWeight: 'bold' }}>
              {monthNames[month]} {year}
            </Typography>
            <IconButton onClick={goToNextMonth}>
              <ChevronRight />
            </IconButton>
          </Box>

          {/* Week Day Headers */}
          <Box 
            sx={{ 
              display: 'grid', 
              gridTemplateColumns: 'repeat(7, 1fr)', 
              gap: 0.5, 
              mb: 1 
            }}
          >
            {weekDays.map(day => (
              <Box 
                key={day} 
                sx={{ 
                  textAlign: 'center', 
                  fontWeight: 'bold', 
                  py: 1 
                }}
              >
                <Typography variant="caption" color="text.secondary">
                  {day}
                </Typography>
              </Box>
            ))}
          </Box>

          {/* Calendar Days */}
          <Box 
            sx={{ 
              display: 'grid', 
              gridTemplateColumns: 'repeat(7, 1fr)', 
              gap: 0.5 
            }}
          >
            {/* Empty cells for days before month starts */}
            {Array.from({ length: startingDayOfWeek }).map((_, index) => (
              <Box 
                key={`empty-${index}`} 
                sx={{ minHeight: 100, py: 0.5 }} 
              />
            ))}

            {/* Days of the month */}
            {Array.from({ length: daysInMonth }).map((_, index) => {
              const day = index + 1;
              const dayEvents = getEventsForDate(day);
              const isToday = 
                new Date().getDate() === day &&
                new Date().getMonth() === month &&
                new Date().getFullYear() === year;

              return (
                <Box
                  key={day}
                  sx={{ 
                    minHeight: 100,
                    border: '1px solid',
                    borderColor: 'divider',
                    p: 0.5,
                    backgroundColor: isToday ? 'action.selected' : 'background.paper',
                    cursor: dayEvents.length > 0 ? 'pointer' : 'default',
                  }}
                  onClick={() => {
                    if (dayEvents.length > 0 && dayEvents[0]) {
                      const element = document.activeElement as HTMLElement;
                      if (element) element.blur();
                      handleEventClick(dayEvents[0]);
                    }
                  }}
                >
                  <Typography
                    variant="caption"
                    sx={{
                      fontWeight: isToday ? 'bold' : 'normal',
                      color: isToday ? 'primary.main' : 'text.primary',
                    }}
                  >
                    {day}
                  </Typography>
                  <Box sx={{ mt: 0.5, display: 'flex', flexDirection: 'column', gap: 0.3 }}>
                    {dayEvents.slice(0, 3).map(event => (
                      <Tooltip key={event.id} title={event.name}>
                        <Chip
                          label={event.name}
                          size="small"
                          icon={getEventIcon(event.event_type)}
                          color={getEventColor(event.event_type)}
                          onClick={(e) => {
                            e.stopPropagation();
                            const target = e.currentTarget as HTMLElement;
                            target.blur();
                            handleEventClick(event, target);
                          }}
                          sx={{ 
                            fontSize: '0.6rem',
                            height: 'auto',
                            '& .MuiChip-label': {
                              padding: '2px 4px',
                            },
                          }}
                        />
                      </Tooltip>
                    ))}
                    {dayEvents.length > 3 && (
                      <Typography variant="caption" color="text.secondary">
                        +{dayEvents.length - 3} more
                      </Typography>
                    )}
                  </Box>
                </Box>
              );
            })}
          </Box>
        </CardContent>
      </Card>

      {/* Event Details Dialog */}
      <Dialog 
        open={dialogOpen} 
        onClose={() => setDialogOpen(false)} 
        maxWidth="sm" 
        fullWidth
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
        keepMounted={false}
      >
        {selectedEvent && (
          <>
            <DialogTitle>
              <Box display="flex" alignItems="center" gap={1}>
                {getEventIcon(selectedEvent.event_type)}
                <Typography variant="h6">{selectedEvent.name}</Typography>
                <Chip
                  label={selectedEvent.event_type}
                  size="small"
                  color={getEventColor(selectedEvent.event_type)}
                />
              </Box>
            </DialogTitle>
            <DialogContent>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <Box>
                  <Typography variant="subtitle2" color="text.secondary">
                    Date & Time
                  </Typography>
                  <Typography variant="body1">
                    {new Date(selectedEvent.date).toLocaleDateString('en-US', {
                      weekday: 'long',
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric',
                    })}
                    {' '}
                    {formatTime(selectedEvent.date)}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {selectedEvent.timezone}
                  </Typography>
                </Box>

                {selectedEvent.location && (
                  <Box>
                    <Typography variant="subtitle2" color="text.secondary">
                      Location
                    </Typography>
                    <Typography variant="body1">
                      {selectedEvent.location.startsWith('http') ? (
                        <a href={selectedEvent.location} target="_blank" rel="noopener noreferrer" style={{ color: 'inherit', textDecoration: 'underline' }}>
                          {selectedEvent.location}
                        </a>
                      ) : (
                        selectedEvent.location
                      )}
                    </Typography>
                  </Box>
                )}

                {selectedEvent.description && (
                  <Box>
                    <Typography variant="subtitle2" color="text.secondary">
                      Description
                    </Typography>
                    <Typography variant="body1" sx={{ whiteSpace: 'pre-wrap' }}>
                      {selectedEvent.description}
                    </Typography>
                  </Box>
                )}

                {selectedEvent.poster_url && (
                  <Box>
                    <Typography variant="subtitle2" color="text.secondary">
                      Poster URL
                    </Typography>
                    <Typography variant="body1">
                      <a href={selectedEvent.poster_url} target="_blank" rel="noopener noreferrer" style={{ color: 'inherit', textDecoration: 'underline' }}>
                        {selectedEvent.poster_url}
                      </a>
                    </Typography>
                  </Box>
                )}

                {selectedEvent.broadcast_url && (
                  <Box>
                    <Typography variant="subtitle2" color="text.secondary">
                      Broadcast URL
                    </Typography>
                    <Typography variant="body1" sx={{ mb: 1 }}>
                      <a href={selectedEvent.broadcast_url} target="_blank" rel="noopener noreferrer" style={{ color: 'inherit', textDecoration: 'underline' }}>
                        {selectedEvent.broadcast_url}
                      </a>
                    </Typography>
                    <Button
                      variant="outlined"
                      href={selectedEvent.broadcast_url}
                      target="_blank"
                      rel="noopener noreferrer"
                      fullWidth
                    >
                      Watch Live
                    </Button>
                  </Box>
                )}

                {selectedEvent.theme && (
                  <Box>
                    <Typography variant="subtitle2" color="text.secondary">
                      Theme
                    </Typography>
                    <Typography variant="body1">{selectedEvent.theme}</Typography>
                  </Box>
                )}

                {selectedEvent.event_type === 'Tournament' && selectedEvent.tournament_id && (
                  <Box>
                    <Typography variant="subtitle2" color="text.secondary">
                      Tournament ID
                    </Typography>
                    <Typography variant="body1">{selectedEvent.tournament_id}</Typography>
                  </Box>
                )}

                {selectedEvent.featured_fighter_ids && selectedEvent.featured_fighter_ids.length > 0 && (
                  <Box>
                    <Typography variant="subtitle2" color="text.secondary">
                      {selectedEvent.event_type === 'Tournament' ? 'Tournament Participants' : 'Featured Fighters'}
                    </Typography>
                    <Typography variant="body1">
                      {selectedEvent.featured_fighter_ids.length} fighter(s) participating
                    </Typography>
                  </Box>
                )}

                <Box>
                  <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 0.5 }}>
                    Status
                  </Typography>
                  <Chip
                    label={selectedEvent.status}
                    size="small"
                    color={
                      selectedEvent.status === 'Live' ? 'error' :
                      selectedEvent.status === 'Completed' ? 'success' :
                      selectedEvent.status === 'Cancelled' ? 'default' :
                      'primary'
                    }
                  />
                </Box>
              </Box>
            </DialogContent>
            <DialogActions>
              <Button onClick={() => setDialogOpen(false)}>Close</Button>
            </DialogActions>
          </>
        )}
      </Dialog>
    </>
  );
};

export default CalendarView;

