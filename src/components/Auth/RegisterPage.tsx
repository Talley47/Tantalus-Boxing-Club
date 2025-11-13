import React, { useState, useEffect } from 'react';
import {
  Box,
  Paper,
  TextField,
  Button,
  Typography,
  Link,
  Alert,
  Container,
  Avatar,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Stepper,
  Step,
  StepLabel,
  Card,
  CardContent,
  Divider,
  Grid,
} from '@mui/material';
import { 
  SportsMma, 
  PersonAdd, 
  Person, 
  FitnessCenter,
  LocationOn,
  Height,
  Scale,
  School
} from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import backgroundImage from '../../AdobeStock_567110431.jpeg';
import { WEIGHT_CLASS_ORDER } from '../../utils/weightClassUtils';
import { COMMON_TIMEZONES, getUserTimezone } from '../../utils/timezones';

const RegisterPage = () => {
  const [activeStep, setActiveStep] = useState(0);
  const [formData, setFormData] = useState({
    // Account Information
    name: '',
    email: '',
    password: '',
    confirmPassword: '',
    // Fighter Profile
    fighterName: '',
    birthday: '',
    hometown: '',
    stance: '',
    platform: '',
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC',
    heightFeet: '',
    heightInches: '',
    reach: '',
    weight: '',
    weightClass: '',
    trainer: '',
    gym: '',
  });
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  
  const { signUp } = useAuth();
  const navigate = useNavigate();

  const steps = ['Account Information', 'Fighter Profile'];

  // Ensure full-screen styling
  useEffect(() => {
    // Remove any default margins/padding from body
    document.body.style.margin = '0';
    document.body.style.padding = '0';
    document.body.style.overflow = 'hidden';
    
    // Check Supabase configuration
    const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
    const supabaseKey = process.env.REACT_APP_SUPABASE_ANON_KEY;
    
    if (!supabaseUrl || supabaseUrl.includes('your-project') || 
        !supabaseKey || supabaseKey.includes('your-anon-key')) {
      setError('🚨 CRITICAL: Supabase not configured! Please check REGISTRATION_FIX_GUIDE.md for setup instructions.');
    }
    
    // Cleanup on unmount
    return () => {
      document.body.style.margin = '';
      document.body.style.padding = '';
      document.body.style.overflow = '';
    };
  }, []);

  const handleChange = (field: string) => (e: any) => {
    const value = e.target.value;
    console.log(`handleChange for ${field}:`, value, typeof value);
    setFormData(prev => {
      const updated = {
        ...prev,
        [field]: value
      } as typeof prev;
      console.log(`Updated formData.${field}:`, (updated as any)[field]);
      return updated;
    });
  };

  const handleNext = () => {
    setActiveStep((prevActiveStep) => prevActiveStep + 1);
  };

  const handleBack = () => {
    setActiveStep((prevActiveStep) => prevActiveStep - 1);
  };

  const validateStep1 = () => {
    if (!formData.name || !formData.email || !formData.password || !formData.confirmPassword) {
      setError('Please fill in all required fields');
      return false;
    }
    // Validate email format
    const trimmedEmail = formData.email.trim();
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(trimmedEmail)) {
      setError('Please enter a valid email address');
      return false;
    }
    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match');
      return false;
    }
    if (formData.password.length < 12) {
      setError('Password must be at least 12 characters');
      return false;
    }
    setError('');
    return true;
  };

  const validateStep2 = () => {
    const missingFields: string[] = [];
    
    if (!formData.fighterName || formData.fighterName.trim() === '') {
      missingFields.push('Fighter/Boxer Name');
    }
    if (!formData.birthday) {
      missingFields.push('Birthday');
    }
    if (!formData.hometown || formData.hometown.trim() === '') {
      missingFields.push('Hometown');
    }
    if (!formData.stance || formData.stance.trim() === '') {
      missingFields.push('Stance');
    }
    const heightFeetValue = formData.heightFeet?.toString().trim() || '';
    if (!heightFeetValue || heightFeetValue === '' || isNaN(parseInt(heightFeetValue)) || parseInt(heightFeetValue) <= 0) {
      missingFields.push('Height (Feet)');
    }
    const heightInchesValue = formData.heightInches?.toString().trim() || '';
    if (!heightInchesValue || heightInchesValue === '' || isNaN(parseInt(heightInchesValue)) || parseInt(heightInchesValue) < 0) {
      missingFields.push('Height (Inches)');
    }
    const reachValue = formData.reach?.toString().trim() || '';
    console.log('Reach validation:', { reach: formData.reach, reachValue, parsed: parseInt(reachValue), isValid: !isNaN(parseInt(reachValue)) && parseInt(reachValue) > 0 });
    if (!reachValue || reachValue === '' || isNaN(parseInt(reachValue)) || parseInt(reachValue) <= 0) {
      missingFields.push('Reach');
    }
    const weightValue = formData.weight?.toString().trim() || '';
    if (!weightValue || weightValue === '' || isNaN(parseFloat(weightValue)) || parseFloat(weightValue) <= 0) {
      missingFields.push('Weight');
    }
    if (!formData.weightClass || formData.weightClass.trim() === '') {
      missingFields.push('Weight Class');
    }
    if (!formData.trainer || formData.trainer.trim() === '') {
      missingFields.push('Trainer');
    }
    if (!formData.gym || formData.gym.trim() === '') {
      missingFields.push('Gym');
    }
    
    if (missingFields.length > 0) {
      setError(`Please fill in all required fields: ${missingFields.join(', ')}`);
      console.log('Validation failed - missing fields:', missingFields);
      return false;
    }
    
    setError('');
    return true;
  };


  const handleSubmit = async (e?: React.FormEvent | React.MouseEvent) => {
    console.log('handleSubmit called', { 
      e, 
      activeStep,
      formData: {
        ...formData,
        reach: formData.reach,
        reachType: typeof formData.reach,
        reachLength: formData.reach?.toString().length
      }
    });
    if (e) {
      e.preventDefault();
      e.stopPropagation();
    }
    setLoading(true);
    setError('');

    if (!validateStep2()) {
      console.log('Validation failed');
      setLoading(false);
      return;
    }
    
    console.log('Validation passed, proceeding with registration');

    try {
      // Trim and validate email
      const trimmedEmail = formData.email.trim().toLowerCase();
      if (!trimmedEmail || !trimmedEmail.includes('@')) {
        setError('Please enter a valid email address');
        setLoading(false);
        return;
      }

      // Convert height from feet/inches to centimeters
      const heightInInches = (parseInt(formData.heightFeet) * 12) + parseInt(formData.heightInches);
      const heightInCm = Math.round(heightInInches * 2.54);
      
      // Convert weight from pounds to kilograms
      const weightInKg = Math.round(parseFloat(formData.weight) * 0.453592);
      
      // Convert reach from inches to centimeters
      const reachInCm = Math.round(parseInt(formData.reach) * 2.54);

      // Build userData object, only including platform/timezone if provided
      const userData: any = {
        name: formData.name,
        full_name: formData.name,
        fighterName: formData.fighterName,
        birthday: formData.birthday,
        hometown: formData.hometown,
        stance: formData.stance,
        height_feet: parseInt(formData.heightFeet),
        height_inches: parseInt(formData.heightInches),
        height: heightInCm, // Keep for backward compatibility
        reach: reachInCm,
        weight: weightInKg,
        weightClass: formData.weightClass,
        trainer: formData.trainer,
        gym: formData.gym,
      };
      
      // Add optional fields only if provided
      if (formData.platform) {
        userData.platform = formData.platform;
      }
      if (formData.timezone) {
        userData.timezone = formData.timezone;
      }
      
      // Log the userData being sent to help debug
      console.log('Registration userData being sent:', {
        fighterName: userData.fighterName,
        height_feet: userData.height_feet,
        height_inches: userData.height_inches,
        reach: userData.reach,
        weight: userData.weight,
        hometown: userData.hometown,
        stance: userData.stance,
        weightClass: userData.weightClass,
        trainer: userData.trainer,
        gym: userData.gym,
        platform: userData.platform,
        timezone: userData.timezone,
        birthday: userData.birthday
      });
      
      await signUp(trimmedEmail, formData.password, userData);
      
      // Registration successful - redirect to login page with success message
      const successMessage = encodeURIComponent('Account created successfully! Please check your email to verify your account, then login.');
      navigate(`/login?message=${successMessage}`);
    } catch (err: any) {
      console.error('Registration error:', err);
      
      // Check for specific error codes and messages
      const errorMessage = err.message || '';
      const errorCode = err.status || err.code || '';
      
      if (errorMessage.includes('Invalid API key') || errorCode === '401') {
        setError('Supabase configuration error. Please check your environment variables.');
      } else if (
        errorMessage.includes('duplicate key') || 
        errorMessage.includes('already registered') || 
        errorMessage.includes('User already registered') ||
        errorCode === '422' && errorMessage.includes('already')
      ) {
        setError('An account with this email already exists. Please try logging in instead, or use a different email address.');
      } else if (errorMessage.includes('violates foreign key')) {
        setError('Database configuration error. Please ensure the database schema is set up correctly.');
      } else if (errorMessage.includes('Password should be at least 12 characters') || errorMessage.includes('weak password')) {
        setError('Password must be at least 12 characters long. Please choose a stronger password.');
      } else if (errorMessage.includes('invalid format') || errorMessage.includes('Unable to validate email')) {
        setError('Please enter a valid email address. Make sure it includes @ and a domain name.');
      } else if (errorCode === '422') {
        setError('Unable to create account. This email may already be registered. Please try logging in or use a different email.');
      } else {
        setError(errorMessage || 'Failed to create account. Please check your internet connection and try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  const renderStepContent = (step: number) => {
    switch (step) {
      case 0:
        return (
          <Box component="form" sx={{ mt: 1, width: '100%' }}>
            {error && (
              <Alert severity="error" sx={{ mb: 2 }}>
                {error}
              </Alert>
            )}

            <Card sx={{ mb: 3 }}>
              <CardContent>
                <Box display="flex" alignItems="center" mb={2}>
                  <Person color="primary" sx={{ mr: 1 }} />
                  <Typography variant="h6">Account Information</Typography>
                </Box>
                
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                  <TextField
                    required
                    fullWidth
                    id="name"
                    label="Full Name"
                    name="name"
                    value={formData.name}
                    onChange={handleChange('name')}
                  />
                  
                  <TextField
                    required
                    fullWidth
                    id="email"
                    label="Email Address"
                    name="email"
                    type="email"
                    value={formData.email}
                    onChange={handleChange('email')}
                  />
                  
                  <TextField
                    required
                    fullWidth
                    name="password"
                    label="Password"
                    type="password"
                    id="password"
                    value={formData.password}
                    onChange={handleChange('password')}
                    helperText={formData.password.length > 0 && formData.password.length < 12 
                      ? `Password must be at least 12 characters (${formData.password.length}/12)`
                      : 'Password must be at least 12 characters'}
                    error={formData.password.length > 0 && formData.password.length < 12}
                    inputProps={{ minLength: 12 }}
                  />
                  
                  <TextField
                    required
                    fullWidth
                    name="confirmPassword"
                    label="Confirm Password"
                    type="password"
                    id="confirmPassword"
                    value={formData.confirmPassword}
                    onChange={handleChange('confirmPassword')}
                    helperText={formData.password !== formData.confirmPassword && formData.confirmPassword.length > 0
                      ? 'Passwords do not match'
                      : ''}
                    error={formData.password !== formData.confirmPassword && formData.confirmPassword.length > 0}
                  />
                </Box>
              </CardContent>
            </Card>
          </Box>
        );

      case 1:
        return (
          <Box component="form" onSubmit={handleSubmit} sx={{ mt: 1, width: '100%' }}>
            {error && (
              <Alert severity="error" sx={{ mb: 2 }}>
                {error}
              </Alert>
            )}

            <Card sx={{ mb: 3 }}>
              <CardContent>
                <Box display="flex" alignItems="center" mb={2}>
                  <FitnessCenter color="primary" sx={{ mr: 1 }} />
                  <Typography variant="h6">Fighter Profile</Typography>
                </Box>
                
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                  <TextField
                    required
                    fullWidth
                    id="fighterName"
                    label="Fighter/Boxer Name"
                    name="fighterName"
                    value={formData.fighterName}
                    onChange={handleChange('fighterName')}
                    placeholder="Your fighting name or nickname"
                  />
                  
                  <TextField
                    required
                    fullWidth
                    id="birthday"
                    label="Birthday"
                    name="birthday"
                    type="date"
                    value={formData.birthday}
                    onChange={handleChange('birthday')}
                    InputLabelProps={{ shrink: true }}
                  />
                  
                  <TextField
                    required
                    fullWidth
                    id="hometown"
                    label="Hometown"
                    name="hometown"
                    value={formData.hometown}
                    onChange={handleChange('hometown')}
                    placeholder="City, State/Country"
                  />
                  
                  <FormControl fullWidth required>
                    <InputLabel id="stance-select-label">Stance</InputLabel>
                    <Select
                      value={formData.stance}
                      onChange={handleChange('stance')}
                      label="Stance"
                      labelId="stance-select-label"
                      aria-labelledby="stance-select-label"
                    >
                      <MenuItem value="Orthodox" aria-label="Orthodox">Orthodox</MenuItem>
                      <MenuItem value="Southpaw" aria-label="Southpaw">Southpaw</MenuItem>
                      <MenuItem value="Switch" aria-label="Switch">Switch</MenuItem>
                    </Select>
                  </FormControl>
                  
                  <FormControl fullWidth>
                    <InputLabel id="platform-select-label">Platform (Optional)</InputLabel>
                    <Select
                      value={formData.platform}
                      onChange={handleChange('platform')}
                      label="Platform (Optional)"
                      labelId="platform-select-label"
                      aria-labelledby="platform-select-label"
                    >
                      <MenuItem value="">None</MenuItem>
                      <MenuItem value="Xbox" aria-label="Xbox">Xbox</MenuItem>
                      <MenuItem value="PSN" aria-label="PlayStation/PSN">PlayStation/PSN</MenuItem>
                      <MenuItem value="PC" aria-label="Steam/PC">Steam/PC</MenuItem>
                    </Select>
                  </FormControl>
                  
                  <FormControl fullWidth>
                    <InputLabel id="timezone-select-label">Timezone (Optional)</InputLabel>
                    <Select
                      value={formData.timezone}
                      onChange={handleChange('timezone')}
                      label="Timezone (Optional)"
                      labelId="timezone-select-label"
                      aria-labelledby="timezone-select-label"
                    >
                      {COMMON_TIMEZONES.map((tz) => (
                        <MenuItem key={tz.value} value={tz.value} aria-label={tz.label}>
                          {tz.label}
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                  
                  <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2 }}>
                    <Box sx={{ display: 'flex', gap: 1 }}>
                      <TextField
                        required
                        id="heightFeet"
                        label="Height (Feet)"
                        name="heightFeet"
                        type="number"
                        value={formData.heightFeet}
                        onChange={handleChange('heightFeet')}
                        placeholder="5"
                        inputProps={{ min: 3, max: 8 }}
                        sx={{ flex: 1 }}
                      />
                      <TextField
                        required
                        id="heightInches"
                        label="Inches"
                        name="heightInches"
                        type="number"
                        value={formData.heightInches}
                        onChange={handleChange('heightInches')}
                        placeholder="10"
                        inputProps={{ min: 0, max: 11 }}
                        sx={{ flex: 1 }}
                      />
                    </Box>
                    
                    <TextField
                      required
                      fullWidth
                      id="reach"
                      label="Reach (Inches)"
                      name="reach"
                      type="number"
                      value={formData.reach || ''}
                      onChange={handleChange('reach')}
                      placeholder="72"
                      inputProps={{ min: 50, max: 100 }}
                      error={!formData.reach || formData.reach.toString().trim() === '' || isNaN(parseInt(formData.reach.toString())) || parseInt(formData.reach.toString()) <= 0}
                      helperText={(!formData.reach || formData.reach.toString().trim() === '') ? 'Reach is required' : ''}
                    />
                  </Box>
                  
                  <TextField
                    required
                    fullWidth
                    id="weight"
                    label="Weight (Pounds/LBS)"
                    name="weight"
                    type="number"
                    value={formData.weight}
                    onChange={handleChange('weight')}
                    placeholder="150"
                    inputProps={{ min: 80, max: 400 }}
                  />
                  
                  <FormControl fullWidth required>
                    <InputLabel>Weight Class (Original)</InputLabel>
                    <Select
                      value={formData.weightClass}
                      onChange={handleChange('weightClass')}
                      label="Weight Class (Original)"
                    >
                      {WEIGHT_CLASS_ORDER.map((wc) => (
                        <MenuItem key={wc} value={wc}>
                          {wc}
                        </MenuItem>
                      ))}
                    </Select>
                    <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5, display: 'block' }}>
                      This will be your original weight class. You can move up to 3 classes up or down later.
                    </Typography>
                  </FormControl>
                  
                  <TextField
                    required
                    fullWidth
                    id="trainer"
                    label="Trainer"
                    name="trainer"
                    value={formData.trainer}
                    onChange={handleChange('trainer')}
                    placeholder="Your coach or trainer's name"
                  />
                  
                  <TextField
                    required
                    fullWidth
                    id="gym"
                    label="Gym/Team"
                    name="gym"
                    value={formData.gym}
                    onChange={handleChange('gym')}
                    placeholder="Your gym or team name"
                  />
                </Box>
              </CardContent>
            </Card>
          </Box>
        );

      default:
        return 'Unknown step';
    }
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        width: '100vw',
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        overflow: 'hidden',
        margin: 0,
        padding: 0
      }}
    >
      {/* Background Image */}
      <Box
        sx={{
          position: 'absolute',
          top: 0,
          left: 0,
          width: '100vw',
          height: '100vh',
          backgroundImage: `url(${backgroundImage})`,
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          backgroundRepeat: 'no-repeat',
          zIndex: -1,
        }}
      />
      
      {/* Overlay */}
      <Box
        sx={{
          position: 'absolute',
          top: 0,
          left: 0,
          width: '100vw',
          height: '100vh',
          backgroundColor: 'rgba(0, 0, 0, 0.4)',
          zIndex: 0,
          margin: 0,
          padding: 0
        }}
      />
      
      <Container 
        component="main" 
        maxWidth="md" 
        sx={{ 
          position: 'relative', 
          zIndex: 1, 
          py: 4,
          width: '100%',
          height: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center'
        }}
      >
        <Box
          sx={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            width: '100%',
            maxHeight: '100vh',
            overflow: 'auto'
          }}
        >
        <Paper
          elevation={8}
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
          <Avatar sx={{ m: 1, bgcolor: 'primary.main', width: 56, height: 56 }}>
            <SportsMma />
          </Avatar>
          
          <Typography component="h1" variant="h4" gutterBottom>
            Join Tantalus Boxing Club
          </Typography>
          
          <Typography variant="h6" color="text.secondary" gutterBottom>
            Create Your Fighter Profile
          </Typography>

          <Stepper activeStep={activeStep} sx={{ mt: 3, mb: 3, width: '100%' }}>
            {steps.map((label) => (
              <Step key={label}>
                <StepLabel>{label}</StepLabel>
              </Step>
            ))}
          </Stepper>

          {renderStepContent(activeStep)}

          <Box sx={{ display: 'flex', flexDirection: 'row', pt: 2, width: '100%' }}>
            <Button
              color="inherit"
              disabled={activeStep === 0}
              onClick={handleBack}
              sx={{ mr: 1 }}
            >
              Back
            </Button>
            <Box sx={{ flex: '1 1 auto' }} />
            {activeStep === steps.length - 1 ? (
              <Button
                onClick={(e) => handleSubmit(e)}
                type="button"
                variant="contained"
                disabled={loading}
                startIcon={<PersonAdd />}
              >
                {loading ? 'Creating Account...' : 'Create Fighter Profile'}
              </Button>
            ) : (
              <Button
                onClick={() => {
                  if (validateStep1()) {
                    handleNext();
                  }
                }}
                variant="contained"
              >
                Next
              </Button>
            )}
          </Box>
          
                  <Box textAlign="center" sx={{ mt: 2 }}>
                    <Link
                      component="button"
                      variant="body2"
                      onClick={() => navigate('/login')}
                      sx={{ textDecoration: 'none' }}
                    >
                      Already have an account? Sign In
                    </Link>
                  </Box>
        </Paper>
        </Box>
      </Container>
    </Box>
  );
};

export default RegisterPage;