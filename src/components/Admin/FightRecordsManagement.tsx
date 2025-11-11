import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Box,
  Alert,
  CircularProgress,
  Card,
  CardContent,
  Tabs,
  Tab,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Divider,
} from '@mui/material';
import {
  Refresh as RefreshIcon,
  Warning as WarningIcon,
  Person as PersonIcon,
} from '@mui/icons-material';
import { AdminService, AdminUser } from '../../services/adminService';

interface FightRecordsManagementProps {
  open: boolean;
  onClose: () => void;
}

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;
  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`fight-records-tabpanel-${index}`}
      aria-labelledby={`fight-records-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ pt: 3 }}>{children}</Box>}
    </div>
  );
}

const FightRecordsManagement: React.FC<FightRecordsManagementProps> = ({
  open,
  onClose,
}) => {
  const [activeTab, setActiveTab] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [confirmReset, setConfirmReset] = useState(false);
  const [fighters, setFighters] = useState<AdminUser[]>([]);
  const [selectedFighterId, setSelectedFighterId] = useState<string>('');
  const [selectedFighter, setSelectedFighter] = useState<AdminUser | null>(null);
  const [loadingFighters, setLoadingFighters] = useState(false);

  // Load fighters when dialog opens
  useEffect(() => {
    if (open && activeTab === 1) {
      loadFighters();
    }
  }, [open, activeTab]);

  // Update selected fighter when ID changes
  useEffect(() => {
    if (selectedFighterId && fighters.length > 0) {
      const fighter = fighters.find(f => f.id === selectedFighterId);
      setSelectedFighter(fighter || null);
    } else {
      setSelectedFighter(null);
    }
  }, [selectedFighterId, fighters]);

  const loadFighters = async () => {
    try {
      setLoadingFighters(true);
      const allUsers = await AdminService.getAllUsers();
      // Filter to only show fighters (users with fighter profiles)
      const fightersOnly = allUsers.filter(
        user => user.fighter_profile && user.role !== 'admin'
      );
      setFighters(fightersOnly);
    } catch (err: any) {
      console.error('Error loading fighters:', err);
      setError('Failed to load fighters list');
    } finally {
      setLoadingFighters(false);
    }
  };

  const handleResetAllRecords = async () => {
    if (!confirmReset) {
      setConfirmReset(true);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      setSuccess(false);
      
      await AdminService.resetAllFightersRecords();
      
      setSuccess(true);
      setConfirmReset(false);
      
      // Auto-close after 2 seconds on success
      setTimeout(() => {
        handleClose();
      }, 2000);
    } catch (err: any) {
      console.error('Error resetting fighters records:', err);
      // Show detailed error message
      const errorMessage = err?.message || 
                          err?.error_description || 
                          (typeof err === 'string' ? err : JSON.stringify(err)) || 
                          'Failed to reset fighters records';
      setError(errorMessage);
      setConfirmReset(false);
    } finally {
      setLoading(false);
    }
  };

  const handleResetIndividualRecord = async () => {
    if (!selectedFighterId) {
      setError('Please select a fighter');
      return;
    }

    if (!confirmReset) {
      setConfirmReset(true);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      setSuccess(false);
      
      await AdminService.resetFighterRecords(selectedFighterId);
      
      setSuccess(true);
      setConfirmReset(false);
      setSelectedFighterId('');
      
      // Reload fighters to show updated stats
      await loadFighters();
      
      // Auto-close after 2 seconds on success
      setTimeout(() => {
        handleClose();
      }, 2000);
    } catch (err: any) {
      console.error('Error resetting fighter records:', err);
      // Show detailed error message
      const errorMessage = err?.message || 
                          err?.error_description || 
                          (typeof err === 'string' ? err : JSON.stringify(err)) || 
                          'Failed to reset fighter records';
      setError(errorMessage);
      setConfirmReset(false);
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    setConfirmReset(false);
    setError(null);
    setSuccess(false);
    setSelectedFighterId('');
    setActiveTab(0);
    onClose();
  };

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setActiveTab(newValue);
    setConfirmReset(false);
    setError(null);
    setSuccess(false);
  };

  return (
    <Dialog 
      open={open} 
      onClose={handleClose} 
      maxWidth="md" 
      fullWidth
      aria-labelledby="fight-records-dialog-title"
      keepMounted={false}
      disableEnforceFocus={false}
      disableAutoFocus={false}
      disableRestoreFocus={false}
    >
      <DialogTitle id="fight-records-dialog-title">
        <Box display="flex" alignItems="center" gap={1}>
          <RefreshIcon />
          <Typography variant="h6">Manage Fight Records</Typography>
        </Box>
      </DialogTitle>
      
      <DialogContent>
        <Box sx={{ pt: 2 }}>
          <Tabs value={activeTab} onChange={handleTabChange} sx={{ mb: 2 }}>
            <Tab 
              icon={<RefreshIcon />} 
              iconPosition="start"
              label="Reset All" 
            />
            <Tab 
              icon={<PersonIcon />} 
              iconPosition="start"
              label="Reset Individual" 
            />
          </Tabs>

          <Divider sx={{ mb: 2 }} />

          {/* Reset All Tab */}
          <TabPanel value={activeTab} index={0}>
            {!confirmReset ? (
              <>
                <Alert severity="info" sx={{ mb: 3 }}>
                  <Typography variant="body2">
                    Use this tool to reset all fighter records across the system.
                  </Typography>
                </Alert>

                <Card variant="outlined">
                  <CardContent>
                    <Typography variant="subtitle1" gutterBottom fontWeight="bold">
                      Reset All Fighters Records
                    </Typography>
                    <Typography variant="body2" color="textSecondary" paragraph>
                      This action will reset all fighter records to zero and delete all fight records, including:
                    </Typography>
                    <Box component="ul" sx={{ pl: 2, mb: 0 }}>
                      <Typography component="li" variant="body2" color="textSecondary">
                        Wins, Losses, Draws, Knockouts
                      </Typography>
                      <Typography component="li" variant="body2" color="textSecondary">
                        Points and Tier (reset to Bronze)
                      </Typography>
                      <Typography component="li" variant="body2" color="textSecondary">
                        Win Percentage, KO Percentage
                      </Typography>
                      <Typography component="li" variant="body2" color="textSecondary">
                        Current Streak
                      </Typography>
                      <Typography component="li" variant="body2" color="textSecondary" fontWeight="bold">
                        All Fight Records (permanently deleted)
                      </Typography>
                    </Box>
                    <Alert severity="warning" sx={{ mt: 2 }}>
                      <Typography variant="body2" fontWeight="bold">
                        ⚠️ This action cannot be undone!
                      </Typography>
                    </Alert>
                  </CardContent>
                </Card>
              </>
            ) : (
              <Alert 
                severity="warning" 
                icon={<WarningIcon />}
                sx={{ mb: 3 }}
              >
                <Typography variant="body1" fontWeight="bold" gutterBottom>
                  Are you absolutely sure?
                </Typography>
                <Typography variant="body2">
                  This will reset ALL fighters' records across the entire system and permanently delete ALL fight records. 
                  This action is permanent and cannot be undone.
                </Typography>
              </Alert>
            )}
          </TabPanel>

          {/* Reset Individual Tab */}
          <TabPanel value={activeTab} index={1}>
            {!confirmReset ? (
              <>
                <Alert severity="info" sx={{ mb: 3 }}>
                  <Typography variant="body2">
                    Select a fighter to reset their individual records.
                  </Typography>
                </Alert>

                <Card variant="outlined" sx={{ mb: 2 }}>
                  <CardContent>
                    <Typography variant="subtitle1" gutterBottom fontWeight="bold">
                      Reset Individual Fighter Records
                    </Typography>
                    
                    <FormControl fullWidth sx={{ mt: 2, mb: 2 }}>
                      <InputLabel id="select-fighter-label">Select Fighter</InputLabel>
                      <Select
                        value={selectedFighterId}
                        onChange={(e) => setSelectedFighterId(e.target.value)}
                        label="Select Fighter"
                        labelId="select-fighter-label"
                        disabled={loadingFighters}
                        aria-labelledby="select-fighter-label"
                      >
                        {loadingFighters ? (
                          <MenuItem disabled>Loading fighters...</MenuItem>
                        ) : fighters.length === 0 ? (
                          <MenuItem disabled>No fighters found</MenuItem>
                        ) : (
                          fighters.map((fighter) => {
                            const fighterName = fighter.fighter_profile?.name || fighter.email;
                            const fighterStats = fighter.fighter_profile 
                              ? `(${fighter.fighter_profile.wins}W-${fighter.fighter_profile.losses}L)`
                              : '';
                            const fullText = `${fighterName} ${fighterStats}`.trim();
                            return (
                              <MenuItem 
                                key={fighter.id} 
                                value={fighter.id}
                                aria-label={fullText}
                                title={fullText}
                              >
                                <Box component="span" aria-hidden="true">
                                  {fighterName}
                                  {fighter.fighter_profile && (
                                    <Box component="span" sx={{ ml: 1, color: 'text.secondary' }}>
                                      ({fighter.fighter_profile.wins}W-{fighter.fighter_profile.losses}L)
                                    </Box>
                                  )}
                                </Box>
                              </MenuItem>
                            );
                          })
                        )}
                      </Select>
                    </FormControl>

                    {selectedFighter && selectedFighter.fighter_profile && (
                      <>
                        <Divider sx={{ my: 2 }} />
                        <Typography variant="subtitle2" gutterBottom>
                          Current Records:
                        </Typography>
                        <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 2, mt: 1 }}>
                          <Typography variant="body2">
                            <strong>Wins:</strong> {selectedFighter.fighter_profile.wins}
                          </Typography>
                          <Typography variant="body2">
                            <strong>Losses:</strong> {selectedFighter.fighter_profile.losses}
                          </Typography>
                          <Typography variant="body2">
                            <strong>Draws:</strong> {(selectedFighter.fighter_profile as any)?.draws ?? 'N/A'}
                          </Typography>
                          <Typography variant="body2">
                            <strong>Points:</strong> {selectedFighter.fighter_profile.points}
                          </Typography>
                          <Typography variant="body2">
                            <strong>Tier:</strong> {selectedFighter.fighter_profile.tier}
                          </Typography>
                        </Box>
                      </>
                    )}

                    <Alert severity="warning" sx={{ mt: 2 }}>
                      <Typography variant="body2" fontWeight="bold">
                        ⚠️ This action cannot be undone! All fight records for this fighter will be permanently deleted.
                      </Typography>
                    </Alert>
                  </CardContent>
                </Card>
              </>
            ) : (
              <Alert 
                severity="warning" 
                icon={<WarningIcon />}
                sx={{ mb: 3 }}
              >
                <Typography variant="body1" fontWeight="bold" gutterBottom>
                  Are you absolutely sure?
                </Typography>
                <Typography variant="body2">
                  This will reset {selectedFighter?.fighter_profile?.name || selectedFighter?.email}'s records to zero and permanently delete all their fight records. 
                  This action is permanent and cannot be undone.
                </Typography>
              </Alert>
            )}
          </TabPanel>

          {error && (
            <Alert severity="error" sx={{ mt: 2 }}>
              {error}
            </Alert>
          )}

          {success && (
            <Alert severity="success" sx={{ mt: 2 }}>
              {activeTab === 0 
                ? 'All fighters records and fight records have been reset/deleted successfully!'
                : `${selectedFighter?.fighter_profile?.name || 'Fighter'}'s records and fight records have been reset/deleted successfully!`}
            </Alert>
          )}
        </Box>
      </DialogContent>

      <DialogActions>
        <Button onClick={handleClose} disabled={loading}>
          {confirmReset ? 'Cancel' : 'Close'}
        </Button>
        {activeTab === 0 ? (
          <Button
            onClick={handleResetAllRecords}
            variant="contained"
            color={confirmReset ? 'error' : 'primary'}
            startIcon={loading ? <CircularProgress size={20} /> : <RefreshIcon />}
            disabled={loading || success}
          >
            {loading
              ? 'Resetting...'
              : confirmReset
              ? 'Confirm Reset All Records'
              : 'Reset All Fighters Records'}
          </Button>
        ) : (
          <Button
            onClick={handleResetIndividualRecord}
            variant="contained"
            color={confirmReset ? 'error' : 'primary'}
            startIcon={loading ? <CircularProgress size={20} /> : <PersonIcon />}
            disabled={loading || success || !selectedFighterId}
          >
            {loading
              ? 'Resetting...'
              : confirmReset
              ? `Confirm Reset ${selectedFighter?.fighter_profile?.name || 'Fighter'} Records`
              : 'Reset Fighter Records'}
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
};

export default FightRecordsManagement;
