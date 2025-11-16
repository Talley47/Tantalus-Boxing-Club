import React, { useState } from 'react';
import {
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Typography,
  Box,
  Avatar,
  Divider,
  IconButton,
  Tooltip,
  Badge,
} from '@mui/material';
import {
  Home,
  Person,
  EmojiEvents,
  SportsMma,
  Schedule,
  Sports,
  Analytics,
  AdminPanelSettings,
  Logout,
  Menu,
  Notifications,
  Forum,
  Gavel,
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';

const drawerWidth = 240;

const Navigation: React.FC = () => {
  const [mobileOpen, setMobileOpen] = useState(false);
  const { fighterProfile, signOut, isAdmin } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const handleSignOut = async () => {
    try {
      await signOut();
      // Always redirect to login, even if signOut had issues
      // The signOut function handles clearing local state defensively
      navigate('/login');
    } catch (error: any) {
      // Don't log session missing errors - they're harmless (user already logged out)
      const isSessionMissing = 
        error?.message?.includes('Auth session missing') || 
        error?.name === 'AuthSessionMissingError' ||
        error?.message?.includes('session missing') ||
        error?.toString()?.includes('Auth session missing') ||
        error?.toString()?.includes('AuthSessionMissingError');
      
      if (!isSessionMissing) {
        console.warn('Sign out error (redirecting anyway):', error);
      }
      // Always redirect to login regardless of errors (defensive UI)
      navigate('/login');
    }
  };

  const menuItems = [
    { text: 'Home', icon: <Home />, path: '/' },
    { text: 'My Profile', icon: <Person />, path: '/profile' },
    { text: 'Rankings', icon: <EmojiEvents />, path: '/rankings' },
    { text: 'Matchmaking', icon: <SportsMma />, path: '/matchmaking' },
    { text: 'Scheduling', icon: <Schedule />, path: '/scheduling' },
    { text: 'Tournaments', icon: <Sports />, path: '/tournaments' },
    { text: 'Analytics', icon: <Analytics />, path: '/analytics' },
    { text: 'Social', icon: <Forum />, path: '/social' },
    { text: 'Rules/Guidelines', icon: <Gavel />, path: '/rules' },
  ];

  // Debug: Log menu items to verify Rules/Guidelines is included
  React.useEffect(() => {
    console.log('Navigation menu items:', menuItems.map(item => item.text));
    const rulesItem = menuItems.find(item => item.path === '/rules');
    console.log('Rules/Guidelines menu item:', rulesItem ? 'FOUND' : 'NOT FOUND', rulesItem);
  }, []);

  if (isAdmin) {
    menuItems.push({ text: 'Admin Panel', icon: <AdminPanelSettings />, path: '/admin' });
  }

  const drawer = (
    <Box>
      <Box sx={{ p: 2, textAlign: 'center' }}>
        <Typography variant="h6" noWrap component="div" color="primary">
          Tantalus Boxing
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Virtual League
        </Typography>
      </Box>
      
      <Divider />
      
      {fighterProfile && (
        <Box sx={{ p: 2 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
            <Avatar
              src={fighterProfile.profile_photo_url}
              sx={{ width: 40, height: 40, mr: 2 }}
            >
              {fighterProfile.name.charAt(0)}
            </Avatar>
            <Box>
              <Typography variant="subtitle2" noWrap>
                {fighterProfile.name}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                {fighterProfile.tier} • {fighterProfile.points} pts
              </Typography>
            </Box>
          </Box>
        </Box>
      )}
      
      <Divider />
      
      <List>
        {menuItems.map((item) => (
          <ListItem key={item.text} disablePadding>
            <ListItemButton
              selected={location.pathname === item.path}
              onClick={() => {
                // If already on the same route, force a refresh by using replace
                if (location.pathname === item.path) {
                  // Force scroll to top and trigger a refresh
                  window.scrollTo(0, 0);
                  navigate(item.path, { replace: true });
                } else {
                  navigate(item.path);
                }
                setMobileOpen(false);
              }}
            >
              <ListItemIcon>
                {item.icon}
              </ListItemIcon>
              <ListItemText primary={item.text} />
            </ListItemButton>
          </ListItem>
        ))}
      </List>
      
      <Divider />
      
      <List>
        <ListItem disablePadding>
          <ListItemButton onClick={handleSignOut}>
            <ListItemIcon>
              <Logout />
            </ListItemIcon>
            <ListItemText primary="Sign Out" />
          </ListItemButton>
        </ListItem>
      </List>
    </Box>
  );

  return (
    <Box sx={{ display: 'flex' }}>
      <Box
        component="nav"
        sx={{ width: { sm: drawerWidth }, flexShrink: { sm: 0 } }}
      >
        <Drawer
          variant="temporary"
          open={mobileOpen}
          onClose={handleDrawerToggle}
          ModalProps={{
            keepMounted: true, // Better open performance on mobile.
          }}
          sx={{
            display: { xs: 'block', sm: 'none' },
            '& .MuiDrawer-paper': { boxSizing: 'border-box', width: drawerWidth },
          }}
        >
          {drawer}
        </Drawer>
        <Drawer
          variant="permanent"
          sx={{
            display: { xs: 'none', sm: 'block' },
            '& .MuiDrawer-paper': { boxSizing: 'border-box', width: drawerWidth },
          }}
          open
        >
          {drawer}
        </Drawer>
      </Box>
    </Box>
  );
};

export default Navigation;

