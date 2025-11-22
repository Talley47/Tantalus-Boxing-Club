import React, { useState, useEffect, useRef } from 'react';
import {
  IconButton,
  Badge,
  Popover,
  Box,
  Typography,
  List,
  ListItem,
  ListItemButton,
  ListItemText,
  ListItemIcon,
  Divider,
  Button,
  Paper,
  Chip,
  CircularProgress,
} from '@mui/material';
import {
  Close,
  CheckCircle,
  SportsMma,
  FitnessCenter,
  Gavel,
  Article,
  Event,
  PersonAdd,
  Link as LinkIcon,
  EmojiEvents,
} from '@mui/icons-material';
import { notificationService, Notification } from '../../services/notificationService';
import { supabase } from '../../services/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';

const NotificationBell: React.FC = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [anchorEl, setAnchorEl] = useState<HTMLButtonElement | null>(null);
  const [loading, setLoading] = useState(false);
  const anchorRef = useRef<HTMLButtonElement>(null);
  const notificationSoundRef = useRef<HTMLAudioElement | null>(null);
  const soundIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const previousUnreadCountRef = useRef<number>(0);

  const open = Boolean(anchorEl);

  // Initialize notification sound
  useEffect(() => {
    // Try different possible file extensions and names
    const soundPaths = [
      '/boxing-bell-signals-6115 (1).mp3',
      '/boxing-bell-signals-6115 (1).mpeg',
      '/boxing-bell-signals-6115 (1).mpe',
      '/boxing-bell-signals-6115.mp3',
      '/boxing-bell-signals-6115.mpeg',
      '/assets/boxing-bell-signals-6115 (1).mp3',
      '/assets/boxing-bell-signals-6115 (1).mpeg',
      '/assets/boxing-bell-signals-6115 (1).mpe',
    ];

    let loadedAudio: HTMLAudioElement | null = null;
    let isLoaded = false;

    const tryLoadAudio = (index: number) => {
      if (index >= soundPaths.length) {
        // Only warn if we've exhausted all paths
        // Note: Cache errors (ERR_CACHE_OPERATION_NOT_SUPPORTED) are harmless
        // and don't prevent the audio from working - they're just browser warnings
        console.warn('Notification sound file not found after trying all paths. Please place "boxing-bell-signals-6115 (1).mp3" in the public folder. Note: Cache errors are harmless.');
        return;
      }

      const path = soundPaths[index];
      // URL encode the path to handle spaces and special characters
      // Use encodeURIComponent for the filename part to properly handle spaces and parentheses
      const encodedPath = path.startsWith('/') 
        ? '/' + path.slice(1).split('/').map(segment => encodeURIComponent(segment)).join('/')
        : encodeURIComponent(path);
      const audio = new Audio(encodedPath);
      audio.preload = 'auto';
      audio.volume = 0.8; // Set volume to 80%
      
      // Test if the file exists by trying to load it
      // Use a timeout to detect if file actually loads despite cache errors
      let errorOccurred = false;
      let successOccurred = false;
      
      const handleCanPlay = () => {
        if (!isLoaded && !errorOccurred) {
          successOccurred = true;
          loadedAudio = audio;
          notificationSoundRef.current = audio;
          isLoaded = true;
          console.log('✅ Notification sound loaded successfully:', path);
          
          // Test play (will fail silently if autoplay blocked, but helps "unlock" audio)
          audio.play().catch(() => {
            console.log('Audio autoplay blocked (normal for browsers). Sound will play on notification.');
          });
        }
      };
      
      const handleLoadedData = () => {
        if (!isLoaded && !errorOccurred) {
          successOccurred = true;
          loadedAudio = audio;
          notificationSoundRef.current = audio;
          isLoaded = true;
          console.log('✅ Notification sound loaded (loadeddata):', path);
        }
      };
      
      const handleError = (e: any) => {
        // Suppress cache operation errors (ERR_CACHE_OPERATION_NOT_SUPPORTED)
        // These are harmless and don't prevent audio from working
        const error = e.target?.error;
        const errorMessage = error?.message || '';
        const errorCode = error?.code;
        const errorName = error?.name || '';
        
        // Mark that an error occurred, but check if it's just a cache error
        errorOccurred = true;
        
        // Suppress cache-related errors - they're harmless
        // The file may still load successfully despite cache errors
        // Wait a bit to see if success events fire despite the cache error
        const isCacheError = errorMessage.includes('ERR_CACHE_OPERATION_NOT_SUPPORTED') || 
            errorMessage.includes('cache') ||
            errorMessage.includes('Cache') ||
            errorCode === 0 || // MEDIA_ERR_ABORTED
            errorCode === undefined || // Some browsers don't set error code for cache issues
            errorName.includes('Cache');
        
        if (isCacheError) {
          // For cache errors, wait a moment to see if the file actually loads
          // Cache errors don't prevent the file from working
          setTimeout(() => {
            if (!successOccurred && !isLoaded) {
              // If still not loaded after cache error, try next path
              tryLoadAudio(index + 1);
            }
          }, 100);
          return;
        }
        
        // For real errors (not cache), try next path immediately
        if (error && error.code === error.MEDIA_ERR_SRC_NOT_SUPPORTED) {
          // File doesn't exist or format not supported - try next path
          console.log(`Audio file not found at ${path}, trying next...`);
          tryLoadAudio(index + 1);
        } else {
          // Other errors - still try next path but don't log
          tryLoadAudio(index + 1);
        }
      };
      
      audio.addEventListener('canplaythrough', handleCanPlay, { once: true });
      audio.addEventListener('loadeddata', handleLoadedData, { once: true });
      audio.addEventListener('error', handleError, { once: true });
      
      // Try to load (load() returns void, errors are handled by error event listener)
      audio.load();
    };

    tryLoadAudio(0);

    // Cleanup on unmount
    return () => {
      if (soundIntervalRef.current) {
        clearInterval(soundIntervalRef.current);
        soundIntervalRef.current = null;
      }
      if (notificationSoundRef.current) {
        notificationSoundRef.current.pause();
        notificationSoundRef.current = null;
      }
    };
  }, []);

  // Load notifications
  const loadNotifications = async () => {
    if (!user) return;

    try {
      setLoading(true);
      const data = await notificationService.getNotifications(user.id, 50);
      setNotifications(data);
      const count = await notificationService.getUnreadCount(user.id);
      setUnreadCount(count);
    } catch (error) {
      console.error('Error loading notifications:', error);
    } finally {
      setLoading(false);
    }
  };

  // Test notification sound (for debugging)
  const testNotificationSound = () => {
    if (notificationSoundRef.current) {
      const audio = notificationSoundRef.current;
      audio.currentTime = 0;
      audio.volume = 0.8;
      audio.play()
        .then(() => {
          console.log('🔔 Test sound played successfully');
          alert('Sound played! Check your speakers/volume.');
        })
        .catch((error: any) => {
          console.error('Test sound failed:', error);
          alert(`Sound test failed: ${error.message}. Make sure your browser allows audio playback.`);
        });
    } else {
      console.warn('Notification sound not loaded');
      alert('Sound file not loaded. Check console for errors.');
    }
  };

  // Handle click on bell icon
  const handleClick = (event: React.MouseEvent<HTMLButtonElement>) => {
    event.currentTarget.blur();
    setAnchorEl(event.currentTarget);
    loadNotifications();
    
    // Test sound on first click (helps unlock audio for future notifications)
    if (notificationSoundRef.current && unreadCount === 0) {
      // Silently try to play to unlock audio
      notificationSoundRef.current.play().catch(() => {
        // Ignore - this is just to unlock audio for future notifications
      });
    }
  };

  // Handle close
  const handleClose = () => {
    setAnchorEl(null);
  };

  // Handle notification click
  const handleNotificationClick = async (notification: Notification) => {
    // Mark as read
    if (!notification.is_read) {
      try {
        await notificationService.markAsRead(notification.id, user!.id);
        setNotifications(prev =>
          prev.map(n => n.id === notification.id ? { ...n, is_read: true } : n)
        );
        setUnreadCount(prev => Math.max(0, prev - 1));
      } catch (error) {
        console.error('Error marking notification as read:', error);
      }
    }

    // Handle navigation based on notification type
    if (notification.type === 'News') {
      // Navigate to home page with news tab selected
      // Use replace to avoid adding to history, and force navigation even if already on home
      if (window.location.pathname === '/') {
        // If already on home page, update the URL to trigger the useEffect
        window.history.replaceState(null, '', '/?tab=news');
        // Force a re-render by triggering location change
        window.dispatchEvent(new PopStateEvent('popstate'));
      } else {
        navigate('/?tab=news');
      }
      handleClose();
    } else if (notification.action_url) {
      // Navigate to action URL if provided
      if (notification.action_url.includes('?tab=')) {
        // If action_url has tab parameter and we're already on that page, force update
        const urlPath = notification.action_url.split('?')[0];
        if (window.location.pathname === urlPath) {
          window.history.replaceState(null, '', notification.action_url);
          window.dispatchEvent(new PopStateEvent('popstate'));
        } else {
          navigate(notification.action_url);
        }
      } else {
        navigate(notification.action_url);
      }
      handleClose();
    } else {
      // If no action URL and not News type, just close the popover
      handleClose();
    }
  };

  // Mark all as read
  const handleMarkAllAsRead = async () => {
    if (!user) return;

    try {
      await notificationService.markAllAsRead(user.id);
      setNotifications(prev => prev.map(n => ({ ...n, is_read: true })));
      setUnreadCount(0);
    } catch (error) {
      console.error('Error marking all as read:', error);
    }
  };

  // Get icon for notification type
  const getNotificationIcon = (type: Notification['type']) => {
    switch (type) {
      case 'Match':
      case 'FightRequest':
        return <SportsMma />;
      case 'TrainingCamp':
        return <FitnessCenter />;
      case 'Callout':
        return <SportsMma />;
      case 'Dispute':
        return <Gavel />;
      case 'FightUrlSubmission':
        return <LinkIcon />;
      case 'Event':
      case 'Tournament':
        return <Event />;
      case 'News':
        return <Article />;
      case 'NewFighter':
        return <PersonAdd />;
      case 'Award':
        return <EmojiEvents />;
      default:
        return <SportsMma />;
    }
  };

  // Get color for notification type
  const getNotificationColor = (type: Notification['type']) => {
    switch (type) {
      case 'Match':
      case 'FightRequest':
        return 'primary';
      case 'TrainingCamp':
        return 'success';
      case 'Callout':
        return 'warning';
      case 'Dispute':
        return 'error';
      case 'FightUrlSubmission':
        return 'info';
      case 'Event':
      case 'Tournament':
        return 'secondary';
      case 'News':
        return 'primary';
      case 'NewFighter':
        return 'success';
      default:
        return 'default';
    }
  };

  // Format time
  const formatTime = (timestamp: string) => {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);

    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    if (hours < 24) return `${hours}h ago`;
    if (days < 7) return `${days}d ago`;
    return date.toLocaleDateString();
  };

  // Load initial unread count
  useEffect(() => {
    if (user) {
      notificationService.getUnreadCount(user.id).then(setUnreadCount);
    }
  }, [user]);

  // Play sound continuously when there are unread notifications
  useEffect(() => {
    // Stop any existing sound interval
    if (soundIntervalRef.current) {
      clearInterval(soundIntervalRef.current);
      soundIntervalRef.current = null;
    }

    // If there are unread notifications, play sound on loop
    if (unreadCount > 0 && notificationSoundRef.current) {
      const audio = notificationSoundRef.current;
      audio.volume = 0.8;
      audio.loop = true;

      const playSound = () => {
        if (audio && unreadCount > 0) {
          audio.currentTime = 0;
          audio.play().catch((error: any) => {
            // Autoplay may be blocked, but we'll try again on next interval
            console.log('Sound autoplay blocked, will retry:', error);
          });
        }
      };

      // Play immediately
      playSound();

      // Set up interval to play every 3 seconds while there are unread notifications
      soundIntervalRef.current = setInterval(() => {
        if (unreadCount > 0 && notificationSoundRef.current) {
          playSound();
        } else {
          // Stop interval if no unread notifications
          if (soundIntervalRef.current) {
            clearInterval(soundIntervalRef.current);
            soundIntervalRef.current = null;
          }
        }
      }, 3000);
    } else {
      // Stop sound if no unread notifications
      if (notificationSoundRef.current) {
        notificationSoundRef.current.pause();
        notificationSoundRef.current.currentTime = 0;
        notificationSoundRef.current.loop = false;
      }
    }

    // Cleanup on unmount or when unreadCount changes
    return () => {
      if (soundIntervalRef.current) {
        clearInterval(soundIntervalRef.current);
        soundIntervalRef.current = null;
      }
    };
  }, [unreadCount]);

  // Set up real-time subscription for notifications
  useEffect(() => {
    if (!user) return;

    const channel = supabase
      .channel('notifications_changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'notifications',
          filter: `user_id=eq.${user.id}`,
        },
        (payload) => {
          if (payload.eventType === 'INSERT') {
            const newNotification = payload.new as Notification;
            setNotifications(prev => [newNotification, ...prev]);
            setUnreadCount(prev => prev + 1);
          } else if (payload.eventType === 'UPDATE') {
            const updatedNotification = payload.new as Notification;
            setNotifications(prev =>
              prev.map(n => n.id === updatedNotification.id ? updatedNotification : n)
            );
            if (updatedNotification.is_read) {
              setUnreadCount(prev => Math.max(0, prev - 1));
            } else {
              // If notification was unread, increment count
              const wasRead = notifications.find(n => n.id === updatedNotification.id)?.is_read;
              if (wasRead && !updatedNotification.is_read) {
                setUnreadCount(prev => prev + 1);
              }
            }
          } else if (payload.eventType === 'DELETE') {
            const deletedNotification = payload.old as Notification;
            setNotifications(prev => prev.filter(n => n.id !== deletedNotification.id));
            if (!deletedNotification.is_read) {
              setUnreadCount(prev => Math.max(0, prev - 1));
            }
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user, notifications]);

  // Boxing Glove Icon Component
  const BoxingGloveIcon = ({ hasNotifications }: { hasNotifications: boolean }) => (
    <Box
      component="svg"
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      sx={{
        width: 28,
        height: 28,
        transition: 'all 0.3s ease',
        filter: hasNotifications ? 'drop-shadow(0 0 4px rgba(255, 68, 68, 0.6))' : 'none',
      }}
    >
      {/* Boxing Glove - Main body */}
      <path 
        d="M18 8c0-3.31-2.69-6-6-6S6 4.69 6 8c0 1.74.74 3.31 1.92 4.4L7 14v3c0 .55.45 1 1 1h8c.55 0 1-.45 1-1v-3l-.92-1.6C17.26 11.31 18 9.74 18 8z" 
        fill={hasNotifications ? "#ff4444" : "currentColor"}
        stroke={hasNotifications ? "#cc0000" : "currentColor"}
        strokeWidth="1.5"
      />
      {/* Wrist strap */}
      <path 
        d="M9 14h6v2H9z" 
        fill={hasNotifications ? "#cc0000" : "rgba(0,0,0,0.3)"}
      />
      {/* Laces/stitching detail */}
      <path 
        d="M10 10h4M11 11h2M10 12h4" 
        stroke="rgba(255,255,255,0.5)" 
        strokeWidth="0.8" 
        strokeLinecap="round"
      />
      {/* Thumb area */}
      <ellipse 
        cx="15" 
        cy="9" 
        rx="1.5" 
        ry="2" 
        fill={hasNotifications ? "#ff6666" : "rgba(255,255,255,0.2)"}
      />
    </Box>
  );

  if (!user) return null;

  return (
    <>
      <IconButton
        ref={anchorRef}
        color="inherit"
        onClick={handleClick}
        sx={{ 
          color: 'white',
          position: 'relative',
          '&:hover': {
            transform: 'scale(1.1)',
          },
          transition: 'transform 0.2s ease',
        }}
      >
        <Badge 
          badgeContent={unreadCount > 0 ? (unreadCount > 99 ? '99+' : unreadCount) : undefined}
          color="error"
          showZero={false}
          max={99}
          overlap="circular"
          anchorOrigin={{
            vertical: 'top',
            horizontal: 'right',
          }}
          sx={{
            '& .MuiBadge-badge': {
              fontSize: '0.75rem',
              fontWeight: 'bold',
              minWidth: unreadCount > 9 ? '24px' : '20px',
              height: '20px',
              padding: '0 4px',
              right: unreadCount > 9 ? '-4px' : '0px',
              top: '0px',
              zIndex: 1000,
              boxShadow: '0 2px 8px rgba(0,0,0,0.5)',
              border: '2px solid white',
              backgroundColor: '#dc2626',
              color: 'white',
              display: unreadCount > 0 ? 'flex' : 'none',
              alignItems: 'center',
              justifyContent: 'center',
            },
          }}
        >
          <BoxingGloveIcon hasNotifications={unreadCount > 0} />
        </Badge>
      </IconButton>

      <Popover
        open={open}
        anchorEl={anchorEl}
        onClose={handleClose}
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'right',
        }}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'right',
        }}
        PaperProps={{
          sx: {
            width: 400,
            maxHeight: 600,
            mt: 1,
          },
        }}
      >
        <Box sx={{ p: 2 }}>
          <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
            <Typography variant="h6">Notifications</Typography>
            {unreadCount > 0 && (
              <Button size="small" onClick={handleMarkAllAsRead}>
                Mark all as read
              </Button>
            )}
          </Box>

          <Divider sx={{ mb: 2 }} />

          {loading ? (
            <Box display="flex" justifyContent="center" p={3}>
              <CircularProgress size={24} />
            </Box>
          ) : notifications.length === 0 ? (
            <Box textAlign="center" p={3}>
              <Box
                sx={{
                  display: 'flex',
                  justifyContent: 'center',
                  mb: 2,
                }}
              >
                <BoxingGloveIcon hasNotifications={false} />
              </Box>
              <Typography variant="body2" color="text.secondary">
                No notifications
              </Typography>
            </Box>
          ) : (
            <List sx={{ maxHeight: 500, overflowY: 'auto' }}>
              {notifications.map((notification) => (
                <ListItem
                  key={notification.id}
                  disablePadding
                >
                  <ListItemButton
                    onClick={() => handleNotificationClick(notification)}
                    sx={{
                      bgcolor: notification.is_read ? 'transparent' : 'action.hover',
                      borderRadius: 1,
                      mb: 0.5,
                      '&:hover': {
                        bgcolor: 'action.selected',
                      },
                    }}
                  >
                    <ListItemIcon>
                      <Box sx={{ minWidth: 40 }}>
                        {getNotificationIcon(notification.type)}
                      </Box>
                    </ListItemIcon>
                    <ListItemText
                      primary={
                        <Box display="flex" justifyContent="space-between" alignItems="center" mb={0.5}>
                          <Typography variant="subtitle2" fontWeight={notification.is_read ? 'normal' : 'bold'}>
                            {notification.title}
                          </Typography>
                          {!notification.is_read && (
                            <Box
                              sx={{
                                width: 8,
                                height: 8,
                                borderRadius: '50%',
                                bgcolor: 'primary.main',
                                ml: 1,
                              }}
                            />
                          )}
                        </Box>
                      }
                      secondary={
                        <Box component="div" sx={{ mt: 0.5 }}>
                          <Typography variant="body2" color="text.secondary" component="div" sx={{ mb: 0.5 }}>
                            {notification.message}
                          </Typography>
                          <Box component="div" sx={{ display: 'flex', alignItems: 'center', gap: 0.5, flexWrap: 'wrap' }}>
                            <Chip
                              label={notification.type}
                              size="small"
                              color={getNotificationColor(notification.type) as any}
                              variant="outlined"
                              sx={{ height: 20, fontSize: '0.7rem' }}
                            />
                            <Typography variant="caption" color="text.secondary" component="span">
                              {formatTime(notification.created_at)}
                            </Typography>
                          </Box>
                        </Box>
                      }
                      secondaryTypographyProps={{ component: 'div' }}
                    />
                  </ListItemButton>
                </ListItem>
              ))}
            </List>
          )}
        </Box>
      </Popover>
    </>
  );
};

export default NotificationBell;

