import React, { useState, useEffect } from 'react';
import { Box, Button, Typography, Paper, Alert } from '@mui/material';
import { supabase } from '../../services/supabase';

export const DiagnosticPage: React.FC = () => {
  const [status, setStatus] = useState<any>({
    env: {},
    supabase: null,
    users: null,
    error: null
  });

  useEffect(() => {
    checkStatus();
  }, []);

  const checkStatus = async () => {
    const results: any = {
      env: {},
      supabase: null,
      users: null,
      error: null
    };

    // Check environment variables
    results.env = {
      supabaseUrl: process.env.REACT_APP_SUPABASE_URL || 'NOT SET',
      hasAnonKey: !!process.env.REACT_APP_SUPABASE_ANON_KEY
    };

    try {
      // Test Supabase connection
      const { data, error } = await supabase.from('profiles').select('count').limit(1);
      
      if (error) {
        results.supabase = `Error: ${error.message}`;
        results.error = error;
      } else {
        results.supabase = 'Connected ✓';
      }

      // Try to get admin user
      const { data: userData, error: userError } = await supabase.auth.signInWithPassword({
        email: 'admin@tantalusboxing.com',
        password: 'TantalusAdmin2025!'
      });

      if (userError) {
        results.users = `Admin login error: ${userError.message}`;
      } else {
        results.users = 'Admin account exists and can login ✓';
        // Sign out immediately
        await supabase.auth.signOut();
      }
    } catch (err: any) {
      results.error = err.message;
    }

    setStatus(results);
  };

  return (
    <Box sx={{ p: 4, maxWidth: 800, margin: '0 auto' }}>
      <Paper sx={{ p: 4 }}>
        <Typography variant="h4" gutterBottom>
          🔍 Diagnostic Page
        </Typography>

        <Box sx={{ mt: 3 }}>
          <Typography variant="h6" gutterBottom>Environment Variables:</Typography>
          <pre style={{ background: '#f5f5f5', padding: '10px', borderRadius: '4px' }}>
            {JSON.stringify(status.env, null, 2)}
          </pre>
        </Box>

        <Box sx={{ mt: 3 }}>
          <Typography variant="h6" gutterBottom>Supabase Connection:</Typography>
          <Alert severity={status.supabase?.includes('Connected') ? 'success' : 'error'}>
            {status.supabase || 'Checking...'}
          </Alert>
        </Box>

        <Box sx={{ mt: 3 }}>
          <Typography variant="h6" gutterBottom>Admin Account:</Typography>
          <Alert severity={status.users?.includes('✓') ? 'success' : 'warning'}>
            {status.users || 'Checking...'}
          </Alert>
        </Box>

        {status.error && (
          <Box sx={{ mt: 3 }}>
            <Typography variant="h6" gutterBottom color="error">Error Details:</Typography>
            <pre style={{ background: '#ffebee', padding: '10px', borderRadius: '4px', color: '#c62828' }}>
              {JSON.stringify(status.error, null, 2)}
            </pre>
          </Box>
        )}

        <Button
          variant="contained"
          onClick={checkStatus}
          sx={{ mt: 3 }}
        >
          Re-check Status
        </Button>
      </Paper>
    </Box>
  );
};

export default DiagnosticPage;


