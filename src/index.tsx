import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';
import reportWebVitals from './reportWebVitals';
import ErrorBoundary from './components/Shared/ErrorBoundary';

// Suppress browser extension errors EARLY - before any other code runs
// These errors are harmless and come from browser extensions (e.g., LastPass, Grammarly)
if (typeof window !== 'undefined') {
  // Also suppress at console level to prevent console logging
  const originalConsoleError = console.error;
  console.error = (...args: any[]) => {
    const errorMessage = args[0]?.toString() || '';
    const allArgs = args.join(' ');
    
    // Check if this is a browser extension error
    const isBrowserExtensionError = 
      errorMessage.includes('listener indicated') ||
      errorMessage.includes('asynchronous response') ||
      errorMessage.includes('message channel') ||
      errorMessage.includes('by returning true') ||
      errorMessage.includes('runtime.lastError') ||
      errorMessage.includes('Cannot create item') ||
      errorMessage.includes('No tab with id') ||
      errorMessage.includes('background-redux') ||
      errorMessage.includes('$ is not defined') ||
      errorMessage.includes('ReferenceError: $') ||
      allArgs.includes('listener indicated') ||
      allArgs.includes('asynchronous response') ||
      allArgs.includes('message channel') ||
      allArgs.includes('by returning true') ||
      allArgs.includes('runtime.lastError') ||
      allArgs.includes('content-script') ||
      allArgs.includes('ch-content-script');
    
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
    const allErrorText = `${errorMessage} ${errorString} ${errorStack} ${errorName}`;
    
    // More comprehensive check - catch any variation of browser extension errors
    // Check for partial matches to catch all variations
    const isBrowserExtensionError = 
      errorMessage.includes('$ is not defined') ||
      errorMessage.includes('ReferenceError: $') ||
      (errorName === 'ReferenceError' && (errorMessage.includes('$') || errorString.includes('$'))) ||
      errorStack.includes('content-script') ||
      errorStack.includes('ch-content-script') ||
      errorMessage.includes('listener indicated') ||
      errorMessage.includes('asynchronous response') ||
      errorMessage.includes('message channel') ||
      errorMessage.includes('by returning true') ||
      errorMessage.includes('runtime.lastError') ||
      errorMessage.includes('Cannot create item') ||
      errorMessage.includes('No tab with id') ||
      errorMessage.includes('background-redux') ||
      errorString.includes('listener indicated') ||
      errorString.includes('asynchronous response') ||
      errorString.includes('message channel') ||
      errorString.includes('by returning true') ||
      errorString.includes('runtime.lastError') ||
      errorString.includes('LastPass') ||
      errorStack.includes('listener indicated') ||
      errorStack.includes('message channel') ||
      errorStack.includes('by returning true') ||
      errorStack.includes('background-redux') ||
      errorStack.includes('content-script') ||
      errorStack.includes('ch-content-script') ||
      allErrorText.includes('listener indicated') ||
      allErrorText.includes('asynchronous response') ||
      allErrorText.includes('message channel') ||
      allErrorText.includes('by returning true');
    
    if (isBrowserExtensionError) {
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();
      return false;
    }
  }, true); // Use capture phase to catch early

  // Also suppress window error events from browser extensions
  window.addEventListener('error', (event) => {
    const errorMessage = event.message || event.error?.message || '';
    const errorFilename = event.filename || '';
    const errorName = event.error?.name || '';
    
    // Suppress jQuery ($) not defined errors from browser extension content scripts
    if (
      errorMessage.includes('$ is not defined') ||
      errorMessage.includes('ReferenceError: $') ||
      (errorName === 'ReferenceError' && errorMessage.includes('$')) ||
      errorFilename.includes('content-script') ||
      errorFilename.includes('ch-content-script')
    ) {
      event.preventDefault();
      event.stopPropagation();
      return false;
    }
    
    // Suppress browser extension errors
    if (
      errorMessage.includes('listener indicated an asynchronous response') ||
      errorMessage.includes('message channel closed before a response was received') ||
      errorMessage.includes('A listener indicated an asynchronous response') ||
      errorMessage.includes('by returning true, but the message channel closed') ||
      (errorMessage.includes('asynchronous response') && errorMessage.includes('message channel')) ||
      errorMessage.includes('runtime.lastError') ||
      errorMessage.includes('Cannot create item with duplicate id') ||
      errorMessage.includes('No tab with id') ||
      errorMessage.includes('background-redux') ||
      (event.filename && (event.filename.includes('background-redux') || 
                          event.filename.includes('content-script') ||
                          event.filename.includes('ch-content-script')))
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