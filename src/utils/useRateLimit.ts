/**
 * React Hook for Rate Limiting
 * Provides easy-to-use rate limiting for React components
 */

import { useCallback, useRef } from 'react';
import { checkRateLimit, RATE_LIMITS } from '../utils/securityUtils';

interface UseRateLimitOptions {
  limit: number;
  windowMs: number;
  key?: string; // Optional custom key (defaults to 'default')
}

interface UseRateLimitReturn {
  checkLimit: () => { allowed: boolean; remaining: number; resetTime: number };
  reset: () => void;
}

/**
 * React hook for rate limiting
 * @param options - Rate limit configuration
 * @returns Rate limit check function and reset function
 */
export const useRateLimit = (
  options: UseRateLimitOptions | keyof typeof RATE_LIMITS
): UseRateLimitReturn => {
  const keyRef = useRef<string>(
    typeof options === 'string' ? options : options.key || 'default'
  );
  
  const limitConfig =
    typeof options === 'string'
      ? RATE_LIMITS[options]
      : { limit: options.limit, windowMs: options.windowMs };

  const checkLimit = useCallback(() => {
    return checkRateLimit(keyRef.current, limitConfig.limit, limitConfig.windowMs);
  }, [limitConfig.limit, limitConfig.windowMs]);

  const reset = useCallback(() => {
    // Note: This is a simplified reset - in production, you'd want to clear the store entry
    // For now, we'll just update the key to force a new entry
    keyRef.current = `${keyRef.current}-${Date.now()}`;
  }, []);

  return { checkLimit, reset };
};

/**
 * Pre-configured rate limit hooks for common actions
 */
export const useLoginRateLimit = () => useRateLimit('LOGIN');
export const useRegistrationRateLimit = () => useRateLimit('REGISTRATION');
export const useFileUploadRateLimit = () => useRateLimit('FILE_UPLOAD');
export const useApiRateLimit = () => useRateLimit('API_CALL');
export const useAdminRateLimit = () => useRateLimit('ADMIN_ACTION');
