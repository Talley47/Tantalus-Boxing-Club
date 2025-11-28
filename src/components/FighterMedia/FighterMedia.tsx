import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Avatar,
  Chip,
  Stack,
  CircularProgress,
  Alert,
  Divider,
  Button,
} from '@mui/material';
import {
  Link as LinkIcon,
  Share,
  EmojiEvents,
  SportsMma,
  Person,
} from '@mui/icons-material';
import { useParams, useNavigate } from 'react-router-dom';
import { supabase } from '../../services/supabase';
import { mediaService } from '../../services/mediaService';
import { SocialLink } from '../../types';
import logo1 from '../../Logo1.png';
import backgroundImage from '../../TBC Ring Magazine.png';

// Debug: Log the imported image path
console.log('FighterMedia background image imported:', backgroundImage);
console.log('Image type:', typeof backgroundImage);

const FighterMedia: React.FC = () => {
  const { userId } = useParams<{ userId: string }>();
  const navigate = useNavigate();
  const [fighterProfile, setFighterProfile] = useState<any>(null);
  const [socialLinks, setSocialLinks] = useState<SocialLink[]>([]);
  const [fightRecords, setFightRecords] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const loadFighterMedia = async () => {
      if (!userId) {
        setError('Invalid fighter ID');
        setLoading(false);
        return;
      }

      try {
        setLoading(true);
        
        // Load fighter profile
        const { data: profile, error: profileError } = await supabase
          .from('fighter_profiles')
          .select('*')
          .eq('user_id', userId)
          .single();

        if (profileError) throw profileError;
        if (!profile) {
          setError('Fighter profile not found');
          setLoading(false);
          return;
        }

        setFighterProfile(profile);

        // Load social links
        try {
          const links = await mediaService.getSocialLinks(profile.id);
          setSocialLinks(links);
        } catch (err) {
          console.error('Error loading social links:', err);
          setSocialLinks([]);
        }

        // Load fight records
        try {
          const { data: records, error: recordsError } = await supabase
            .from('fight_records')
            .select('*')
            .eq('fighter_id', userId)
            .order('date', { ascending: false })
            .limit(10);

          if (!recordsError && records) {
            setFightRecords(records);
          }
        } catch (err) {
          console.error('Error loading fight records:', err);
          setFightRecords([]);
        }
      } catch (err: any) {
        console.error('Error loading fighter media:', err);
        setError(err.message || 'Failed to load fighter media');
      } finally {
        setLoading(false);
      }
    };

    loadFighterMedia();
  }, [userId]);

  const handleShare = async () => {
    const url = window.location.href;
    try {
      await navigator.clipboard.writeText(url);
      alert('Link copied to clipboard!');
    } catch (err) {
      console.error('Failed to copy link:', err);
    }
  };

  if (loading) {
    return (
      <>
        {/* Full-screen background layer */}
        <Box
          component="div"
          sx={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            width: '100%',
            height: '100vh',
            backgroundImage: backgroundImage ? `url("${backgroundImage}")` : 'url("/TBC Ring Magazine.png")',
            backgroundSize: '100% 100%',
            backgroundPosition: 'center center',
            backgroundRepeat: 'no-repeat',
            backgroundAttachment: 'fixed',
            zIndex: -1,
            display: 'block',
          }}
        />
        <Box
          sx={{
            position: 'relative',
            zIndex: 0,
            minHeight: '100vh',
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
          }}
        >
          <CircularProgress sx={{ color: 'white' }} />
        </Box>
      </>
    );
  }

  if (error || !fighterProfile) {
    return (
      <>
        {/* Full-screen background layer */}
        <Box
          component="div"
          sx={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            width: '100%',
            height: '100vh',
            backgroundImage: backgroundImage ? `url("${backgroundImage}")` : 'url("/TBC Ring Magazine.png")',
            backgroundSize: '100% 100%',
            backgroundPosition: 'center center',
            backgroundRepeat: 'no-repeat',
            backgroundAttachment: 'fixed',
            zIndex: -1,
            display: 'block',
          }}
        />
        <Box
          sx={{
            position: 'relative',
            zIndex: 0,
            minHeight: '100vh',
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'center',
            alignItems: 'center',
            p: 3,
          }}
        >
          <Box sx={{ maxWidth: 600, width: '100%' }}>
            <Alert severity="error" sx={{ mb: 2 }}>
              {error || 'Fighter profile not found'}
            </Alert>
            <Typography variant="body2" color="white" textAlign="center">
              This fighter's media profile is not available or has been removed.
            </Typography>
          </Box>
        </Box>
      </>
    );
  }

  const record = `${fighterProfile.wins || 0}-${fighterProfile.losses || 0}-${fighterProfile.draws || 0}`;
  const knockouts = fighterProfile.knockouts || 0;

  return (
    <>
      {/* Full-screen background layer */}
      <Box
        component="div"
        sx={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          width: '100%',
          height: '100vh',
          backgroundImage: backgroundImage ? `url("${backgroundImage}")` : 'url("/TBC Ring Magazine.png")',
          backgroundSize: '100% 100%',
          backgroundPosition: 'center center',
          backgroundRepeat: 'no-repeat',
          backgroundAttachment: 'fixed',
          zIndex: -1,
          display: 'block',
        }}
      />
      {/* Content layer */}
      <Box
        sx={{
          position: 'relative',
          zIndex: 0,
          minHeight: '100vh',
          py: 4,
          px: { xs: 2, md: 4 },
        }}
      >
      <Box sx={{ maxWidth: 1200, mx: 'auto' }}>
        {/* Header */}
        <Box display="flex" justifyContent="space-between" alignItems="center" mb={4}>
          <Box display="flex" alignItems="center" gap={2}>
            <Box
              component="img"
              src={logo1}
              alt="Tantalus Boxing Club Logo"
              sx={{
                height: { xs: 50, md: 70 },
                width: 'auto',
                objectFit: 'contain',
              }}
            />
            <Typography variant="h4" sx={{ fontWeight: 'bold', color: 'white' }}>
              Tantalus Ring Magazine Media
            </Typography>
          </Box>
          <Button
            variant="contained"
            startIcon={<Share />}
            onClick={handleShare}
            sx={{ bgcolor: 'white', color: 'primary.main', '&:hover': { bgcolor: 'grey.100' } }}
          >
            Share
          </Button>
        </Box>

        {/* Fighter Profile Card */}
        <Card sx={{ mb: 3, boxShadow: 6 }}>
          <CardContent sx={{ p: 4 }}>
            <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, gap: 4 }}>
              {/* Left Column: Fighter Info */}
              <Box sx={{ flex: { xs: '1', md: '0 0 66.666%' } }}>
                <Box display="flex" alignItems="center" gap={3} mb={3}>
                  <Avatar
                    sx={{
                      width: { xs: 80, md: 120 },
                      height: { xs: 80, md: 120 },
                      bgcolor: 'primary.main',
                      fontSize: { xs: '2rem', md: '3rem' },
                    }}
                  >
                    {fighterProfile.name?.charAt(0) || '?'}
                  </Avatar>
                  <Box>
                    <Typography variant="h3" sx={{ fontWeight: 'bold', mb: 1 }}>
                      {fighterProfile.name}
                    </Typography>
                    <Typography variant="h6" color="text.secondary" gutterBottom>
                      @{fighterProfile.handle}
                    </Typography>
                    <Stack direction="row" spacing={1} flexWrap="wrap">
                      <Chip label={fighterProfile.tier || 'Amateur'} color="primary" />
                      <Chip label={fighterProfile.weight_class || 'N/A'} variant="outlined" />
                      <Chip label={`${fighterProfile.points || 0} pts`} variant="outlined" />
                    </Stack>
                  </Box>
                </Box>

                {/* Record */}
                <Box mb={3}>
                  <Typography variant="h5" sx={{ fontWeight: 'bold', mb: 2 }}>
                    Record
                  </Typography>
                  <Stack direction="row" spacing={3}>
                    <Box>
                      <Typography variant="h3" color="primary.main" sx={{ fontWeight: 'bold' }}>
                        {record}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Wins-Losses-Draws
                      </Typography>
                    </Box>
                    {knockouts > 0 && (
                      <Box>
                        <Typography variant="h3" color="error.main" sx={{ fontWeight: 'bold' }}>
                          {knockouts}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          Knockouts
                        </Typography>
                      </Box>
                    )}
                  </Stack>
                </Box>

                {/* Bio */}
                {(fighterProfile as any)?.social_media_bio && (
                  <Box mb={3}>
                    <Typography variant="h6" sx={{ fontWeight: 'bold', mb: 1 }}>
                      Bio
                    </Typography>
                    <Typography variant="body1" sx={{ whiteSpace: 'pre-wrap', lineHeight: 1.8 }}>
                      {(fighterProfile as any).social_media_bio}
                    </Typography>
                  </Box>
                )}

                {/* Social Links */}
                {socialLinks.length > 0 && (
                  <Box mb={3}>
                    <Typography variant="h6" sx={{ fontWeight: 'bold', mb: 2 }}>
                      Follow {fighterProfile.name}
                    </Typography>
                    <Stack direction="row" spacing={1} flexWrap="wrap">
                      {socialLinks.map((link) => (
                        <Chip
                          key={link.id}
                          label={link.platform}
                          component="a"
                          href={link.url}
                          target="_blank"
                          rel="noopener noreferrer"
                          clickable
                          icon={<LinkIcon />}
                          sx={{ mb: 1 }}
                        />
                      ))}
                    </Stack>
                  </Box>
                )}
              </Box>

              {/* Right Column: Creative Fighter Image */}
              <Box sx={{ flex: { xs: '1', md: '0 0 33.333%' } }}>
                {(fighterProfile as any)?.creative_fighter_image_url ? (
                  <Box
                    component="img"
                    src={(fighterProfile as any).creative_fighter_image_url}
                    alt="Creative Fighter"
                    sx={{
                      width: '100%',
                      maxHeight: '500px',
                      objectFit: 'contain',
                      borderRadius: 2,
                      boxShadow: 3,
                    }}
                  />
                ) : (
                  <Box
                    sx={{
                      width: '100%',
                      height: '300px',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      border: '2px dashed',
                      borderColor: 'divider',
                      borderRadius: 2,
                    }}
                  >
                    <Typography variant="body2" color="text.secondary">
                      No Creative Fighter image
                    </Typography>
                  </Box>
                )}
              </Box>
            </Box>
          </CardContent>
        </Card>

        {/* Recent Fight Records */}
        {fightRecords.length > 0 && (
          <Card sx={{ boxShadow: 6 }}>
            <CardContent>
              <Typography variant="h5" sx={{ fontWeight: 'bold', mb: 3 }}>
                Recent Fights
              </Typography>
              <Stack spacing={2}>
                {fightRecords.map((fight) => (
                  <Box key={fight.id}>
                    <Box display="flex" justifyContent="space-between" alignItems="center" mb={1}>
                      <Typography variant="h6">
                        vs. {fight.opponent_name}
                      </Typography>
                      <Chip
                        label={fight.result.toUpperCase()}
                        color={fight.result === 'win' ? 'success' : fight.result === 'loss' ? 'error' : 'default'}
                        size="small"
                      />
                    </Box>
                    <Typography variant="body2" color="text.secondary">
                      {fight.method} {fight.round ? `(Round ${fight.round})` : ''} • {new Date(fight.date).toLocaleDateString()}
                    </Typography>
                    <Divider sx={{ mt: 2 }} />
                  </Box>
                ))}
              </Stack>
            </CardContent>
          </Card>
        )}
      </Box>
      </Box>
    </>
  );
};

export default FighterMedia;

