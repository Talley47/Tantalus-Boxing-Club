import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';
import reportWebVitals from './reportWebVitals';
import ErrorBoundary from './components/Shared/ErrorBoundary';

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
      errorMessage.includes('by returning true, but the message channel closed') ||
      (errorMessage.includes('asynchronous response') && errorMessage.includes('message channel')) ||
      errorMessage.includes('runtime.lastError') ||
      errorMessage.includes('Cannot create item with duplicate id') ||
      errorMessage.includes('No tab with id') ||
      errorMessage.includes('background-redux') ||
      errorString.includes('listener indicated') ||
      errorString.includes('message channel closed') ||
      errorString.includes('by returning true') ||
      errorString.includes('runtime.lastError') ||
      errorString.includes('Cannot create item with duplicate id') ||
      errorString.includes('LastPass') ||
      errorString.includes('No tab with id') ||
      errorString.includes('background-redux') ||
      errorStack.includes('listener indicated') ||
      errorStack.includes('message channel') ||
      errorStack.includes('by returning true') ||
      errorStack.includes('background-redux') ||
      errorStack.includes('background-redux-new.js') ||
      allErrorText.includes('listener indicated an asynchronous response') ||
      allErrorText.includes('message channel closed before a response was received') ||
      allErrorText.includes('by returning true, but the message channel closed') ||
      allErrorText.includes('runtime.lastError') ||
      allErrorText.includes('Cannot create item with duplicate id') ||
      allErrorText.includes('No tab with id') ||
      allErrorText.includes('background-redux') ||
      allErrorText.includes('background-redux-new.js')
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
      errorMessage.includes('by returning true, but the message channel closed') ||
      (errorMessage.includes('asynchronous response') && errorMessage.includes('message channel')) ||
      errorMessage.includes('runtime.lastError') ||
      errorMessage.includes('Cannot create item with duplicate id') ||
      errorMessage.includes('No tab with id') ||
      errorMessage.includes('background-redux') ||
      (event.filename && event.filename.includes('background-redux'))
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