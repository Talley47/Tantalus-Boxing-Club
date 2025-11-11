import { useRealtime } from '../contexts/RealtimeContext';

export const useRealtimeData = () => {
  const { connectionStatus, reconnect } = useRealtime();
  
  return {
    connectionStatus,
    reconnect,
    // Add more real-time data getters here
  };
};

export default useRealtimeData;