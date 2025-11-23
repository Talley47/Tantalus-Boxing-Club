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
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  IconButton,
  ImageList,
  ImageListItem,
  ImageListItemBar,
  Dialog as ConfirmDialog,
  DialogContentText,
} from '@mui/material';
import {
  Close as CloseIcon,
  Delete as DeleteIcon,
  Upload as UploadIcon,
  EmojiEvents as TrophyIcon,
} from '@mui/icons-material';
import Tooltip from '@mui/material/Tooltip';
import { AdminService, AdminUser } from '../../services/adminService';
import {
  championshipBeltService,
  ChampionshipBelt,
  GoverningBody,
  GOVERNING_BODY_LABELS,
  CreateChampionshipBeltRequest,
} from '../../services/championshipBeltService';

interface ChampionshipBeltManagementProps {
  open: boolean;
  onClose: () => void;
}

const ChampionshipBeltManagement: React.FC<ChampionshipBeltManagementProps> = ({
  open,
  onClose,
}) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [fighters, setFighters] = useState<AdminUser[]>([]);
  const [loadingFighters, setLoadingFighters] = useState(false);
  const [selectedFighterId, setSelectedFighterId] = useState<string>('');
  const [selectedFighter, setSelectedFighter] = useState<AdminUser | null>(null);
  const [selectedGoverningBody, setSelectedGoverningBody] = useState<GoverningBody | ''>('');
  const [beltImageFile, setBeltImageFile] = useState<File | null>(null);
  const [beltImagePreview, setBeltImagePreview] = useState<string | null>(null);
  const [existingBelts, setExistingBelts] = useState<ChampionshipBelt[]>([]);
  const [loadingBelts, setLoadingBelts] = useState(false);
  const [deleteConfirmOpen, setDeleteConfirmOpen] = useState(false);
  const [beltToDelete, setBeltToDelete] = useState<ChampionshipBelt | null>(null);
  const [uploading, setUploading] = useState(false);
  const [selectedFighterForDeletion, setSelectedFighterForDeletion] = useState<string>('all');

  // Load fighters when dialog opens
  useEffect(() => {
    if (open) {
      loadFighters();
      loadAllBelts();
    }
  }, [open]);

  // Update selected fighter when ID changes
  useEffect(() => {
    if (selectedFighterId && fighters.length > 0) {
      const fighter = fighters.find(f => f.id === selectedFighterId);
      setSelectedFighter(fighter || null);
      if (fighter) {
        loadFighterBelts(fighter.id);
      }
    } else {
      setSelectedFighter(null);
      setExistingBelts([]);
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

  const loadAllBelts = async () => {
    try {
      setLoadingBelts(true);
      const belts = await championshipBeltService.getAllBelts();
      setExistingBelts(belts);
    } catch (err: any) {
      console.error('Error loading championship belts:', err);
      setError('Failed to load championship belts');
    } finally {
      setLoadingBelts(false);
    }
  };

  const loadFighterBelts = async (userId: string) => {
    try {
      setLoadingBelts(true);
      const belts = await championshipBeltService.getBeltsByUserId(userId);
      setExistingBelts(belts);
    } catch (err: any) {
      console.error('Error loading fighter belts:', err);
      setError('Failed to load fighter belts');
    } finally {
      setLoadingBelts(false);
    }
  };

  const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Validate file type
    if (!file.type.startsWith('image/')) {
      setError('Please select an image file');
      return;
    }

    // Validate file size (10MB max)
    if (file.size > 10 * 1024 * 1024) {
      setError('Image size must be less than 10MB');
      return;
    }

    setBeltImageFile(file);
    setError(null);

    // Create preview
    const reader = new FileReader();
    reader.onloadend = () => {
      setBeltImagePreview(reader.result as string);
    };
    reader.readAsDataURL(file);
  };

  const handleUpload = async () => {
    if (!selectedFighterId || !selectedFighter) {
      setError('Please select a fighter');
      return;
    }

    if (!selectedGoverningBody) {
      setError('Please select a governing body');
      return;
    }

    if (!beltImageFile) {
      setError('Please select an image file');
      return;
    }

    try {
      setUploading(true);
      setError(null);
      setSuccess(null);

      // Get fighter profile ID from user ID
      const fighterProfileId = await championshipBeltService.getFighterProfileId(selectedFighterId);

      if (!fighterProfileId) {
        throw new Error('Fighter profile not found');
      }

      // Upload image
      const imageUrl = await championshipBeltService.uploadBeltImage(
        beltImageFile,
        fighterProfileId
      );

      // Create belt record
      const request: CreateChampionshipBeltRequest = {
        fighter_id: fighterProfileId,
        user_id: selectedFighterId,
        governing_body: selectedGoverningBody as GoverningBody,
        belt_image_url: imageUrl,
      };

      await championshipBeltService.createBelt(request);

      setSuccess(`Championship belt assigned successfully!`);
      
      // Reset form
      setBeltImageFile(null);
      setBeltImagePreview(null);
      setSelectedGoverningBody('');
      (document.getElementById('belt-image-input') as HTMLInputElement).value = '';

      // Reload belts
      await loadFighterBelts(selectedFighterId);
      await loadAllBelts();
    } catch (err: any) {
      console.error('Error uploading championship belt:', err);
      setError(err.message || 'Failed to upload championship belt');
    } finally {
      setUploading(false);
    }
  };

  const handleDeleteClick = (belt: ChampionshipBelt) => {
    setBeltToDelete(belt);
    setDeleteConfirmOpen(true);
  };

  const handleDeleteConfirm = async () => {
    if (!beltToDelete) return;

    try {
      setLoading(true);
      setError(null);
      setSuccess(null);

      await championshipBeltService.deleteBelt(beltToDelete.id);

      setSuccess('Championship belt deleted successfully!');
      setDeleteConfirmOpen(false);
      setBeltToDelete(null);

      // Reload belts
      if (selectedFighterId) {
        await loadFighterBelts(selectedFighterId);
      }
      await loadAllBelts();
    } catch (err: any) {
      console.error('Error deleting championship belt:', err);
      setError(err.message || 'Failed to delete championship belt');
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    setSelectedFighterId('');
    setSelectedFighter(null);
    setSelectedGoverningBody('');
    setBeltImageFile(null);
    setBeltImagePreview(null);
    setExistingBelts([]);
    setError(null);
    setSuccess(null);
    setBeltToDelete(null);
    setDeleteConfirmOpen(false);
    setSelectedFighterForDeletion('all');
    onClose();
  };

  // Get belts for selected fighter
  const selectedFighterBelts = selectedFighterId
    ? existingBelts.filter(belt => belt.user_id === selectedFighterId)
    : [];

  // Get fighter name for a belt
  const getFighterNameForBelt = (belt: ChampionshipBelt): string => {
    const fighter = fighters.find(f => f.id === belt.user_id);
    return fighter?.fighter_profile?.name || fighter?.email || 'Unknown Fighter';
  };

  return (
    <>
      <Dialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
        <DialogTitle>
          <Box display="flex" alignItems="center" justifyContent="space-between">
            <Box display="flex" alignItems="center" gap={1}>
              <TrophyIcon />
              <Typography variant="h6">Championship Belt Management</Typography>
            </Box>
            <IconButton onClick={handleClose} size="small">
              <CloseIcon />
            </IconButton>
          </Box>
        </DialogTitle>
        <DialogContent>
          {error && (
            <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
              {error}
            </Alert>
          )}
          {success && (
            <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccess(null)}>
              {success}
            </Alert>
          )}

          <Card sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Assign Championship Belt
              </Typography>
              
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <FormControl fullWidth>
                  <InputLabel>Select Fighter</InputLabel>
                  <Select
                    value={selectedFighterId}
                    onChange={(e) => setSelectedFighterId(e.target.value)}
                    label="Select Fighter"
                    disabled={loadingFighters}
                  >
                    {fighters.map((fighter) => (
                      <MenuItem key={fighter.id} value={fighter.id}>
                        {fighter.fighter_profile?.name || fighter.email} 
                        {fighter.fighter_profile && ` (${fighter.fighter_profile.tier})`}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>

                <FormControl fullWidth>
                  <InputLabel>Governing Body</InputLabel>
                  <Select
                    value={selectedGoverningBody}
                    onChange={(e) => setSelectedGoverningBody(e.target.value as GoverningBody)}
                    label="Governing Body"
                  >
                    {Object.entries(GOVERNING_BODY_LABELS).map(([value, label]) => (
                      <MenuItem key={value} value={value}>
                        {label}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>

                <Box>
                  <input
                    accept="image/*"
                    style={{ display: 'none' }}
                    id="belt-image-input"
                    type="file"
                    onChange={handleImageSelect}
                  />
                  <label htmlFor="belt-image-input">
                    <Button
                      variant="outlined"
                      component="span"
                      startIcon={<UploadIcon />}
                      fullWidth
                    >
                      Upload Belt Image
                    </Button>
                  </label>
                  {beltImagePreview && (
                    <Box mt={2}>
                      <img
                        src={beltImagePreview}
                        alt="Belt preview"
                        style={{
                          maxWidth: '100%',
                          maxHeight: '200px',
                          objectFit: 'contain',
                          borderRadius: '4px',
                        }}
                      />
                    </Box>
                  )}
                </Box>

                <Button
                  variant="contained"
                  fullWidth
                  onClick={handleUpload}
                  disabled={!selectedFighterId || !selectedGoverningBody || !beltImageFile || uploading}
                  startIcon={uploading ? <CircularProgress size={20} /> : <TrophyIcon />}
                >
                  {uploading ? 'Uploading...' : 'Assign Championship Belt'}
                </Button>
              </Box>
            </CardContent>
          </Card>

          {selectedFighter && (
            <Card sx={{ mb: 3 }}>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  {selectedFighter.fighter_profile?.name || selectedFighter.email}'s Championship Belts
                </Typography>
                {loadingBelts ? (
                  <Box display="flex" justifyContent="center" p={3}>
                    <CircularProgress />
                  </Box>
                ) : selectedFighterBelts.length === 0 ? (
                  <Typography color="text.secondary">
                    No championship belts assigned yet.
                  </Typography>
                ) : (
                  <ImageList cols={3} gap={16}>
                    {selectedFighterBelts.map((belt) => (
                      <ImageListItem key={belt.id}>
                        <img
                          src={belt.belt_image_url}
                          alt={GOVERNING_BODY_LABELS[belt.governing_body]}
                          loading="lazy"
                          style={{ width: '100%', height: 'auto' }}
                        />
                        <ImageListItemBar
                          title={GOVERNING_BODY_LABELS[belt.governing_body]}
                          actionIcon={
                            <Tooltip title="Delete Championship Belt">
                              <IconButton
                                sx={{ 
                                  color: 'rgba(255, 255, 255, 0.9)',
                                  '&:hover': {
                                    color: '#ff4444',
                                    backgroundColor: 'rgba(255, 68, 68, 0.2)'
                                  }
                                }}
                                onClick={() => handleDeleteClick(belt)}
                                aria-label="Delete belt"
                              >
                                <DeleteIcon />
                              </IconButton>
                            </Tooltip>
                          }
                        />
                      </ImageListItem>
                    ))}
                  </ImageList>
                )}
              </CardContent>
            </Card>
          )}

          {/* All Championship Belts - Admin can delete any belt */}
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Delete Championship Belts
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Select a fighter to view and delete their championship belts
              </Typography>
              
              <FormControl fullWidth sx={{ mb: 3 }}>
                <InputLabel>Select Fighter to Delete Belts From</InputLabel>
                <Select
                  value={selectedFighterForDeletion}
                  onChange={(e) => setSelectedFighterForDeletion(e.target.value)}
                  label="Select Fighter to Delete Belts From"
                  disabled={loadingFighters}
                >
                  <MenuItem value="all">
                    <em>All Fighters (Show All Belts)</em>
                  </MenuItem>
                  {fighters.map((fighter) => (
                    <MenuItem key={fighter.id} value={fighter.id}>
                      {fighter.fighter_profile?.name || fighter.email} 
                      {fighter.fighter_profile && ` (${fighter.fighter_profile.tier})`}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>

              {loadingBelts ? (
                <Box display="flex" justifyContent="center" p={3}>
                  <CircularProgress />
                </Box>
              ) : (() => {
                // Filter belts based on selected fighter
                const beltsToShow = selectedFighterForDeletion === 'all'
                  ? existingBelts
                  : existingBelts.filter(belt => belt.user_id === selectedFighterForDeletion);
                
                const selectedFighterName = selectedFighterForDeletion === 'all'
                  ? null
                  : fighters.find(f => f.id === selectedFighterForDeletion)?.fighter_profile?.name ||
                    fighters.find(f => f.id === selectedFighterForDeletion)?.email ||
                    'Unknown Fighter';

                if (beltsToShow.length === 0) {
                  return (
                    <Typography color="text.secondary">
                      {selectedFighterForDeletion === 'all'
                        ? 'No championship belts assigned to any fighter.'
                        : `${selectedFighterName} has no championship belts assigned.`}
                    </Typography>
                  );
                }

                return (
                  <>
                    {selectedFighterForDeletion !== 'all' && (
                      <Typography variant="subtitle1" sx={{ mb: 2, fontWeight: 'bold' }}>
                        {selectedFighterName}'s Championship Belts ({beltsToShow.length})
                      </Typography>
                    )}
                    <ImageList cols={3} gap={16}>
                      {beltsToShow.map((belt) => (
                        <ImageListItem key={belt.id}>
                          <img
                            src={belt.belt_image_url}
                            alt={GOVERNING_BODY_LABELS[belt.governing_body]}
                            loading="lazy"
                            style={{ width: '100%', height: 'auto' }}
                          />
                          <ImageListItemBar
                            title={GOVERNING_BODY_LABELS[belt.governing_body]}
                            subtitle={selectedFighterForDeletion === 'all' ? getFighterNameForBelt(belt) : undefined}
                            actionIcon={
                              <Tooltip title="Delete Championship Belt">
                                <IconButton
                                  sx={{ 
                                    color: 'rgba(255, 255, 255, 0.9)',
                                    '&:hover': {
                                      color: '#ff4444',
                                      backgroundColor: 'rgba(255, 68, 68, 0.2)'
                                    }
                                  }}
                                  onClick={() => handleDeleteClick(belt)}
                                  aria-label="Delete belt"
                                >
                                  <DeleteIcon />
                                </IconButton>
                              </Tooltip>
                            }
                          />
                        </ImageListItem>
                      ))}
                    </ImageList>
                  </>
                );
              })()}
            </CardContent>
          </Card>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose}>Close</Button>
        </DialogActions>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        open={deleteConfirmOpen}
        onClose={() => setDeleteConfirmOpen(false)}
      >
        <DialogTitle>Delete Championship Belt?</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Are you sure you want to delete this championship belt? This action cannot be undone.
            {beltToDelete && (
              <>
                <br />
                <br />
                <Box sx={{ mt: 2, p: 2, bgcolor: 'background.paper', borderRadius: 1 }}>
                  <Typography variant="body2" sx={{ mb: 1 }}>
                    <strong>Governing Body:</strong> {GOVERNING_BODY_LABELS[beltToDelete.governing_body]}
                  </Typography>
                  <Typography variant="body2">
                    <strong>Fighter:</strong> {getFighterNameForBelt(beltToDelete)}
                  </Typography>
                </Box>
              </>
            )}
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteConfirmOpen(false)}>Cancel</Button>
          <Button onClick={handleDeleteConfirm} color="error" variant="contained" disabled={loading}>
            {loading ? <CircularProgress size={20} /> : 'Delete'}
          </Button>
        </DialogActions>
      </ConfirmDialog>
    </>
  );
};

export default ChampionshipBeltManagement;

