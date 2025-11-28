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
      
      // Initialize read state tracking
      notificationReadStatesRef.current.clear();
      data.forEach(notification => {
        notificationReadStatesRef.current.set(notification.id, notification.is_read || false);
      });
      
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
    } else if (notification.type === 'Sanction') {
      // Navigate to home page with Boxing Sanctions tab selected
      if (window.location.pathname === '/') {
        // If already on home page, update the URL to trigger the useEffect
        window.history.replaceState(null, '', '/?tab=sanctions');
        // Force a re-render by triggering location change
        window.dispatchEvent(new PopStateEvent('popstate'));
      } else {
        navigate('/?tab=sanctions');
      }
      handleClose();
    } else if (notification.type === 'NewFighter') {
      // Navigate to the new fighter's profile page
      console.log('NewFighter notification clicked:', notification);
      console.log('Action URL:', notification.action_url);
      
      if (notification.action_url) {
        // Clean the action_url to ensure it's a valid path
        let targetUrl = notification.action_url.trim();
        
        // Remove any query parameters for now (we can add them back if needed)
        if (targetUrl.includes('?')) {
          targetUrl = targetUrl.split('?')[0];
        }
        
        // Ensure it starts with /fighter/
        if (!targetUrl.startsWith('/fighter/')) {
          console.log('NewFighter notification has non-standard action_url, extracting fighter info from message:', notification.action_url);
          
          // Try to extract user_id from the URL if it's malformed
          const userIdMatch = notification.action_url.match(/fighter[\/\s]+([a-f0-9-]{36})/i);
          if (userIdMatch) {
            targetUrl = `/fighter/${userIdMatch[1]}`;
            console.log('Extracted user_id from malformed URL, using:', targetUrl);
            navigate(targetUrl);
            handleClose();
            return;
          }
          
          // If URL doesn't contain user_id, try to extract fighter name from message
          // Try multiple patterns to extract fighter name
          let fighterName: string | null = null;
          
          // Pattern 1: "{name} has joined the club!"
          const nameMatch1 = notification.message?.match(/^(.+?)\s+has joined the club!/i);
          if (nameMatch1 && nameMatch1[1]) {
            fighterName = nameMatch1[1].trim();
          }
          
          // Pattern 2: "New Fighter: {name}" or similar
          if (!fighterName) {
            const nameMatch2 = notification.message?.match(/New Fighter[:\s]+(.+?)(?:\s|$)/i);
            if (nameMatch2 && nameMatch2[1]) {
              fighterName = nameMatch2[1].trim();
            }
          }
          
          // Pattern 3: Extract any name before common phrases
          if (!fighterName) {
            const nameMatch3 = notification.message?.match(/^(.+?)(?:\s+has joined|\s+joined|$)/i);
            if (nameMatch3 && nameMatch3[1] && nameMatch3[1].length > 0) {
              fighterName = nameMatch3[1].trim();
            }
          }
          
          if (fighterName) {
            console.log('Extracted fighter name from message:', fighterName);
            
            // Query database to find fighter by name (case-insensitive, try exact match first)
            try {
              let { data, error } = await supabase
                .from('fighter_profiles')
                .select('user_id, name, created_at')
                .ilike('name', fighterName)  // Case-insensitive match
                .order('created_at', { ascending: false })
                .limit(5);  // Get multiple in case of duplicates
              
              // If no exact match, try partial match
              if (error || !data || data.length === 0) {
                console.log('Trying partial name match...');
                const { data: partialData, error: partialError } = await supabase
                  .from('fighter_profiles')
                  .select('user_id, name, created_at')
                  .ilike('name', `%${fighterName}%`)  // Partial match
                  .order('created_at', { ascending: false })
                  .limit(5);
                
                if (!partialError && partialData && partialData.length > 0) {
                  data = partialData;
                  error = null;
                }
              }
              
              // If still no match, try to find the most recently created fighter
              if (error || !data || data.length === 0) {
                console.log('Trying to find most recently created fighter...');
                const { data: recentData, error: recentError } = await supabase
                  .from('fighter_profiles')
                  .select('user_id, name, created_at')
                  .order('created_at', { ascending: false })
                  .limit(1)
                  .single();
                
                if (!recentError && recentData?.user_id) {
                  console.log('Using most recently created fighter:', recentData.name);
                  targetUrl = `/fighter/${recentData.user_id}`;
                  navigate(targetUrl);
                  handleClose();
                  return;
                }
              }
              
              if (!error && data && data.length > 0) {
                // Use the first (most recent) match
                const fighter = data[0];
                targetUrl = `/fighter/${fighter.user_id}`;
                console.log('Found fighter by name, navigating to:', targetUrl, 'Fighter:', fighter.name);
                navigate(targetUrl);
                handleClose();
                return;
              } else {
                console.error('Could not find fighter by name:', fighterName, error);
              }
            } catch (err) {
              console.error('Error querying fighter by name:', err);
            }
          } else {
            console.warn('Could not extract fighter name from message:', notification.message);
          }
          
          // If we still can't find the fighter, try to get the most recently created fighter
          console.log('Attempting fallback: finding most recently created fighter...');
          try {
            const { data: recentFighter, error: recentError } = await supabase
              .from('fighter_profiles')
              .select('user_id, name, created_at')
              .order('created_at', { ascending: false })
              .limit(1)
              .single();
            
            if (!recentError && recentFighter?.user_id) {
              targetUrl = `/fighter/${recentFighter.user_id}`;
              console.log('Using most recently created fighter as fallback:', recentFighter.name);
              navigate(targetUrl);
              handleClose();
              return;
            }
          } catch (err) {
            console.error('Error in fallback fighter lookup:', err);
          }
          
          // Last resort: show error
          console.error('Could not determine fighter profile URL from notification');
          console.error('Notification details:', {
            id: notification.id,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            action_url: notification.action_url
          });
          alert(`Unable to navigate to fighter profile. The notification may be missing required information.\n\nNotification: ${notification.message || notification.title}`);
          handleClose();
          return;
        }
        
        console.log('Navigating to fighter profile:', targetUrl);
        
        // Navigate to the fighter profile
        navigate(targetUrl);
      } else {
        // Fallback: try to find the fighter by name from the message
        console.warn('NewFighter notification missing action_url, attempting to find fighter by name');
        console.warn('Full notification object:', JSON.stringify(notification, null, 2));
        
        // Try multiple patterns to extract fighter name from message
        let fighterName: string | null = null;
        
        // Pattern 1: "{name} has joined the club!"
        const nameMatch1 = notification.message?.match(/^(.+?)\s+has joined the club!/i);
        if (nameMatch1 && nameMatch1[1]) {
          fighterName = nameMatch1[1].trim();
        }
        
        // Pattern 2: "New Fighter: {name}" or similar
        if (!fighterName) {
          const nameMatch2 = notification.message?.match(/New Fighter[:\s]+(.+?)(?:\s|$)/i);
          if (nameMatch2 && nameMatch2[1]) {
            fighterName = nameMatch2[1].trim();
          }
        }
        
        // Pattern 3: Extract any name before common phrases
        if (!fighterName) {
          const nameMatch3 = notification.message?.match(/^(.+?)(?:\s+has joined|\s+joined|$)/i);
          if (nameMatch3 && nameMatch3[1] && nameMatch3[1].length > 0) {
            fighterName = nameMatch3[1].trim();
          }
        }
        
        if (fighterName) {
          console.log('Extracted fighter name from message:', fighterName);
          
          // Query database to find fighter by name (case-insensitive)
          supabase
            .from('fighter_profiles')
            .select('user_id, name, created_at')
            .ilike('name', fighterName)  // Case-insensitive match
            .order('created_at', { ascending: false })
            .limit(1)
            .single()
            .then(({ data, error }) => {
              if (!error && data?.user_id) {
                console.log('Found fighter user_id:', data.user_id, 'Name:', data.name);
                navigate(`/fighter/${data.user_id}`);
              } else {
                // Try partial match
                console.log('Trying partial name match...');
                supabase
                  .from('fighter_profiles')
                  .select('user_id, name, created_at')
                  .ilike('name', `%${fighterName}%`)
                  .order('created_at', { ascending: false })
                  .limit(1)
                  .single()
                  .then(({ data: partialData, error: partialError }) => {
                    if (!partialError && partialData?.user_id) {
                      console.log('Found fighter with partial match:', partialData.user_id);
                      navigate(`/fighter/${partialData.user_id}`);
                    } else {
                      // Last resort: get most recently created fighter
                      console.log('Trying to find most recently created fighter...');
                      supabase
                        .from('fighter_profiles')
                        .select('user_id, name, created_at')
                        .order('created_at', { ascending: false })
                        .limit(1)
                        .single()
                        .then(({ data: recentData, error: recentError }) => {
                          if (!recentError && recentData?.user_id) {
                            console.log('Using most recently created fighter:', recentData.name);
                            navigate(`/fighter/${recentData.user_id}`);
                          } else {
                            console.error('Could not find fighter by name:', fighterName, error, partialError, recentError);
                            alert(`Could not find fighter profile for "${fighterName}". The notification may be missing required information.`);
                          }
                        });
                    }
                  });
              }
            });
        } else {
          console.error('Could not extract fighter name from notification message:', notification.message);
          // Try to get most recently created fighter as fallback
          supabase
            .from('fighter_profiles')
            .select('user_id, name, created_at')
            .order('created_at', { ascending: false })
            .limit(1)
            .single()
            .then(({ data, error }) => {
              if (!error && data?.user_id) {
                console.log('Using most recently created fighter as fallback:', data.name);
                navigate(`/fighter/${data.user_id}`);
              } else {
                alert('Unable to navigate to fighter profile. The notification is missing required information.');
              }
            });
        }
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
      notificationService.getUnreadCount(user.id)
        .then(count => {
          console.log('Initial unread count loaded:', count);
          setUnreadCount(count);
        })
        .catch(error => {
          console.error('Error loading initial unread count:', error);
          setUnreadCount(0);
        });
    } else {
      setUnreadCount(0);
    }
  }, [user]);

  // Removed debug logging to improve performance

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

  // Track notification read states in a ref to avoid dependency issues
  const notificationReadStatesRef = useRef<Map<string, boolean>>(new Map());

  // Set up real-time subscription for notifications
  useEffect(() => {
    if (!user) return;

    // Use a debounce mechanism to batch rapid updates
    let updateTimeout: NodeJS.Timeout | null = null;
    const pendingUpdates: Array<() => void> = [];

    const processPendingUpdates = () => {
      if (pendingUpdates.length === 0) return;
      
      // Process all pending updates
      pendingUpdates.forEach(update => update());
      pendingUpdates.length = 0;
    };

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
          // Batch updates to avoid overwhelming the message handler
          if (updateTimeout) {
            clearTimeout(updateTimeout);
          }

          const updateFn = () => {
            if (payload.eventType === 'INSERT') {
              const newNotification = payload.new as Notification;
              // Update read state tracking
              notificationReadStatesRef.current.set(newNotification.id, newNotification.is_read || false);
              
              setNotifications(prev => {
                // Avoid duplicates
                if (prev.some(n => n.id === newNotification.id)) {
                  return prev;
                }
                return [newNotification, ...prev];
              });
              
              // Only increment if unread
              if (!newNotification.is_read) {
                setUnreadCount(prev => (prev || 0) + 1);
              }
            } else if (payload.eventType === 'UPDATE') {
              const updatedNotification = payload.new as Notification;
              const previousReadState = notificationReadStatesRef.current.get(updatedNotification.id) ?? false;
              
              // Update read state tracking
              notificationReadStatesRef.current.set(updatedNotification.id, updatedNotification.is_read || false);
              
              setNotifications(prev =>
                prev.map(n => n.id === updatedNotification.id ? updatedNotification : n)
              );
              
              // Update unread count based on read state change
              if (previousReadState && !updatedNotification.is_read) {
                // Was read, now unread - increment
                setUnreadCount(prev => (prev || 0) + 1);
              } else if (!previousReadState && updatedNotification.is_read) {
                // Was unread, now read - decrement
                setUnreadCount(prev => Math.max(0, (prev || 0) - 1));
              }
            } else if (payload.eventType === 'DELETE') {
              const deletedNotification = payload.old as Notification;
              const wasRead = notificationReadStatesRef.current.get(deletedNotification.id) ?? false;
              
              // Remove from read state tracking
              notificationReadStatesRef.current.delete(deletedNotification.id);
              
              setNotifications(prev => prev.filter(n => n.id !== deletedNotification.id));
              
              // Only decrement if it was unread
              if (!wasRead) {
                setUnreadCount(prev => Math.max(0, (prev || 0) - 1));
              }
            }
          };

          // Batch updates - process immediately for single updates, batch for rapid updates
          pendingUpdates.push(updateFn);
          
          updateTimeout = setTimeout(() => {
            processPendingUpdates();
            updateTimeout = null;
          }, 50); // 50ms debounce for batching
        }
      )
      .subscribe();

    return () => {
      if (updateTimeout) {
        clearTimeout(updateTimeout);
      }
      supabase.removeChannel(channel);
    };
  }, [user]); // Removed 'notifications' from dependencies - this was causing performance issues

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

  // Debug: Force badge to show for testing (remove after verification)
  const displayCount = unreadCount > 0 ? (unreadCount > 99 ? '99+' : unreadCount) : null;

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
          badgeContent={displayCount}
          color="error"
          showZero={false}
          max={99}
          overlap="rectangular"
          anchorOrigin={{
            vertical: 'top',
            horizontal: 'right',
          }}
          invisible={unreadCount === 0}
          sx={{
            '& .MuiBadge-badge': {
              fontSize: '0.7rem',
              fontWeight: 'bold',
              minWidth: '20px',
              height: '20px',
              padding: '0 4px',
              right: '4px',
              top: '4px',
              zIndex: 1001,
              boxShadow: '0 2px 8px rgba(0,0,0,0.8)',
              border: '2px solid white',
              backgroundColor: '#dc2626 !important',
              color: 'white !important',
              display: unreadCount > 0 ? 'flex' : 'none',
              alignItems: 'center',
              justifyContent: 'center',
              lineHeight: 1,
              fontFamily: 'Arial, sans-serif',
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
        hideBackdrop
        disableRestoreFocus
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
                          {notification.type === 'NewFighter' && notification.action_url && (
                            <Typography variant="caption" color="primary" component="div" sx={{ mb: 0.5, fontStyle: 'italic' }}>
                              Click to view profile
                            </Typography>
                          )}
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

