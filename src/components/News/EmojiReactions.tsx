import React, { useState, useEffect } from 'react';
import {
  Box,
  IconButton,
  Tooltip,
  Popover,
  Typography,
  Stack,
  Divider,
  Button,
} from '@mui/material';
import {
  ThumbUp,
  ThumbDown,
  Favorite,
  SentimentSatisfied,
  SentimentVeryDissatisfied,
  EmojiEmotions,
  Whatshot,
  SentimentVerySatisfied,
} from '@mui/icons-material';
import { NewsReactionsService, ReactionType, ReactionCounts } from '../../services/newsReactionsService';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../services/supabase';

interface EmojiReactionsProps {
  newsId: string;
}

const REACTION_EMOJIS: Record<ReactionType, { emoji: string; label: string; icon: React.ReactNode; color: string }> = {
  like: { emoji: '👍', label: 'Like', icon: <ThumbUp />, color: '#2196F3' },
  dislike: { emoji: '👎', label: 'Dislike', icon: <ThumbDown />, color: '#757575' },
  love: { emoji: '❤️', label: 'Love', icon: <Favorite />, color: '#E91E63' },
  laugh: { emoji: '😂', label: 'Laugh', icon: <EmojiEmotions />, color: '#FFC107' },
  angry: { emoji: '😠', label: 'Angry', icon: <SentimentVeryDissatisfied />, color: '#F44336' },
  sad: { emoji: '😢', label: 'Sad', icon: <SentimentSatisfied />, color: '#9C27B0' },
  wow: { emoji: '😮', label: 'Wow', icon: <SentimentVerySatisfied />, color: '#FF9800' },
  fire: { emoji: '🔥', label: 'Fire', icon: <Whatshot />, color: '#FF5722' },
};

const EmojiReactions: React.FC<EmojiReactionsProps> = ({ newsId }) => {
  const { user } = useAuth();
  const [reactionCounts, setReactionCounts] = useState<ReactionCounts>({});
  const [userReaction, setUserReaction] = useState<ReactionType | null>(null);
  const [loading, setLoading] = useState(false);
  const [anchorEl, setAnchorEl] = useState<HTMLButtonElement | null>(null);
  const [showAllReactions, setShowAllReactions] = useState(false);

  const open = Boolean(anchorEl);

  // Load initial reaction counts and user reaction
  useEffect(() => {
    if (!newsId) return;

    const loadReactions = async () => {
      try {
        const [counts, userReact] = await Promise.all([
          NewsReactionsService.getReactionCounts(newsId),
          user ? NewsReactionsService.getUserReaction(newsId, user.id) : Promise.resolve(null),
        ]);

        setReactionCounts(counts);
        setUserReaction(userReact);
      } catch (error) {
        console.error('Error loading reactions:', error);
      }
    };

    loadReactions();

    // Set up real-time subscription for reactions
    const channel = supabase
      .channel(`news_reactions_${newsId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'news_reactions',
          filter: `news_id=eq.${newsId}`,
        },
        (payload) => {
          console.log('🔔 Reaction changed:', payload.eventType);
          // Reload reactions when they change
          loadReactions();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [newsId, user]);

  const handleReactionClick = async (reactionType: ReactionType) => {
    if (!user) {
      alert('Please log in to react to posts');
      return;
    }

    if (!newsId) {
      console.error('Cannot add reaction: No newsId');
      return;
    }

    setLoading(true);
    try {
      console.log('Adding reaction:', reactionType, 'to news:', newsId);
      await NewsReactionsService.addReaction(newsId, user.id, reactionType);
      
      // Reload reactions
      const [counts, userReact] = await Promise.all([
        NewsReactionsService.getReactionCounts(newsId),
        NewsReactionsService.getUserReaction(newsId, user.id),
      ]);

      console.log('Reactions updated:', counts, 'User reaction:', userReact);
      setReactionCounts(counts || {});
      setUserReaction(userReact);
    } catch (error: any) {
      console.error('Error adding reaction:', error);
      const errorMessage = error?.message || 'Failed to add reaction. Please try again.';
      
      // Check if it's a database error (table might not exist)
      if (errorMessage.includes('relation') || errorMessage.includes('does not exist')) {
        alert('Reactions feature is not set up yet. Please run the database migration: database/news-reactions-schema.sql');
      } else {
        alert(errorMessage);
      }
    } finally {
      setLoading(false);
    }
  };

  const handleShowAllClick = (event: React.MouseEvent<HTMLButtonElement>) => {
    setAnchorEl(event.currentTarget);
    setShowAllReactions(true);
  };

  const handleClosePopover = () => {
    setAnchorEl(null);
    setShowAllReactions(false);
  };

  // Get top 3 reactions by count
  const topReactions = Object.entries(reactionCounts)
    .sort(([, a], [, b]) => b - a)
    .slice(0, 3)
    .map(([type, count]) => ({ type: type as ReactionType, count }));

  const totalReactions = Object.values(reactionCounts).reduce((sum, count) => sum + count, 0);

  // Always show the component, even if no reactions yet
  // Show quick reaction buttons for most common reactions if no reactions yet
  const quickReactions: ReactionType[] = ['like', 'love', 'fire'];
  
  return (
    <Box sx={{ mt: 2, pt: 2, borderTop: '1px solid rgba(0,0,0,0.1)' }}>
      <Box display="flex" alignItems="center" gap={1} flexWrap="wrap">
        {/* Quick reaction buttons (top 3) - show if there are reactions */}
        {topReactions.length > 0 && topReactions.map(({ type, count }) => (
          <Tooltip key={type} title={`${REACTION_EMOJIS[type].label}: ${count}`}>
            <IconButton
              size="small"
              onClick={() => handleReactionClick(type)}
              disabled={loading}
              sx={{
                bgcolor: userReaction === type ? REACTION_EMOJIS[type].color : 'transparent',
                color: userReaction === type ? 'white' : 'inherit',
                border: userReaction === type ? `2px solid ${REACTION_EMOJIS[type].color}` : '2px solid transparent',
                '&:hover': {
                  bgcolor: userReaction === type ? REACTION_EMOJIS[type].color : 'rgba(0,0,0,0.05)',
                  transform: 'scale(1.1)',
                },
                transition: 'all 0.2s ease',
              }}
            >
              <Box component="span" sx={{ fontSize: '1.2rem', mr: 0.5 }}>
                {REACTION_EMOJIS[type].emoji}
              </Box>
              <Typography variant="caption" sx={{ fontWeight: 'bold' }}>
                {count}
              </Typography>
            </IconButton>
          </Tooltip>
        ))}

        {/* Show quick reaction buttons if no reactions yet */}
        {topReactions.length === 0 && user && quickReactions.map((type) => (
          <Tooltip key={type} title={`${REACTION_EMOJIS[type].label}`}>
            <IconButton
              size="small"
              onClick={() => handleReactionClick(type)}
              disabled={loading}
              sx={{
                bgcolor: userReaction === type ? REACTION_EMOJIS[type].color : 'transparent',
                color: userReaction === type ? 'white' : 'inherit',
                border: userReaction === type ? `2px solid ${REACTION_EMOJIS[type].color}` : '1px solid rgba(0,0,0,0.1)',
                '&:hover': {
                  bgcolor: userReaction === type ? REACTION_EMOJIS[type].color : 'rgba(0,0,0,0.05)',
                  transform: 'scale(1.1)',
                },
                transition: 'all 0.2s ease',
              }}
            >
              <Box component="span" sx={{ fontSize: '1.3rem' }}>
                {REACTION_EMOJIS[type].emoji}
              </Box>
            </IconButton>
          </Tooltip>
        ))}

        {/* Show all reactions button - only if there are more than 3 reactions */}
        {totalReactions > topReactions.reduce((sum, r) => sum + r.count, 0) && (
          <IconButton
            size="small"
            onClick={handleShowAllClick}
            sx={{
              '&:hover': {
                bgcolor: 'rgba(0,0,0,0.05)',
              },
            }}
          >
            <Typography variant="caption" sx={{ color: 'text.secondary' }}>
              +{totalReactions - topReactions.reduce((sum, r) => sum + r.count, 0)} more
            </Typography>
          </IconButton>
        )}

        {/* Add reaction button - always visible */}
        <Button
          variant="contained"
          size="small"
          onClick={handleShowAllClick}
          disabled={loading || !user}
          startIcon={<Box component="span" sx={{ fontSize: '1.2rem' }}>😊</Box>}
          sx={{
            ml: (topReactions.length > 0 || (topReactions.length === 0 && user)) ? 'auto' : 0,
            bgcolor: user ? 'primary.main' : 'grey.400',
            color: 'white',
            px: 2,
            py: 0.5,
            borderRadius: 2,
            textTransform: 'none',
            '&:hover': {
              bgcolor: user ? 'primary.dark' : 'grey.500',
            },
            '&:disabled': {
              bgcolor: 'grey.300',
              color: 'text.disabled',
            },
          }}
        >
          <Typography variant="body2" sx={{ fontWeight: 'bold' }}>
            {user ? 'React' : 'Login to React'}
          </Typography>
        </Button>
      </Box>

      {/* All reactions popover */}
      <Popover
        open={open}
        anchorEl={anchorEl}
        onClose={handleClosePopover}
        anchorOrigin={{
          vertical: 'top',
          horizontal: 'left',
        }}
        transformOrigin={{
          vertical: 'bottom',
          horizontal: 'left',
        }}
        hideBackdrop
        disableRestoreFocus
        PaperProps={{
          sx: {
            p: 2,
            minWidth: 300,
            maxWidth: 400,
          },
        }}
      >
        <Typography variant="subtitle2" gutterBottom sx={{ fontWeight: 'bold' }}>
          React to this post
        </Typography>
        <Divider sx={{ my: 1 }} />
        <Stack spacing={1}>
          {Object.entries(REACTION_EMOJIS).map(([type, { emoji, label, icon, color }]) => {
            const count = reactionCounts[type as ReactionType] || 0;
            const isActive = userReaction === type;
            
            return (
              <Box
                key={type}
                display="flex"
                alignItems="center"
                justifyContent="space-between"
                sx={{
                  p: 1,
                  borderRadius: 1,
                  bgcolor: isActive ? `${color}20` : 'transparent',
                  border: isActive ? `2px solid ${color}` : '2px solid transparent',
                  cursor: 'pointer',
                  '&:hover': {
                    bgcolor: isActive ? `${color}30` : 'rgba(0,0,0,0.05)',
                  },
                  transition: 'all 0.2s ease',
                }}
                onClick={() => {
                  handleReactionClick(type as ReactionType);
                  if (!isActive) {
                    handleClosePopover();
                  }
                }}
              >
                <Box display="flex" alignItems="center" gap={1}>
                  <Box component="span" sx={{ fontSize: '1.5rem' }}>
                    {emoji}
                  </Box>
                  <Typography variant="body2" sx={{ fontWeight: isActive ? 'bold' : 'normal' }}>
                    {label}
                  </Typography>
                </Box>
                <Typography variant="body2" sx={{ fontWeight: 'bold', color: isActive ? color : 'text.secondary' }}>
                  {count}
                </Typography>
              </Box>
            );
          })}
        </Stack>
        {totalReactions === 0 && (
          <Typography variant="caption" color="text.secondary" sx={{ mt: 2, display: 'block', textAlign: 'center' }}>
            No reactions yet. Be the first to react!
          </Typography>
        )}
      </Popover>
    </Box>
  );
};

export default EmojiReactions;

