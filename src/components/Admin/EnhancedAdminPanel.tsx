import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Grid,
  Alert,
  CircularProgress
} from '@mui/material';
import {
  Edit as EditIcon,
  Delete as DeleteIcon,
  Add as AddIcon,
  Person as PersonIcon,
  Settings as SettingsIcon,
  Security as SecurityIcon
} from '@mui/icons-material';
import { AdminService, AdminUser } from '../../services/adminService';
// Import Logo1.png
import logo1 from '../../Logo1.png';


interface SystemSettings {
  maintenance_mode: boolean;
  registration_enabled: boolean;
  max_users: number;
  notification_retention_days: number;
}

const EnhancedAdminPanel: React.FC = () => {
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [systemSettings, setSystemSettings] = useState<SystemSettings>({
    maintenance_mode: false,
    registration_enabled: true,
    max_users: 1000,
    notification_retention_days: 30
  });
  const [loading, setLoading] = useState(true);
  const [selectedUser, setSelectedUser] = useState<AdminUser | null>(null);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [settingsDialogOpen, setSettingsDialogOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadUsers();
    loadSystemSettings();
  }, []);

  const loadUsers = async () => {
    try {
      setLoading(true);
      setError(null);
      const allUsers = await AdminService.getAllUsers();
      setUsers(allUsers);
    } catch (error: any) {
      console.error('Error loading users:', error);
      setError(error.message || 'Failed to load users');
    } finally {
      setLoading(false);
    }
  };

  const loadSystemSettings = async () => {
    try {
      // System settings would typically come from a settings table or config
      // For now, keeping default values as they would be stored in database
      // TODO: Implement settings table in database
      setSystemSettings({
        maintenance_mode: false,
        registration_enabled: true,
        max_users: 1000,
        notification_retention_days: 30
      });
    } catch (error) {
      console.error('Error loading system settings:', error);
    }
  };

  const handleEditUser = (user: AdminUser) => {
    setSelectedUser(user);
    setEditDialogOpen(true);
  };

  const handleDeleteUser = async (userId: string) => {
    if (window.confirm('Are you sure you want to delete this user? This action cannot be undone.')) {
      try {
        await AdminService.deleteUser(userId);
        loadUsers(); // Reload users
      } catch (error: any) {
        console.error('Error deleting user:', error);
        alert(`Failed to delete user: ${error.message}`);
      }
    }
  };

  const handleSaveUser = async () => {
    if (!selectedUser) return;
    
    try {
      // Update user role if changed
      if (selectedUser.role) {
        await AdminService.updateUserRole(selectedUser.id, selectedUser.role as 'admin' | 'fighter' | 'user');
      }
      setEditDialogOpen(false);
      loadUsers(); // Reload users
    } catch (error: any) {
      console.error('Error saving user:', error);
      alert(`Failed to save user: ${error.message}`);
    }
  };

  const handleSaveSettings = async () => {
    try {
      // Implement save settings logic
      console.log('Saving settings:', systemSettings);
      setSettingsDialogOpen(false);
    } catch (error) {
      console.error('Error saving settings:', error);
    }
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box display="flex" alignItems="center" gap={2} mb={3}>
        <Box
          component="img"
          src={logo1}
          alt="Tantalus Boxing League Logo"
          sx={{
            height: { xs: 50, md: 70 },
            width: 'auto',
            objectFit: 'contain',
          }}
        />
        <Typography variant="h4" gutterBottom sx={{ mb: 0 }}>
          Enhanced Admin Panel
        </Typography>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* System Status Cards */}
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(3, 1fr)' }, gap: 2, mb: 3 }}>
        <Card>
          <CardContent>
            <Box display="flex" alignItems="center" justifyContent="space-between">
              <Box>
                <Typography color="textSecondary" gutterBottom>
                  Total Users
                </Typography>
                <Typography variant="h4">
                  {users.length}
                </Typography>
              </Box>
              <PersonIcon color="primary" sx={{ fontSize: 40 }} />
            </Box>
          </CardContent>
        </Card>

        <Card>
          <CardContent>
            <Box display="flex" alignItems="center" justifyContent="space-between">
              <Box>
                <Typography color="textSecondary" gutterBottom>
                  System Status
                </Typography>
                <Typography variant="h6">
                  {systemSettings.maintenance_mode ? 'Maintenance' : 'Operational'}
                </Typography>
              </Box>
              <SettingsIcon color={systemSettings.maintenance_mode ? 'error' : 'success'} sx={{ fontSize: 40 }} />
            </Box>
          </CardContent>
        </Card>

        <Card>
          <CardContent>
            <Box display="flex" alignItems="center" justifyContent="space-between">
              <Box>
                <Typography color="textSecondary" gutterBottom>
                  Security Level
                </Typography>
                <Typography variant="h6">
                  High
                </Typography>
              </Box>
              <SecurityIcon color="success" sx={{ fontSize: 40 }} />
            </Box>
          </CardContent>
        </Card>
      </Box>

      {/* User Management */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
            <Typography variant="h6">
              User Management
            </Typography>
            <Button
              variant="contained"
              startIcon={<AddIcon />}
              onClick={() => setEditDialogOpen(true)}
            >
              Add User
            </Button>
          </Box>

          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Name</TableCell>
                  <TableCell>Email</TableCell>
                  <TableCell>Role</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Created</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {users.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} align="center">
                      <Typography color="textSecondary">No users found</Typography>
                    </TableCell>
                  </TableRow>
                ) : (
                  users.map((user) => (
                    <TableRow key={user.id}>
                      <TableCell>{user.fighter_profile?.name || user.email}</TableCell>
                      <TableCell>{user.email}</TableCell>
                      <TableCell>
                        <Chip
                          label={user.role}
                          color={user.role === 'admin' ? 'error' : 'primary'}
                          size="small"
                        />
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={user.status}
                          color={user.status === 'active' ? 'success' : user.status === 'banned' ? 'error' : 'default'}
                          size="small"
                        />
                      </TableCell>
                      <TableCell>{new Date(user.created_at).toLocaleDateString()}</TableCell>
                      <TableCell>
                        <IconButton
                          size="small"
                          onClick={() => handleEditUser(user)}
                        >
                          <EditIcon />
                        </IconButton>
                        <IconButton
                          size="small"
                          onClick={() => handleDeleteUser(user.id)}
                          disabled={user.role === 'admin'}
                        >
                          <DeleteIcon />
                        </IconButton>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* System Settings */}
      <Card>
        <CardContent>
          <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
            <Typography variant="h6">
              System Settings
            </Typography>
            <Button
              variant="outlined"
              startIcon={<SettingsIcon />}
              onClick={() => setSettingsDialogOpen(true)}
            >
              Configure
            </Button>
          </Box>

          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(2, 1fr)' }, gap: 2 }}>
            <Box>
              <Typography variant="body2" color="textSecondary">
                Maintenance Mode
              </Typography>
              <Typography variant="body1">
                {systemSettings.maintenance_mode ? 'Enabled' : 'Disabled'}
              </Typography>
            </Box>
            <Box>
              <Typography variant="body2" color="textSecondary">
                Registration
              </Typography>
              <Typography variant="body1">
                {systemSettings.registration_enabled ? 'Enabled' : 'Disabled'}
              </Typography>
            </Box>
            <Box>
              <Typography variant="body2" color="textSecondary">
                Max Users
              </Typography>
              <Typography variant="body1">
                {systemSettings.max_users.toLocaleString()}
              </Typography>
            </Box>
            <Box>
              <Typography variant="body2" color="textSecondary">
                Notification Retention
              </Typography>
              <Typography variant="body1">
                {systemSettings.notification_retention_days} days
              </Typography>
            </Box>
          </Box>
        </CardContent>
      </Card>

      {/* Edit User Dialog */}
      <Dialog 
        open={editDialogOpen} 
        onClose={() => setEditDialogOpen(false)} 
        maxWidth="sm" 
        fullWidth
        aria-labelledby="edit-user-dialog-title"
        keepMounted={false}
        disableEnforceFocus={false}
        disableAutoFocus={false}
      >
        <DialogTitle id="edit-user-dialog-title">
          {selectedUser ? 'Edit User' : 'Add User'}
        </DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 1 }}>
            <TextField
              fullWidth
              label="Fighter Name"
              value={selectedUser?.fighter_profile?.name || 'No fighter profile'}
              margin="normal"
              disabled
              helperText="Fighter name is managed through the fighter profile"
            />
            <TextField
              fullWidth
              label="Email"
              value={selectedUser?.email || ''}
              onChange={(e) => setSelectedUser({ ...selectedUser!, email: e.target.value })}
              margin="normal"
              disabled
              helperText="Email cannot be changed here"
            />
            <FormControl fullWidth margin="normal">
              <InputLabel id="user-role-label">Role</InputLabel>
              <Select
                value={selectedUser?.role || ''}
                onChange={(e) => setSelectedUser({ ...selectedUser!, role: e.target.value })}
                label="Role"
                labelId="user-role-label"
                aria-labelledby="user-role-label"
              >
                <MenuItem value="admin">Admin</MenuItem>
                <MenuItem value="fighter">Fighter</MenuItem>
                <MenuItem value="spectator">Spectator</MenuItem>
              </Select>
            </FormControl>
            <FormControl fullWidth margin="normal">
              <InputLabel>Status</InputLabel>
              <Select
                value={selectedUser?.status || ''}
                onChange={(e) => setSelectedUser({ ...selectedUser!, status: e.target.value as 'active' | 'inactive' | 'banned' })}
              >
                <MenuItem value="active">Active</MenuItem>
                <MenuItem value="inactive">Inactive</MenuItem>
                <MenuItem value="banned">Banned</MenuItem>
              </Select>
            </FormControl>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditDialogOpen(false)}>
            Cancel
          </Button>
          <Button onClick={handleSaveUser} variant="contained">
            Save
          </Button>
        </DialogActions>
      </Dialog>

      {/* System Settings Dialog */}
      <Dialog 
        open={settingsDialogOpen} 
        onClose={() => setSettingsDialogOpen(false)} 
        maxWidth="sm" 
        fullWidth
        aria-labelledby="settings-dialog-title"
        keepMounted={false}
        disableEnforceFocus={false}
        disableAutoFocus={false}
      >
        <DialogTitle id="settings-dialog-title">
          System Settings
        </DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 1 }}>
            <FormControl fullWidth margin="normal">
              <InputLabel>Maintenance Mode</InputLabel>
              <Select
                value={systemSettings.maintenance_mode}
                onChange={(e) => setSystemSettings({ ...systemSettings, maintenance_mode: e.target.value === 'true' })}
              >
                <MenuItem value="false">Disabled</MenuItem>
                <MenuItem value="true">Enabled</MenuItem>
              </Select>
            </FormControl>
            <FormControl fullWidth margin="normal">
              <InputLabel>Registration</InputLabel>
              <Select
                value={systemSettings.registration_enabled}
                onChange={(e) => setSystemSettings({ ...systemSettings, registration_enabled: e.target.value === 'true' })}
              >
                <MenuItem value="true">Enabled</MenuItem>
                <MenuItem value="false">Disabled</MenuItem>
              </Select>
            </FormControl>
            <TextField
              fullWidth
              label="Max Users"
              type="number"
              value={systemSettings.max_users}
              onChange={(e) => setSystemSettings({ ...systemSettings, max_users: parseInt(e.target.value) })}
              margin="normal"
            />
            <TextField
              fullWidth
              label="Notification Retention (Days)"
              type="number"
              value={systemSettings.notification_retention_days}
              onChange={(e) => setSystemSettings({ ...systemSettings, notification_retention_days: parseInt(e.target.value) })}
              margin="normal"
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSettingsDialogOpen(false)}>
            Cancel
          </Button>
          <Button onClick={handleSaveSettings} variant="contained">
            Save
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default EnhancedAdminPanel;