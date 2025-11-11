/**
 * Security Utilities
 * Provides input validation, sanitization, and security helpers
 */

import DOMPurify from 'dompurify';
import validator from 'validator';

// ============================================================================
// INPUT SANITIZATION
// ============================================================================

/**
 * Sanitize HTML content to prevent XSS attacks
 * @param html - HTML string to sanitize
 * @param allowTags - Optional array of allowed HTML tags
 * @returns Sanitized HTML string
 */
export const sanitizeHTML = (
  html: string,
  allowTags: string[] = ['b', 'i', 'em', 'strong', 'a', 'p', 'br', 'ul', 'ol', 'li']
): string => {
  if (!html || typeof html !== 'string') return '';
  
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS: allowTags,
    ALLOWED_ATTR: ['href', 'target', 'rel'],
    ALLOW_DATA_ATTR: false,
  });
};

/**
 * Sanitize plain text input (removes all HTML)
 * @param input - Text input to sanitize
 * @returns Sanitized plain text
 */
export const sanitizeText = (input: string): string => {
  if (!input || typeof input !== 'string') return '';
  return DOMPurify.sanitize(input, { ALLOWED_TAGS: [] });
};

/**
 * Sanitize URL to prevent XSS and malicious redirects
 * @param url - URL to sanitize
 * @returns Sanitized URL or empty string if invalid
 */
export const sanitizeURL = (url: string): string => {
  if (!url || typeof url !== 'string') return '';
  
  // Remove dangerous protocols
  const dangerousProtocols = ['javascript:', 'data:', 'vbscript:', 'file:'];
  const lowerUrl = url.toLowerCase().trim();
  
  for (const protocol of dangerousProtocols) {
    if (lowerUrl.startsWith(protocol)) {
      return '';
    }
  }
  
  // Validate URL format
  if (validator.isURL(url, { require_protocol: true })) {
    return url;
  }
  
  // If no protocol, assume HTTPS
  if (validator.isURL(`https://${url}`)) {
    return `https://${url}`;
  }
  
  return '';
};

// ============================================================================
// INPUT VALIDATION
// ============================================================================

/**
 * Validate email address
 * @param email - Email to validate
 * @returns Validation result
 */
export const validateEmail = (email: string): { valid: boolean; error?: string } => {
  if (!email || typeof email !== 'string') {
    return { valid: false, error: 'Email is required' };
  }
  
  const trimmed = email.trim().toLowerCase();
  
  if (trimmed.length === 0) {
    return { valid: false, error: 'Email cannot be empty' };
  }
  
  if (trimmed.length > 255) {
    return { valid: false, error: 'Email is too long (max 255 characters)' };
  }
  
  if (!validator.isEmail(trimmed)) {
    return { valid: false, error: 'Invalid email format' };
  }
  
  return { valid: true };
};

/**
 * Validate password strength
 * @param password - Password to validate
 * @returns Validation result
 */
export const validatePassword = (password: string): { valid: boolean; error?: string } => {
  if (!password || typeof password !== 'string') {
    return { valid: false, error: 'Password is required' };
  }
  
  if (password.length < 8) {
    return { valid: false, error: 'Password must be at least 8 characters long' };
  }
  
  if (password.length > 128) {
    return { valid: false, error: 'Password is too long (max 128 characters)' };
  }
  
  if (!/[A-Z]/.test(password)) {
    return { valid: false, error: 'Password must contain at least one uppercase letter' };
  }
  
  if (!/[a-z]/.test(password)) {
    return { valid: false, error: 'Password must contain at least one lowercase letter' };
  }
  
  if (!/[0-9]/.test(password)) {
    return { valid: false, error: 'Password must contain at least one number' };
  }
  
  if (!/[^A-Za-z0-9]/.test(password)) {
    return { valid: false, error: 'Password must contain at least one special character' };
  }
  
  // Check for common weak passwords
  const commonPasswords = ['password', 'password123', '12345678', 'qwerty', 'abc123'];
  if (commonPasswords.includes(password.toLowerCase())) {
    return { valid: false, error: 'Password is too common. Please choose a stronger password' };
  }
  
  return { valid: true };
};

/**
 * Validate UUID format
 * @param uuid - UUID string to validate
 * @returns Validation result
 */
export const validateUUID = (uuid: string): { valid: boolean; error?: string } => {
  if (!uuid || typeof uuid !== 'string') {
    return { valid: false, error: 'UUID is required' };
  }
  
  if (!validator.isUUID(uuid)) {
    return { valid: false, error: 'Invalid UUID format' };
  }
  
  return { valid: true };
};

/**
 * Validate text input length
 * @param text - Text to validate
 * @param minLength - Minimum length
 * @param maxLength - Maximum length
 * @param fieldName - Field name for error message
 * @returns Validation result
 */
export const validateTextLength = (
  text: string,
  minLength: number,
  maxLength: number,
  fieldName: string = 'Text'
): { valid: boolean; error?: string } => {
  if (!text || typeof text !== 'string') {
    return { valid: false, error: `${fieldName} is required` };
  }
  
  const trimmed = text.trim();
  
  if (trimmed.length < minLength) {
    return { valid: false, error: `${fieldName} must be at least ${minLength} characters` };
  }
  
  if (trimmed.length > maxLength) {
    return { valid: false, error: `${fieldName} must be no more than ${maxLength} characters` };
  }
  
  return { valid: true };
};

// ============================================================================
// FILE VALIDATION
// ============================================================================

export const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'] as const;
export const ALLOWED_VIDEO_TYPES = ['video/mp4', 'video/webm', 'video/quicktime'] as const;
export const MAX_IMAGE_SIZE = 10 * 1024 * 1024; // 10MB
export const MAX_VIDEO_SIZE = 50 * 1024 * 1024; // 50MB

/**
 * Validate file upload
 * @param file - File to validate
 * @param type - File type ('image' or 'video')
 * @returns Validation result
 */
export const validateFileUpload = (
  file: File,
  type: 'image' | 'video'
): { valid: boolean; error?: string } => {
  if (!file || !(file instanceof File)) {
    return { valid: false, error: 'Invalid file' };
  }
  
  // Check file type
  const allowedTypes = type === 'image' ? ALLOWED_IMAGE_TYPES : ALLOWED_VIDEO_TYPES;
  const fileType = file.type;
  // Type-safe check using type guard
  const isValidType = (allowedTypes as readonly string[]).includes(fileType);
  if (!isValidType) {
    return {
      valid: false,
      error: `Invalid ${type} type. Allowed types: ${allowedTypes.join(', ')}`
    };
  }
  
  // Check file size
  const maxSize = type === 'image' ? MAX_IMAGE_SIZE : MAX_VIDEO_SIZE;
  if (file.size > maxSize) {
    const maxSizeMB = Math.round(maxSize / 1024 / 1024);
    return {
      valid: false,
      error: `File too large. Maximum size: ${maxSizeMB}MB`
    };
  }
  
  // Check filename (prevent path traversal attacks)
  if (file.name.includes('..') || file.name.includes('/') || file.name.includes('\\')) {
    return { valid: false, error: 'Invalid filename' };
  }
  
  // Check filename length
  if (file.name.length > 255) {
    return { valid: false, error: 'Filename is too long' };
  }
  
  return { valid: true };
};

// ============================================================================
// RATE LIMITING (Client-Side)
// ============================================================================

interface RateLimitEntry {
  count: number;
  resetTime: number;
}

const rateLimitStore = new Map<string, RateLimitEntry>();

/**
 * Check if action is within rate limit
 * @param key - Unique identifier for rate limiting (e.g., userId, IP)
 * @param limit - Maximum number of actions allowed
 * @param windowMs - Time window in milliseconds
 * @returns Whether action is allowed
 */
export const checkRateLimit = (
  key: string,
  limit: number,
  windowMs: number
): { allowed: boolean; remaining: number; resetTime: number } => {
  const now = Date.now();
  const entry = rateLimitStore.get(key);
  
  // Clean up expired entries periodically
  if (Math.random() < 0.01) { // 1% chance to clean up
    const entries = Array.from(rateLimitStore.entries());
    for (const [k, v] of entries) {
      if (now > v.resetTime) {
        rateLimitStore.delete(k);
      }
    }
  }
  
  // No entry or expired entry
  if (!entry || now > entry.resetTime) {
    rateLimitStore.set(key, {
      count: 1,
      resetTime: now + windowMs
    });
    return {
      allowed: true,
      remaining: limit - 1,
      resetTime: now + windowMs
    };
  }
  
  // Check if limit exceeded
  if (entry.count >= limit) {
    return {
      allowed: false,
      remaining: 0,
      resetTime: entry.resetTime
    };
  }
  
  // Increment count
  entry.count++;
  return {
    allowed: true,
    remaining: limit - entry.count,
    resetTime: entry.resetTime
  };
};

/**
 * Rate limit presets for common actions
 */
export const RATE_LIMITS = {
  LOGIN: { limit: 5, windowMs: 60 * 1000 }, // 5 per minute
  REGISTRATION: { limit: 3, windowMs: 60 * 60 * 1000 }, // 3 per hour
  FILE_UPLOAD: { limit: 10, windowMs: 60 * 1000 }, // 10 per minute
  API_CALL: { limit: 100, windowMs: 60 * 1000 }, // 100 per minute
  ADMIN_ACTION: { limit: 50, windowMs: 60 * 1000 }, // 50 per minute
} as const;

// ============================================================================
// ERROR HANDLING
// ============================================================================

/**
 * Sanitize error message for user display (prevents info leakage)
 * @param error - Error object or message
 * @param userMessage - Optional user-friendly message
 * @returns Sanitized error message
 */
export const sanitizeErrorMessage = (
  error: unknown,
  userMessage: string = 'An error occurred. Please try again.'
): string => {
  // Log full error server-side (in production, use proper logging service)
  if (error instanceof Error) {
    console.error('Error details:', {
      message: error.message,
      stack: error.stack,
      name: error.name
    });
  } else {
    console.error('Error:', error);
  }
  
  // Return generic user message (never expose internal errors)
  return userMessage;
};

/**
 * Check if error is a security-related error
 * @param error - Error to check
 * @returns Whether error is security-related
 */
export const isSecurityError = (error: unknown): boolean => {
  if (error instanceof Error) {
    const message = error.message.toLowerCase();
    return (
      message.includes('unauthorized') ||
      message.includes('forbidden') ||
      message.includes('permission') ||
      message.includes('access denied') ||
      message.includes('authentication') ||
      message.includes('authorization')
    );
  }
  return false;
};

// ============================================================================
// SECURITY HELPERS
// ============================================================================

/**
 * Generate a secure random string
 * @param length - Length of string
 * @returns Random string
 */
export const generateSecureToken = (length: number = 32): string => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const array = new Uint8Array(length);
  crypto.getRandomValues(array);
  return Array.from(array, byte => chars[byte % chars.length]).join('');
};

/**
 * Check if string contains potentially dangerous content
 * @param input - String to check
 * @returns Whether string is safe
 */
export const isSafeString = (input: string): boolean => {
  if (!input || typeof input !== 'string') return false;
  
  // Check for script tags
  if (/<script/i.test(input)) return false;
  
  // Check for javascript: protocol
  if (/javascript:/i.test(input)) return false;
  
  // Check for data: protocol (can be used for XSS)
  if (/data:text\/html/i.test(input)) return false;
  
  // Check for onerror, onclick, etc.
  if (/on\w+\s*=/i.test(input)) return false;
  
  return true;
};

