import React, { useState, useEffect } from 'react';
import {
  Box,
  TextField,
  Button,
  Typography,
  Link,
  Alert,
  Container,
  Paper,
} from '@mui/material';
import { Login as LoginIcon } from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';
import { useNavigate, useSearchParams } from 'react-router-dom';
import TBCLogo from '../Shared/TBCLogo';
import logoBackground from '../../Logo0.png';

const LoginPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');
  
  const { signIn } = useAuth();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  useEffect(() => {
    const message = searchParams.get('message');
    if (message) {
      setSuccessMessage(decodeURIComponent(message));
    }
  }, [searchParams]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    // Basic validation
    if (!email.trim()) {
      setError('Please enter your email address');
      setLoading(false);
      return;
    }

    if (!password.trim()) {
      setError('Please enter your password');
      setLoading(false);
      return;
    }

    try {
      await signIn(email.trim(), password);
      navigate('/');
    } catch (err: any) {
      // Don't log "Invalid login credentials" as an error - it's expected and user-friendly
      const isExpectedError = 
        err?.message?.toLowerCase().includes('invalid login credentials') ||
        err?.message?.toLowerCase().includes('invalid credentials');
      
      if (!isExpectedError) {
        console.error('Login error:', err);
      }
      
      // Provide more helpful error messages
      if (err.message?.includes('Invalid login credentials') || err.message?.includes('Invalid credentials')) {
        setError('Invalid email or password. Please check your credentials and try again.');
      } else if (err.message?.includes('Email not confirmed')) {
        setError('Please check your email and confirm your account before signing in.');
      } else if (err.message?.includes('Too many requests')) {
        setError('Too many login attempts. Please wait a moment and try again.');
      } else if (err.message) {
        setError(err.message);
      } else {
        setError('Failed to sign in. Please check your credentials and try again.');
      }
    } finally {
      setLoading(false);
    }
  };


  return (
    <Box
      sx={{
        minHeight: '100vh',
        width: '100vw',
        backgroundImage: `url(${logoBackground})`,
        backgroundSize: '100% 100%',
        backgroundPosition: 'center',
        backgroundRepeat: 'no-repeat',
        backgroundAttachment: 'fixed',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 2,
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
      }}
    >
      <Container component="main" maxWidth="sm">
        <Box
          sx={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
          }}
        >
        <Paper
          elevation={3}
          sx={{
            padding: 4,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            width: '100%',
            borderRadius: 3,
            backgroundColor: 'rgba(255, 255, 255, 0.95)',
            backdropFilter: 'blur(10px)',
          }}
        >
          <TBCLogo />
          
          <Typography 
            component="h1" 
            variant="h4" 
            gutterBottom
            sx={{
              color: '#d32f2f',
              fontWeight: 'bold'
            }}
          >
            Tantalus Boxing Club
          </Typography>
          
          <Typography variant="h6" color="text.secondary" gutterBottom>
            Virtual Boxing League
          </Typography>

          <Box component="form" onSubmit={handleSubmit} sx={{ mt: 1, width: '100%' }}>
            {successMessage && (
              <Alert severity="success" sx={{ mb: 2 }}>
                {successMessage}
              </Alert>
            )}
            
            {error && (
              <Alert severity="error" sx={{ mb: 2 }}>
                {error}
              </Alert>
            )}

            <TextField
              margin="normal"
              required
              fullWidth
              id="email"
              label="Email Address"
              name="email"
              autoFocus
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              inputProps={{ 
                autoComplete: 'email'
              }}
            />
            
            <TextField
              margin="normal"
              required
              fullWidth
              name="password"
              label="Password"
              type="password"
              id="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              inputProps={{ 
                autoComplete: 'current-password'
              }}
            />
            
            <Button
              type="submit"
              fullWidth
              variant="contained"
              sx={{ mt: 3, mb: 2 }}
              disabled={loading}
              startIcon={<LoginIcon />}
            >
              {loading ? 'Signing In...' : 'Sign In'}
            </Button>
          </Box>
          
          <Box textAlign="center" sx={{ mt: 2 }}>
            <Button
              type="button"
              variant="text"
              onClick={() => navigate('/register')}
              sx={{ 
                textTransform: 'none',
                color: 'primary.main',
                '&:hover': {
                  backgroundColor: 'transparent',
                  textDecoration: 'underline'
                }
              }}
            >
              Don't have an account? Sign Up
            </Button>
          </Box>
        </Paper>
        </Box>
      </Container>
    </Box>
  );
};

export default LoginPage;

