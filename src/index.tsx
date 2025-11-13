import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';
import reportWebVitals from './reportWebVitals';

// Suppress browser extension errors EARLY - before any other code runs
// These errors are harmless and come from browser extensions (e.g., LastPass, Grammarly)
if (typeof window !== 'undefined') {
  // Suppress unhandled promise rejections from browser extensions
  window.addEventListener('unhandledrejection', (event) => {
    const errorMessage = event.reason?.message || event.reason?.toString() || '';
    const errorString = JSON.stringify(event.reason) || '';
    const errorStack = event.reason?.stack || '';
    const errorName = event.reason?.name || '';
    const allErrorText = `${errorMessage} ${errorString} ${errorStack} ${errorName}`;
    
    // Suppress browser extension errors (multiple variations)
    if (
      errorMessage.includes('listener indicated an asynchronous response') ||
      errorMessage.includes('message channel closed before a response was received') ||
      errorMessage.includes('A listener indicated an asynchronous response') ||
      (errorMessage.includes('asynchronous response') && errorMessage.includes('message channel')) ||
      errorMessage.includes('runtime.lastError') ||
      errorMessage.includes('Cannot create item with duplicate id') ||
      errorString.includes('listener indicated') ||
      errorString.includes('message channel closed') ||
      errorString.includes('runtime.lastError') ||
      errorString.includes('Cannot create item with duplicate id') ||
      errorString.includes('LastPass') ||
      errorStack.includes('listener indicated') ||
      errorStack.includes('message channel') ||
      allErrorText.includes('listener indicated an asynchronous response') ||
      allErrorText.includes('message channel closed before a response was received') ||
      allErrorText.includes('runtime.lastError') ||
      allErrorText.includes('Cannot create item with duplicate id')
    ) {
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();
      return false;
    }
  }, true); // Use capture phase to catch early

  // Also suppress window error events from browser extensions
  window.addEventListener('error', (event) => {
    const errorMessage = event.message || event.error?.message || '';
    // Suppress browser extension errors
    if (
      errorMessage.includes('listener indicated an asynchronous response') ||
      errorMessage.includes('message channel closed before a response was received') ||
      errorMessage.includes('A listener indicated an asynchronous response') ||
      (errorMessage.includes('asynchronous response') && errorMessage.includes('message channel')) ||
      errorMessage.includes('runtime.lastError') ||
      errorMessage.includes('Cannot create item with duplicate id')
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
    <App />
  </React.StrictMode>
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();