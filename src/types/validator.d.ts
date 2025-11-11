/**
 * Type declarations for validator module
 * This ensures TypeScript recognizes the validator module
 */

declare module 'validator' {
  export function isEmail(email: string): boolean;
  export function isURL(url: string, options?: { require_protocol?: boolean }): boolean;
  export function isUUID(uuid: string): boolean;
  export function isLength(str: string, options: { min?: number; max?: number }): boolean;
  
  const validator: {
    isEmail: typeof isEmail;
    isURL: typeof isURL;
    isUUID: typeof isUUID;
    isLength: typeof isLength;
  };
  
  export default validator;
}

