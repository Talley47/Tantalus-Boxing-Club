import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { supabase } from '../services/supabase';
import { RealtimeChannel } from '@supabase/supabase-js';

interface RealtimeContextType {
  connectionStatus: 'connected' | 'disconnected' | 'connecting';
  reconnect: () => void;
  subscribeToFightRecords: (callback: (payload: any) => void) => () => void;
  subscribeToFighterProfiles: (callback: (payload: any) => void) => () => void;
  subscribeToScheduledFights: (callback: (payload: any) => void) => () => void;
  subscribeToRankings: (callback: (payload: any) => void) => () => void;
}

const RealtimeContext = createContext<RealtimeContextType | undefined>(undefined);

export const useRealtime = () => {
  const context = useContext(RealtimeContext);
  if (!context) {
    throw new Error('useRealtime must be used within a RealtimeProvider');
  }
  return context;
};

export const RealtimeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [connectionStatus, setConnectionStatus] = useState<'connected' | 'disconnected' | 'connecting'>('disconnected');
  const [channels, setChannels] = useState<Map<string, RealtimeChannel>>(new Map());

  const reconnect = () => {
    setConnectionStatus('connecting');
    // Reconnection logic here
    setTimeout(() => setConnectionStatus('connected'), 1000);
  };

  // Subscribe to fight_records changes
  const subscribeToFightRecords = useCallback((callback: (payload: any) => void) => {
    try {
      const channel = supabase
        .channel('fight_records_changes', {
          config: {
            broadcast: { self: false },
            presence: { key: '' }
          }
        })
        .on(
          'postgres_changes',
          {
            event: '*',
            schema: 'public',
            table: 'fight_records'
          },
          callback
        )
        .subscribe((status, err) => {
          if (status === 'SUBSCRIBED') {
            setConnectionStatus('connected');
          } else if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT' || status === 'CLOSED') {
            setConnectionStatus('disconnected');
            // Suppress CHANNEL_ERROR warnings - they're harmless when Realtime is disabled
            // CHANNEL_ERROR typically means Realtime is disabled or connection failed - this is expected
            // Only log other errors in development mode for debugging
            if (process.env.NODE_ENV === 'development' && status !== 'CLOSED' && status !== 'CHANNEL_ERROR' && status !== 'TIMED_OUT') {
              console.warn('Realtime subscription error for fight_records:', status, err);
            }
            // CHANNEL_ERROR is silently ignored - it's expected when Realtime is disabled
          }
        });

      setChannels(prev => new Map(prev).set('fight_records', channel));

      return () => {
        try {
          if (channel) {
            channel.unsubscribe();
            supabase.removeChannel(channel);
          }
        } catch (error) {
          // Silently ignore cleanup errors - WebSocket may already be closed
        }
        setChannels(prev => {
          const newMap = new Map(prev);
          newMap.delete('fight_records');
          return newMap;
        });
      };
    } catch (error) {
      // Realtime is optional - don't break the app if it fails
      console.warn('Failed to subscribe to fight_records (Realtime may be disabled):', error);
      return () => {}; // Return no-op cleanup function
    }
  }, []);

  // Subscribe to fighter_profiles changes
  const subscribeToFighterProfiles = useCallback((callback: (payload: any) => void) => {
    try {
      const channel = supabase
        .channel('fighter_profiles_changes', {
          config: {
            broadcast: { self: false },
            presence: { key: '' }
          }
        })
        .on(
          'postgres_changes',
          {
            event: '*',
            schema: 'public',
            table: 'fighter_profiles'
          },
          callback
        )
        .subscribe((status, err) => {
          if (status === 'SUBSCRIBED') {
            setConnectionStatus('connected');
          } else if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT' || status === 'CLOSED') {
            setConnectionStatus('disconnected');
            // Suppress CHANNEL_ERROR warnings - they're harmless when Realtime is disabled
            // Only log in development mode for debugging
            if (process.env.NODE_ENV === 'development' && status !== 'CLOSED' && status !== 'CHANNEL_ERROR') {
              console.warn('Realtime subscription error for fighter_profiles:', status, err);
            }
          }
        });

      setChannels(prev => new Map(prev).set('fighter_profiles', channel));

      return () => {
        try {
          if (channel) {
            channel.unsubscribe();
            supabase.removeChannel(channel);
          }
        } catch (error) {
          // Silently ignore cleanup errors - WebSocket may already be closed
        }
        setChannels(prev => {
          const newMap = new Map(prev);
          newMap.delete('fighter_profiles');
          return newMap;
        });
      };
    } catch (error) {
      // Realtime is optional - don't break the app if it fails
      console.warn('Failed to subscribe to fighter_profiles (Realtime may be disabled):', error);
      return () => {}; // Return no-op cleanup function
    }
  }, []);

  // Subscribe to scheduled_fights changes
  const subscribeToScheduledFights = useCallback((callback: (payload: any) => void) => {
    try {
      const channel = supabase
        .channel('scheduled_fights_changes', {
          config: {
            broadcast: { self: false },
            presence: { key: '' }
          }
        })
        .on(
          'postgres_changes',
          {
            event: '*',
            schema: 'public',
            table: 'scheduled_fights'
          },
          callback
        )
        .subscribe((status, err) => {
          if (status === 'SUBSCRIBED') {
            setConnectionStatus('connected');
          } else if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT' || status === 'CLOSED') {
            setConnectionStatus('disconnected');
            // Suppress CHANNEL_ERROR warnings - they're harmless when Realtime is disabled
            // Only log in development mode for debugging
            if (process.env.NODE_ENV === 'development' && status !== 'CLOSED' && status !== 'CHANNEL_ERROR') {
              console.warn('Realtime subscription error for scheduled_fights:', status, err);
            }
          }
        });

      setChannels(prev => new Map(prev).set('scheduled_fights', channel));

      return () => {
        try {
          if (channel) {
            channel.unsubscribe();
            supabase.removeChannel(channel);
          }
        } catch (error) {
          // Silently ignore cleanup errors - WebSocket may already be closed
        }
        setChannels(prev => {
          const newMap = new Map(prev);
          newMap.delete('scheduled_fights');
          return newMap;
        });
      };
    } catch (error) {
      // Realtime is optional - don't break the app if it fails
      console.warn('Failed to subscribe to scheduled_fights (Realtime may be disabled):', error);
      return () => {}; // Return no-op cleanup function
    }
  }, []);

  // Subscribe to rankings changes
  const subscribeToRankings = useCallback((callback: (payload: any) => void) => {
    try {
      const channel = supabase
        .channel('rankings_changes', {
          config: {
            broadcast: { self: false },
            presence: { key: '' }
          }
        })
        .on(
          'postgres_changes',
          {
            event: '*',
            schema: 'public',
            table: 'rankings'
          },
          callback
        )
        .subscribe((status, err) => {
          if (status === 'SUBSCRIBED') {
            setConnectionStatus('connected');
          } else if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT' || status === 'CLOSED') {
            setConnectionStatus('disconnected');
            // Suppress CHANNEL_ERROR warnings - they're harmless when Realtime is disabled
            // Only log in development mode for debugging
            if (process.env.NODE_ENV === 'development' && status !== 'CLOSED' && status !== 'CHANNEL_ERROR') {
              console.warn('Realtime subscription error for rankings:', status, err);
            }
          }
        });

      setChannels(prev => new Map(prev).set('rankings', channel));

      return () => {
        try {
          if (channel) {
            channel.unsubscribe();
            supabase.removeChannel(channel);
          }
        } catch (error) {
          // Silently ignore cleanup errors - WebSocket may already be closed
        }
        setChannels(prev => {
          const newMap = new Map(prev);
          newMap.delete('rankings');
          return newMap;
        });
      };
    } catch (error) {
      // Realtime is optional - don't break the app if it fails
      console.warn('Failed to subscribe to rankings (Realtime may be disabled):', error);
      return () => {}; // Return no-op cleanup function
    }
  }, []);

  useEffect(() => {
    // Set initial connection status
    setConnectionStatus('connecting');
    
    // Cleanup on unmount
    return () => {
      try {
        channels.forEach(channel => {
          try {
            if (channel) {
              channel.unsubscribe();
              supabase.removeChannel(channel);
            }
          } catch (error) {
            // Silently ignore cleanup errors - WebSocket may already be closed
          }
        });
      } catch (error) {
        // Silently ignore cleanup errors
      }
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <RealtimeContext.Provider value={{ 
      connectionStatus, 
      reconnect,
      subscribeToFightRecords: subscribeToFightRecords,
      subscribeToFighterProfiles: subscribeToFighterProfiles,
      subscribeToScheduledFights: subscribeToScheduledFights,
      subscribeToRankings: subscribeToRankings,
    }}>
      {children}
    </RealtimeContext.Provider>
  );
};

export default RealtimeContext;