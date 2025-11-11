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
  Alert,
  Snackbar,
  Tooltip,
  CircularProgress,
} from '@mui/material';
import {
  People,
  Edit,
  Delete,
  Block,
  LockOpen,
  Search,
  FilterList,
  LockReset,
  Email,
} from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';
import { AdminService, AdminUser } from '../../services/adminService';

const UserManagement: React.FC = () => {
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterRole, setFilterRole] = useState('all');
  const [filterStatus, setFilterStatus] = useState('all');
  const [selectedUser, setSelectedUser] = useState<AdminUser | null>(null);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [banDialogOpen, setBanDialogOpen] = useState(false);
  const [resetPasswordDialogOpen, setResetPasswordDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [banDuration, setBanDuration] = useState('7');
  const [banReason, setBanReason] = useState('');
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' | 'warning' });
  const [editForm, setEditForm] = useState({
    email: '',
    role: '',
  });

  const { user } = useAuth();

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    try {
      setLoading(true);
      console.log('[UserManagement] Loading users...');
      const allUsers = await AdminService.getAllUsers();
      console.log('[UserManagement] Loaded', allUsers.length, 'users');
      setUsers(allUsers);
      
      if (allUsers.length === 0) {
        setSnackbar({ 
          open: true, 
          message: 'No users found. Make sure the profiles table exists and has data.', 
          severity: 'warning' 
        });
      }
    } catch (error: any) {
      console.error('[UserManagement] Error loading users:', error);
      setSnackbar({ 
        open: true, 
        message: `Error loading users: ${error.message || 'Unknown error'}. Check browser console for details.`, 
        severity: 'error' 
      });
    } finally {
      setLoading(false);
    }
  };

  const handleEditUser = (user: AdminUser) => {
    setSelectedUser(user);
    setEditForm({
      email: user.email,
      role: user.role,
    });
    setEditDialogOpen(true);
  };

  const handleSaveUser = async () => {
    if (!selectedUser) return;

    try {
      // Update role if changed
      if (editForm.role !== selectedUser.role) {
        await AdminService.updateUserRole(selectedUser.id, editForm.role as 'admin' | 'fighter' | 'user');
      }

      await loadUsers();
      setEditDialogOpen(false);
      setSnackbar({ open: true, message: 'User updated successfully', severity: 'success' });
    } catch (error: any) {
      setSnackbar({ 
        open: true, 
        message: `Error updating user: ${error.message || 'Unknown error'}`, 
        severity: 'error' 
      });
    }
  };

  const handleBanUser = (user: AdminUser) => {
    setSelectedUser(user);
    setBanReason('');
    setBanDialogOpen(true);
  };

  const handleConfirmBan = async () => {
    if (!selectedUser) return;

    try {
      const duration = banDuration === 'permanent' 
        ? undefined 
        : parseInt(banDuration);
      
      await AdminService.banUser(selectedUser.id, duration, banReason);
      await loadUsers();
      setBanDialogOpen(false);
      setSnackbar({ open: true, message: 'User banned successfully', severity: 'success' });
    } catch (error: any) {
      setSnackbar({ 
        open: true, 
        message: `Error banning user: ${error.message || 'Unknown error'}`, 
        severity: 'error' 
      });
    }
  };

  const handleUnbanUser = async (userId: string) => {
    try {
      await AdminService.unbanUser(userId);
      await loadUsers();
      setSnackbar({ open: true, message: 'User unbanned successfully', severity: 'success' });
    } catch (error: any) {
      setSnackbar({ 
        open: true, 
        message: `Error unbanning user: ${error.message || 'Unknown error'}`, 
        severity: 'error' 
      });
    }
  };

  const handleResetPassword = async (userEmail: string) => {
    try {
      await AdminService.sendPasswordResetEmail(userEmail);
      setResetPasswordDialogOpen(false);
      setSnackbar({ 
        open: true, 
        message: 'Password reset email sent successfully', 
        severity: 'success' 
      });
    } catch (error: any) {
      setSnackbar({ 
        open: true, 
        message: `Error resetting password: ${error.message || 'Unknown error'}`, 
        severity: 'error' 
      });
    }
  };

  const handleDeleteUser = (user: AdminUser) => {
    setSelectedUser(user);
    setDeleteDialogOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!selectedUser) return;

    try {
      await AdminService.deleteUser(selectedUser.id);
      await loadUsers();
      setDeleteDialogOpen(false);
      setSnackbar({ open: true, message: 'User deleted successfully', severity: 'success' });
    } catch (error: any) {
      setSnackbar({ 
        open: true, 
        message: `Error deleting user: ${error.message || 'Unknown error'}. Note: User deletion from auth requires server-side admin API.`, 
        severity: 'error' 
      });
    }
  };

  const filteredUsers = users.filter(user => {
    const matchesSearch = user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         (user.username && user.username.toLowerCase().includes(searchTerm.toLowerCase())) ||
                         (user.fighter_profile?.name && user.fighter_profile.name.toLowerCase().includes(searchTerm.toLowerCase()));
    const matchesRole = filterRole === 'all' || user.role === filterRole;
    const matchesStatus = filterStatus === 'all' || user.status === filterStatus;
    return matchesSearch && matchesRole && matchesStatus;
  });

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
        <Box>
          <Typography variant="h4" gutterBottom>
            User Management
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Manage user accounts, roles, and permissions.
          </Typography>
        </Box>
        <Button
          variant="outlined"
          onClick={loadUsers}
          disabled={loading}
          startIcon={loading ? <CircularProgress size={20} /> : undefined}
        >
          Refresh
        </Button>
      </Box>

      {/* Search and Filter */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Box display="flex" gap={2} alignItems="center">
            <TextField
              placeholder="Search users..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              InputProps={{
                startAdornment: <Search sx={{ mr: 1, color: 'text.secondary' }} />,
              }}
              sx={{ flexGrow: 1 }}
            />
            <FormControl sx={{ minWidth: 120 }}>
              <InputLabel>Role</InputLabel>
              <Select
                value={filterRole}
                onChange={(e) => setFilterRole(e.target.value)}
              >
                <MenuItem value="all">All Roles</MenuItem>
                <MenuItem value="fighter">Fighter</MenuItem>
                <MenuItem value="admin">Admin</MenuItem>
                <MenuItem value="user">User</MenuItem>
              </Select>
            </FormControl>
            <FormControl sx={{ minWidth: 120 }}>
              <InputLabel>Status</InputLabel>
              <Select
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
              >
                <MenuItem value="all">All Status</MenuItem>
                <MenuItem value="active">Active</MenuItem>
                <MenuItem value="inactive">Inactive</MenuItem>
                <MenuItem value="banned">Banned</MenuItem>
              </Select>
            </FormControl>
          </Box>
        </CardContent>
      </Card>

      {/* Users Table */}
      <Card>
        <CardContent>
          {loading ? (
            <Box display="flex" justifyContent="center" p={4}>
              <CircularProgress />
            </Box>
          ) : filteredUsers.length === 0 ? (
            <Alert severity="info">No users found</Alert>
          ) : (
            <TableContainer component={Paper}>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell><strong>Username</strong></TableCell>
                    <TableCell><strong>Email Address</strong></TableCell>
                    <TableCell><strong>Password</strong></TableCell>
                    <TableCell><strong>Status</strong></TableCell>
                    <TableCell><strong>Role</strong></TableCell>
                    <TableCell><strong>Created</strong></TableCell>
                    <TableCell><strong>Last Login</strong></TableCell>
                    <TableCell><strong>Actions</strong></TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {filteredUsers.map((user) => (
                    <TableRow key={user.id}>
                      <TableCell>
                        <Typography variant="body2" fontWeight="medium">
                          {user.username || user.email || 'N/A'}
                        </Typography>
                        {user.fighter_profile && (
                          <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                            {user.fighter_profile.name}
                          </Typography>
                        )}
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2">
                          {user.email || 'No email'}
                        </Typography>
                        <Typography variant="caption" color="text.secondary" sx={{ display: 'block', fontFamily: 'monospace', fontSize: '0.7rem' }}>
                          ID: {user.id.substring(0, 8)}...
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Tooltip title="Passwords are encrypted and cannot be displayed. Click Reset Password to send reset email.">
                          <Box>
                            <Chip 
                              label="••••••••" 
                              size="small" 
                              variant="outlined"
                              sx={{ fontFamily: 'monospace', letterSpacing: '2px' }}
                            />
                            <Button
                              size="small"
                              variant="text"
                              color="primary"
                              startIcon={<LockReset />}
                              onClick={() => {
                                setSelectedUser(user);
                                setResetPasswordDialogOpen(true);
                              }}
                              sx={{ mt: 0.5, textTransform: 'none', fontSize: '0.7rem' }}
                            >
                              Reset
                            </Button>
                          </Box>
                        </Tooltip>
                      </TableCell>
                      <TableCell>
                        {user.status === 'banned' ? (
                          <Chip label="Banned" size="small" color="error" />
                        ) : user.status === 'inactive' ? (
                          <Chip label="Inactive" size="small" color="warning" />
                        ) : (
                          <Chip label="Active" size="small" color="success" />
                        )}
                        {user.banned_until && (
                          <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 0.5, fontSize: '0.7rem' }}>
                            Until: {new Date(user.banned_until).toLocaleDateString()}
                          </Typography>
                        )}
                      </TableCell>
                      <TableCell>
                        <Chip 
                          label={user.role || 'user'} 
                          size="small" 
                          color={user.role === 'admin' ? 'error' : user.role === 'fighter' ? 'primary' : 'default'} 
                        />
                      </TableCell>
                      <TableCell>
                        {new Date(user.created_at).toLocaleDateString()}
                      </TableCell>
                      <TableCell>
                        {user.last_sign_in_at 
                          ? new Date(user.last_sign_in_at).toLocaleDateString()
                          : 'Never'}
                      </TableCell>
                      <TableCell>
                        <Box display="flex" gap={0.5}>
                          <Tooltip title="Edit User">
                            <IconButton
                              size="small"
                              onClick={() => handleEditUser(user)}
                            >
                              <Edit />
                            </IconButton>
                          </Tooltip>
                          <Tooltip title="Reset Password">
                            <IconButton
                              size="small"
                              onClick={() => {
                                setSelectedUser(user);
                                setResetPasswordDialogOpen(true);
                              }}
                              color="info"
                            >
                              <LockReset />
                            </IconButton>
                          </Tooltip>
                          {user.status === 'banned' ? (
                            <Tooltip title="Unban User">
                              <IconButton
                                size="small"
                                onClick={() => handleUnbanUser(user.id)}
                                color="success"
                              >
                                <LockOpen />
                              </IconButton>
                            </Tooltip>
                          ) : (
                            <Tooltip title="Ban User">
                              <IconButton
                                size="small"
                                onClick={() => handleBanUser(user)}
                                color="error"
                              >
                                <Block />
                              </IconButton>
                            </Tooltip>
                          )}
                          <Tooltip title="Delete User">
                            <IconButton
                              size="small"
                              onClick={() => handleDeleteUser(user)}
                              color="error"
                            >
                              <Delete />
                            </IconButton>
                          </Tooltip>
                        </Box>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </CardContent>
      </Card>

      {/* Edit User Dialog - Add/Edit Roles */}
      <Dialog 
        open={editDialogOpen} 
        onClose={() => setEditDialogOpen(false)} 
        maxWidth="sm" 
        fullWidth
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
        keepMounted={false}
      >
        <DialogTitle>Edit User Role</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 2 }}>
            <Alert severity="info">
              <Typography variant="body2" fontWeight="bold">
                User: {selectedUser?.email || selectedUser?.username || 'Unknown'}
              </Typography>
              <Typography variant="caption">
                Username: {selectedUser?.username || selectedUser?.email || 'N/A'}
              </Typography>
            </Alert>
            <TextField
              fullWidth
              label="Email Address"
              value={editForm.email}
              disabled
              helperText="Email address cannot be changed"
            />
            <FormControl fullWidth required>
              <InputLabel id="user-role-select-label">User Role</InputLabel>
              <Select
                value={editForm.role}
                onChange={(e) => setEditForm({ ...editForm, role: e.target.value })}
                label="User Role"
                labelId="user-role-select-label"
                aria-labelledby="user-role-select-label"
              >
                <MenuItem value="fighter">Fighter</MenuItem>
                <MenuItem value="admin">Admin</MenuItem>
                <MenuItem value="user">User</MenuItem>
              </Select>
            </FormControl>
            <Alert severity="warning" sx={{ mt: 1 }}>
              <Typography variant="body2" fontWeight="bold">
                Role Permissions:
              </Typography>
              <Typography variant="caption" component="div">
                <strong>Admin:</strong> Full system access, can manage all users and settings<br />
                <strong>Fighter:</strong> Can participate in matches, tournaments, and manage their profile<br />
                <strong>User:</strong> Basic account access only
              </Typography>
            </Alert>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleSaveUser} variant="contained" color="primary">
            Update Role
          </Button>
        </DialogActions>
      </Dialog>

      {/* Ban User Dialog */}
      <Dialog 
        open={banDialogOpen} 
        onClose={() => setBanDialogOpen(false)}
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
        keepMounted={false}
      >
        <DialogTitle>Ban User</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 2 }}>
            <Alert severity="warning">
              Banning user: <strong>{selectedUser?.email}</strong>
            </Alert>
            <FormControl fullWidth required>
              <InputLabel>Ban Duration</InputLabel>
              <Select
                value={banDuration}
                onChange={(e) => setBanDuration(e.target.value)}
              >
                <MenuItem value="1">1 Day</MenuItem>
                <MenuItem value="7">1 Week</MenuItem>
                <MenuItem value="30">1 Month</MenuItem>
                <MenuItem value="90">3 Months</MenuItem>
                <MenuItem value="365">1 Year</MenuItem>
                <MenuItem value="permanent">Permanent</MenuItem>
              </Select>
            </FormControl>
            <TextField
              fullWidth
              label="Reason (Optional)"
              multiline
              rows={3}
              value={banReason}
              onChange={(e) => setBanReason(e.target.value)}
              placeholder="Enter reason for banning this user..."
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setBanDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleConfirmBan} color="error" variant="contained">
            Ban User
          </Button>
        </DialogActions>
      </Dialog>

      {/* Reset Password Dialog */}
      <Dialog 
        open={resetPasswordDialogOpen} 
        onClose={() => setResetPasswordDialogOpen(false)}
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
        keepMounted={false}
      >
        <DialogTitle>Reset User Password</DialogTitle>
        <DialogContent>
          <Box sx={{ mt: 2 }}>
            <Alert severity="info" sx={{ mb: 2 }}>
              A password reset email will be sent to: <strong>{selectedUser?.email}</strong>
            </Alert>
            <Typography variant="body2" color="text.secondary">
              The user will receive an email with instructions to reset their password.
              They will be able to set a new password through the email link.
            </Typography>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setResetPasswordDialogOpen(false)}>Cancel</Button>
          <Button 
            onClick={() => selectedUser && handleResetPassword(selectedUser.email)} 
            variant="contained"
            startIcon={<Email />}
          >
            Send Reset Email
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete User Dialog */}
      <Dialog 
        open={deleteDialogOpen} 
        onClose={() => setDeleteDialogOpen(false)}
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
        keepMounted={false}
      >
        <DialogTitle>Delete User Account</DialogTitle>
        <DialogContent>
          <Box sx={{ mt: 2 }}>
            <Alert severity="error" sx={{ mb: 2 }}>
              Warning: This action cannot be undone!
            </Alert>
            <Typography variant="body1" gutterBottom>
              Are you sure you want to delete the account for:
            </Typography>
            <Typography variant="h6" color="error" sx={{ my: 2 }}>
              {selectedUser?.email}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              This will permanently delete:
              <ul>
                <li>User account and authentication</li>
                <li>Fighter profile and all associated data</li>
                <li>Fight records</li>
                <li>All other user data</li>
              </ul>
            </Typography>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleConfirmDelete} color="error" variant="contained">
            Delete Account
          </Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar for notifications */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
      >
        <Alert severity={snackbar.severity} onClose={() => setSnackbar({ ...snackbar, open: false })}>
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default UserManagement;