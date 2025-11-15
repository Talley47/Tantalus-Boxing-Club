import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';
import reportWebVitals from './reportWebVitals';
import ErrorBoundary from './components/Shared/ErrorBoundary';

// Suppress browser extension errors EARLY - before any other code runs
// These errors are harmless and come from browser extensions (e.g., LastPass, Grammarly)
if (typeof window !== 'undefined') {
  // Add a helpful message explaining browser extension errors (only in development)
  if (process.env.NODE_ENV === 'development') {
    // Use setTimeout to ensure this runs after browser extension errors are logged
    setTimeout(() => {
      console.log(
        '%cℹ️ Browser Extension Errors',
        'color: #2196F3; font-weight: bold; font-size: 12px;'
      );
      console.log(
        '%cIf you see errors like "No tab with id", "Unchecked runtime.lastError", or "Cannot find menu item" in the console, these are harmless browser extension errors (LastPass, Redux DevTools, etc.) and can be safely ignored. They do not affect the app\'s functionality.',
        'color: #666; font-size: 11px; line-height: 1.4;'
      );
    }, 1000);
  }
  // Also suppress at console level to prevent console logging
  const originalConsoleError = console.error;
  console.error = (...args: any[]) => {
    const errorMessage = args[0]?.toString() || '';
    const allArgs = args.join(' ').toLowerCase();
    const lowerErrorMessage = errorMessage.toLowerCase();
    
    // Check if this is a browser extension error (check chrome-extension:// URLs)
    // Also catch "Unchecked runtime.lastError" errors from LastPass and other extensions
    const isBrowserExtensionError = 
      lowerErrorMessage.includes('listener indicated') ||
      lowerErrorMessage.includes('asynchronous response') ||
      lowerErrorMessage.includes('message channel') ||
      lowerErrorMessage.includes('by returning true') ||
      lowerErrorMessage.includes('runtime.lasterror') ||
      lowerErrorMessage.includes('unchecked runtime.lasterror') ||
      lowerErrorMessage.includes('runtime.lasterror') ||
      lowerErrorMessage.includes('unchecked runtime.lasterror') ||
      lowerErrorMessage.includes('cannot create item') ||
      (lowerErrorMessage.includes('unchecked runtime') && lowerErrorMessage.includes('cannot create item')) ||
      (lowerErrorMessage.includes('runtime.last') && lowerErrorMessage.includes('cannot create item')) ||
      lowerErrorMessage.includes('cannot find menu item') ||
      lowerErrorMessage.includes('no tab with id') ||
      lowerErrorMessage.includes('background-redux') ||
      lowerErrorMessage.includes('$ is not defined') ||
      lowerErrorMessage.includes('referenceerror: $') ||
      allArgs.includes('listener indicated') ||
      allArgs.includes('asynchronous response') ||
      allArgs.includes('message channel') ||
      allArgs.includes('by returning true') ||
      allArgs.includes('runtime.lasterror') ||
      allArgs.includes('unchecked runtime.lasterror') ||
      allArgs.includes('runtime.lasterror') ||
      allArgs.includes('unchecked runtime.lasterror') ||
      allArgs.includes('cannot create item') ||
      (allArgs.includes('unchecked runtime') && allArgs.includes('cannot create item')) ||
      (allArgs.includes('runtime.last') && allArgs.includes('cannot create item')) ||
      allArgs.includes('cannot find menu item') ||
      allArgs.includes('no tab with id') ||
      allArgs.includes('background-redux') ||
      allArgs.includes('chrome-extension://') ||
      allArgs.includes('content-script') ||
      allArgs.includes('ch-content-script') ||
      allArgs.includes('lastpass');
    
    // Don't log browser extension errors
    if (isBrowserExtensionError) {
      return;
    }
    
    // Log all other errors normally
    originalConsoleError.apply(console, args);
  };
  
  // Suppress unhandled promise rejections from browser extensions
  window.addEventListener('unhandledrejection', (event) => {
    const errorMessage = event.reason?.message || event.reason?.toString() || '';
    const errorString = JSON.stringify(event.reason) || '';
    const errorStack = event.reason?.stack || '';
    const errorName = event.reason?.name || '';
    const allErrorText = `${errorMessage} ${errorString} ${errorStack} ${errorName}`.toLowerCase();
    const lowerErrorMessage = errorMessage.toLowerCase();
    const lowerErrorString = errorString.toLowerCase();
    const lowerErrorStack = errorStack.toLowerCase();
    
    // More comprehensive check - catch any variation of browser extension errors
    // Check for partial matches to catch all variations (case-insensitive)
    const isBrowserExtensionError = 
      lowerErrorMessage.includes('$ is not defined') ||
      lowerErrorMessage.includes('referenceerror: $') ||
      (errorName === 'ReferenceError' && (lowerErrorMessage.includes('$') || lowerErrorString.includes('$'))) ||
      lowerErrorStack.includes('content-script') ||
      lowerErrorStack.includes('ch-content-script') ||
      lowerErrorStack.includes('chrome-extension://') ||
      lowerErrorMessage.includes('listener indicated') ||
      lowerErrorMessage.includes('asynchronous response') ||
      lowerErrorMessage.includes('message channel') ||
      lowerErrorMessage.includes('by returning true') ||
      lowerErrorMessage.includes('runtime.lasterror') ||
      lowerErrorMessage.includes('unchecked runtime.lasterror') ||
      lowerErrorMessage.includes('cannot create item') ||
      lowerErrorMessage.includes('cannot find menu item') ||
      lowerErrorMessage.includes('no tab with id') ||
      lowerErrorMessage.includes('background-redux') ||
      lowerErrorString.includes('listener indicated') ||
      lowerErrorString.includes('asynchronous response') ||
      lowerErrorString.includes('message channel') ||
      lowerErrorString.includes('by returning true') ||
      lowerErrorString.includes('runtime.lasterror') ||
      lowerErrorString.includes('unchecked runtime.lasterror') ||
      lowerErrorString.includes('cannot create item') ||
      lowerErrorString.includes('cannot find menu item') ||
      lowerErrorString.includes('lastpass') ||
      lowerErrorString.includes('no tab with id') ||
      lowerErrorString.includes('background-redux') ||
      lowerErrorString.includes('background-redux-new.js') ||
      lowerErrorString.includes('chrome-extension://') ||
      lowerErrorStack.includes('listener indicated') ||
      lowerErrorStack.includes('message channel') ||
      lowerErrorStack.includes('by returning true') ||
      lowerErrorStack.includes('runtime.lasterror') ||
      lowerErrorStack.includes('unchecked runtime.lasterror') ||
      lowerErrorStack.includes('cannot create item') ||
      lowerErrorStack.includes('cannot find menu item') ||
      lowerErrorStack.includes('background-redux') ||
      lowerErrorStack.includes('background-redux-new.js') ||
      lowerErrorStack.includes('chrome-extension://') ||
      lowerErrorStack.includes('content-script') ||
      lowerErrorStack.includes('ch-content-script') ||
      allErrorText.includes('listener indicated') ||
      allErrorText.includes('asynchronous response') ||
      allErrorText.includes('message channel') ||
      allErrorText.includes('by returning true') ||
      allErrorText.includes('runtime.lasterror') ||
      allErrorText.includes('unchecked runtime.lasterror') ||
      allErrorText.includes('cannot create item') ||
      allErrorText.includes('cannot find menu item') ||
      allErrorText.includes('no tab with id') ||
      allErrorText.includes('background-redux') ||
      allErrorText.includes('background-redux-new.js') ||
      allErrorText.includes('chrome-extension://') ||
      allErrorText.includes('lastpass');
    
    if (isBrowserExtensionError) {
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();
      return false;
    }
  }, true); // Use capture phase to catch early

  // Also suppress window error events from browser extensions and network errors
  window.addEventListener('error', (event) => {
    const errorMessage = event.message || event.error?.message || '';
    const errorFilename = event.filename || '';
    const errorName = event.error?.name || '';
    const errorTarget = event.target as HTMLElement;
    const errorSrc = (errorTarget as HTMLImageElement | HTMLScriptElement | HTMLAudioElement)?.src || '';
    const errorStack = event.error?.stack || '';
    
    // Suppress cache errors for audio files (harmless browser cache warnings)
    if (
      (errorFilename.includes('boxing-bell') || errorSrc.includes('boxing-bell')) &&
      (errorMessage.includes('ERR_CACHE_OPERATION_NOT_SUPPORTED') || 
       errorMessage.includes('Failed to load resource') ||
       errorMessage.includes('cache'))
    ) {
      event.preventDefault();
      event.stopPropagation();
      return false;
    }
    
    // Suppress 400 errors from resources (likely from browser extensions or network issues)
    if (
      errorMessage.includes('400') ||
      (errorSrc && errorMessage.includes('Failed to load resource') && errorMessage.includes('400'))
    ) {
      // Only suppress if it's not from our own API endpoints
      if (!errorSrc.includes('supabase.co') && !errorSrc.includes('tantalus')) {
        event.preventDefault();
        event.stopPropagation();
        return false;
      }
    }
    
    // Suppress 403 errors on logout endpoint (regardless of scope parameter)
    // These occur when session is already missing/expired - expected behavior
    if (
      (errorFilename.includes('/auth/v1/logout') || errorSrc.includes('/auth/v1/logout')) &&
      (errorMessage.includes('403') || errorMessage.includes('Failed to load resource'))
    ) {
      event.preventDefault();
      event.stopPropagation();
      return false;
    }
    
    // Suppress jQuery ($) not defined errors from browser extension content scripts
    if (
      errorMessage.includes('$ is not defined') ||
      errorMessage.includes('ReferenceError: $') ||
      (errorName === 'ReferenceError' && errorMessage.includes('$')) ||
      errorFilename.includes('content-script') ||
      errorFilename.includes('ch-content-script') ||
      errorStack.includes('content-script') ||
      errorStack.includes('ch-content-script')
    ) {
      event.preventDefault();
      event.stopPropagation();
      return false;
    }
    
    // Suppress browser extension errors (including background-redux-new.js and chrome-extension:// URLs)
    // Also check for errors from /login and /matchmaking routes (these are often browser extension errors)
    const lowerErrorMsg = errorMessage.toLowerCase();
    const lowerFilename = errorFilename.toLowerCase();
    const lowerStack = errorStack.toLowerCase();
    const isFromRoute = errorFilename.includes('/login') || errorFilename.includes('/matchmaking') || 
                        errorStack.includes('/login') || errorStack.includes('/matchmaking');
    
    if (
      lowerErrorMsg.includes('listener indicated an asynchronous response') ||
      lowerErrorMsg.includes('message channel closed before a response was received') ||
      lowerErrorMsg.includes('a listener indicated an asynchronous response') ||
      lowerErrorMsg.includes('by returning true, but the message channel closed') ||
      (lowerErrorMsg.includes('asynchronous response') && lowerErrorMsg.includes('message channel')) ||
      lowerErrorMsg.includes('runtime.lasterror') ||
      lowerErrorMsg.includes('unchecked runtime.lasterror') ||
      (lowerErrorMsg.includes('unchecked runtime') && lowerErrorMsg.includes('cannot create item')) ||
      (lowerErrorMsg.includes('runtime.last') && lowerErrorMsg.includes('cannot create item')) ||
      lowerErrorMsg.includes('cannot create item with duplicate id') ||
      lowerErrorMsg.includes('cannot find menu item') ||
      lowerErrorMsg.includes('no tab with id') ||
      lowerErrorMsg.includes('background-redux') ||
      lowerFilename.includes('background-redux') ||
      lowerFilename.includes('background-redux-new.js') ||
      lowerFilename.includes('chrome-extension://') ||
      lowerFilename.includes('content-script') ||
      lowerFilename.includes('ch-content-script') ||
      lowerFilename.includes('lastpass') ||
      lowerStack.includes('background-redux') ||
      lowerStack.includes('background-redux-new.js') ||
      lowerStack.includes('chrome-extension://') ||
      lowerStack.includes('content-script') ||
      lowerStack.includes('ch-content-script') ||
      lowerStack.includes('lastpass') ||
      (isFromRoute && (lowerErrorMsg.includes('listener') || lowerErrorMsg.includes('message channel') || 
                       lowerErrorMsg.includes('asynchronous response'))) ||
      (event.filename && (event.filename.toLowerCase().includes('background-redux') || 
                          event.filename.toLowerCase().includes('background-redux-new.js') ||
                          event.filename.toLowerCase().includes('chrome-extension://') ||
                          event.filename.toLowerCase().includes('content-script') ||
                          event.filename.toLowerCase().includes('ch-content-script') ||
                          event.filename.toLowerCase().includes('lastpass')))
    ) {
      event.preventDefault();
      event.stopPropagation();
      return false;
    }
  }, true);
}

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);
root.render(
  <React.StrictMode>
    <ErrorBoundary>
      <App />
    </ErrorBoundary>
  </React.StrictMode>
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();