import React, { useState, useEffect, useRef, useCallback, useMemo, startTransition, useDeferredValue } from 'react';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  Typography,
  Avatar,
  Paper,
  IconButton,
  Tooltip,
  CircularProgress,
  Alert,
  Chip,
  Popover,
  Grid,
} from '@mui/material';
import {
  Send,
  Forum,
  Delete,
  Edit,
  Check,
  Close,
  AttachFile,
  Image,
  InsertLink,
  EmojiEmotions,
  KeyboardArrowDown,
} from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';
import { chatService, ChatMessage } from '../../services/chatService';
import { supabase } from '../../services/supabase';
import { sanitizeText, sanitizeHTML, sanitizeURL } from '../../utils/securityUtils';
import boxingGymBg from '../../bxr-boxinggym-hd-4.jpg';

const Social: React.FC = () => {
  const { user, fighterProfile } = useAuth();
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [loadingOlder, setLoadingOlder] = useState(false);
  const [hasMoreMessages, setHasMoreMessages] = useState(true);
  const [sending, setSending] = useState(false);
  const [editingMessageId, setEditingMessageId] = useState<string | null>(null);
  const [editText, setEditText] = useState('');
  const [uploading, setUploading] = useState(false);
  const [attachmentPreview, setAttachmentPreview] = useState<{ url: string; type: 'image' | 'video' | 'file' } | null>(null);
  const [emojiPickerOpen, setEmojiPickerOpen] = useState(false);
  const [emojiAnchorEl, setEmojiAnchorEl] = useState<HTMLButtonElement | null>(null);
  const [isAtBottom, setIsAtBottom] = useState(true);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const messagesContainerRef = useRef<HTMLDivElement>(null);
  const messagesStartRef = useRef<HTMLDivElement>(null);
  const editingMessageIdRef = useRef<string | null>(null);

  // Keep ref in sync with state
  useEffect(() => {
    editingMessageIdRef.current = editingMessageId;
  }, [editingMessageId]);

  // Scroll to bottom of messages
  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    setIsAtBottom(true);
  };

  // Check if user is at bottom of scroll
  const checkIfAtBottom = () => {
    const container = messagesContainerRef.current;
    if (!container) return;
    
    const threshold = 100; // pixels from bottom
    const isNearBottom = 
      container.scrollHeight - container.scrollTop - container.clientHeight < threshold;
    setIsAtBottom(isNearBottom);
  };

  // Load older messages when scrolling up
  const loadOlderMessages = useCallback(async () => {
    if (loadingOlder || !hasMoreMessages || messages.length === 0) return;

    const oldestMessage = messages[0];
    if (!oldestMessage) return;

    try {
      setLoadingOlder(true);
      const olderMessages = await chatService.getOlderMessages(
        oldestMessage.created_at,
        50
      );

      if (olderMessages.length === 0) {
        setHasMoreMessages(false);
        return;
      }

      // Maintain scroll position
      const container = messagesContainerRef.current;
      const previousScrollHeight = container?.scrollHeight || 0;
      const previousScrollTop = container?.scrollTop || 0;

      // Add older messages to the beginning
      setMessages((prev) => {
        const combined = [...olderMessages, ...prev];
        // Remove duplicates
        const unique = combined.filter(
          (msg, index, self) => index === self.findIndex((m) => m.id === msg.id)
        );
        return unique.sort(
          (a, b) =>
            new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
        );
      });

      // Restore scroll position after a brief delay
      setTimeout(() => {
        if (container) {
          const newScrollHeight = container.scrollHeight;
          const scrollDifference = newScrollHeight - previousScrollHeight;
          container.scrollTop = previousScrollTop + scrollDifference;
        }
      }, 50);
    } catch (error) {
      console.error('Error loading older messages:', error);
    } finally {
      setLoadingOlder(false);
    }
  }, [loadingOlder, hasMoreMessages, messages]);

  // Handle scroll events
  const handleScroll = useCallback(() => {
    checkIfAtBottom();
    
    const container = messagesContainerRef.current;
    if (!container) return;

    // Load older messages when scrolling near the top
    const scrollThreshold = 200; // pixels from top
    if (container.scrollTop < scrollThreshold && hasMoreMessages && !loadingOlder) {
      loadOlderMessages();
    }
  }, [hasMoreMessages, loadingOlder, loadOlderMessages]);

  // Load initial messages
  const loadMessages = async () => {
    try {
      setLoading(true);
      setHasMoreMessages(true);
      const data = await chatService.getMessages(100);
      // Sort messages by created_at to ensure correct chronological order
      const sortedData = data.sort((a: ChatMessage, b: ChatMessage) => 
        new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
      );
      setMessages(sortedData);
      // If we got less than 100 messages, there are no more older messages
      if (data.length < 100) {
        setHasMoreMessages(false);
      }
    } catch (error) {
      console.error('Error loading messages:', error);
    } finally {
      setLoading(false);
    }
  };


  // Delete a message
  const handleDeleteMessage = async (messageId: string) => {
    if (!user) return;
    
    if (!window.confirm('Are you sure you want to delete this message?')) {
      return;
    }

    // Store the message to restore if deletion fails
    const messageToDelete = messages.find(m => m.id === messageId);

    try {
      // Optimistically remove the message immediately for instant feedback
      setMessages((prev) => prev.filter((msg) => msg.id !== messageId));

      // Delete via service (will trigger real-time update)
      await chatService.deleteMessage(messageId, user.id);
      
      // If editing this message, exit edit mode
      if (editingMessageId === messageId) {
        setEditingMessageId(null);
        setEditText('');
      }
      
      // Real-time subscription will confirm the deletion
    } catch (error: any) {
      console.error('Error deleting message:', error);
      
      // Revert optimistic deletion on error
      if (messageToDelete) {
        setMessages((prev) => {
          const updated = [...prev, messageToDelete];
          return updated.sort((a, b) => 
            new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
          );
        });
      }
      
      alert('Failed to delete message: ' + (error.message || 'Unknown error'));
    }
  };

  // Start editing a message
  const handleStartEdit = (message: ChatMessage) => {
    setEditingMessageId(message.id);
    setEditText(message.message);
  };

  // Cancel editing
  const handleCancelEdit = () => {
    setEditingMessageId(null);
    setEditText('');
  };

  // Save edited message
  const handleSaveEdit = async (messageId: string) => {
    if (!editText.trim() || !user) return;

    // SECURITY: Sanitize the edited message before saving
    const sanitizedEditText = sanitizeText(editText.trim());
    if (!sanitizedEditText) {
      alert('Invalid message content. Please try again.');
      return;
    }

    // Store the original message to restore if update fails
    const messageToUpdate = messages.find(m => m.id === messageId);
    if (!messageToUpdate) return;

    try {
      // Optimistically update the message immediately for instant feedback
      setMessages((prev) =>
        prev.map((msg) =>
          msg.id === messageId
            ? { ...msg, message: sanitizedEditText, updated_at: new Date().toISOString() }
            : msg
        )
      );

      // Update via service (will trigger real-time update)
      // SECURITY: Service will also sanitize, but we sanitize here too for defense in depth
      await chatService.updateMessage(messageId, user.id, sanitizedEditText);
      
      // Exit edit mode immediately
      setEditingMessageId(null);
      setEditText('');
      
      // Real-time subscription will update with the full message and profile
    } catch (error: any) {
      console.error('Error updating message:', error);
      
      // Revert optimistic update on error
      setMessages((prev) =>
        prev.map((msg) =>
          msg.id === messageId ? messageToUpdate : msg
        )
      );
      
      alert('Failed to update message: ' + (error.message || 'Unknown error'));
    }
  };

  // Check if user can edit their own message (always allowed for own messages)
  const canEdit = (message: ChatMessage) => {
    return user && message.user_id === user.id;
  };

  // Check if user can delete their own message (always allowed for own messages)
  const canDelete = (message: ChatMessage) => {
    return user && message.user_id === user.id;
  };

  // Detect URLs in text and make them clickable
  // SECURITY: All text is sanitized before rendering to prevent XSS
  const renderMessageText = (text: string) => {
    if (!text) return null;
    
    // SECURITY: Sanitize the entire message first to prevent XSS
    const sanitizedText = sanitizeText(text);
    
    // Improved URL regex that matches http/https URLs and also www. and plain domains
    const urlPattern = /(https?:\/\/[^\s]+|www\.[^\s]+|[a-zA-Z0-9-]+\.[a-zA-Z]{2,}[^\s]*)/gi;
    const parts: (string | React.ReactNode)[] = [];
    let lastIndex = 0;
    let match;
    
    // Reset regex lastIndex
    urlPattern.lastIndex = 0;
    
    while ((match = urlPattern.exec(sanitizedText)) !== null) {
      // Add text before the URL
      if (match.index > lastIndex) {
        // SECURITY: Sanitize text segments before adding
        const textSegment = sanitizedText.substring(lastIndex, match.index);
        parts.push(textSegment);
      }
      
      // Add the URL as a clickable link
      const url = match[0];
      // SECURITY: Sanitize URL to prevent javascript: and other dangerous protocols
      const sanitizedUrl = sanitizeURL(url);
      if (!sanitizedUrl) {
        // If URL is invalid/dangerous, just show as plain text
        parts.push(url);
        lastIndex = match.index + match[0].length;
        continue;
      }
      
      let href = sanitizedUrl;
      if (!sanitizedUrl.startsWith('http://') && !sanitizedUrl.startsWith('https://')) {
        href = `https://${sanitizedUrl}`;
      }
      
      parts.push(
        <a
          key={`link-${match.index}`}
          href={href}
          target="_blank"
          rel="noopener noreferrer"
          style={{ color: '#1976d2', textDecoration: 'underline', wordBreak: 'break-all' }}
          onClick={(e) => e.stopPropagation()}
        >
          {url}
        </a>
      );
      
      lastIndex = urlPattern.lastIndex;
    }
    
    // Add remaining text after the last URL
    if (lastIndex < text.length) {
      parts.push(text.substring(lastIndex));
    }
    
    // If no URLs found, return the text as-is
    if (parts.length === 0) {
      return <span style={{ whiteSpace: 'pre-wrap' }}>{text}</span>;
    }
    
    return (
      <>
        {parts.map((part, index) => 
          typeof part === 'string' ? (
            <span key={index} style={{ whiteSpace: 'pre-wrap' }}>{part}</span>
          ) : (
            part
          )
        )}
      </>
    );
  };

  // Common emojis for quick selection (including boxing/sports emojis)
  const commonEmojis = [
    // Boxing & Sports Emojis
    '🥊', '🥋', '🏆', '🥇', '🥈', '🥉', '🎖️', '🏅', '💪', '👊',
    '🤛', '🤜', '✊', '👏', '🙌', '🎯', '⚡', '🔥', '💥', '💢',
    '⚔️', '🗡️', '🛡️', '🎪', '🎭', '🎬', '📣', '📢', '🔔', '📯',
    // Championship Boxing Belts & Awards
    '👑', '💎', '⭐', '🌟', '✨', '💫', '🎗️', '🎀', '🎁', '🎊',
    '🎉', '🎈', '💍',
    // Faces & Emotions
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃',
    '😉', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '😚', '😙',
    '😋', '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔',
    '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥', '😌', '😔',
    '😪', '🤤', '😴', '😷', '🤒', '🤕', '🤢', '🤮', '🤧', '🥵',
    '🥶', '😵', '🤯', '🤠', '🥳', '😎', '🤓', '🧐', '😕', '😟',
    '🙁', '☹️', '😮', '😯', '😲', '😳', '🥺', '😦', '😧', '😨',
    '😰', '😥', '😢', '😭', '😱', '😖', '😣', '😞', '😓', '😩',
    '😫', '🥱', '😤', '😡', '😠', '🤬', '💀', '☠️', '💩', '🤡',
    '👻', '👽', '👾', '🤖', '😺', '😸', '😹', '😻', '😼', '😽',
    '🙀', '😿', '😾', '🙈', '🙉', '🙊',
    // Hearts & Love
    '💋', '💌', '💘', '💝', '💖', '💗', '💓', '💞', '💕', '💟',
    '❣️', '💔', '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
    '🤎', '💯', '💫', '💦', '💨', '🕳️', '💣', '💬', '🗨️', '🗯️',
    '💭', '💤',
    // Hands & Gestures
    '👋', '🤚', '🖐️', '✋', '🖖', '👌', '🤌', '🤏', '✌️', '🤞',
    '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕', '👇', '☝️', '👍',
    '👎', '👐', '🤲', '🤝', '🙏', '✍️', '🦾', '🦿', '🦵', '🦶',
    '👂', '🦻', '👃',
    // People
    '👶', '👧', '🧒', '👦', '👩', '🧑', '👨', '👵', '🧓', '👴',
    '👲', '👳', '🧕', '👮', '👷', '💂', '🕵️', '👩‍⚕️', '👨‍⚕️', '👩‍🌾',
    '👨‍🌾', '👩‍🍳', '👨‍🍳', '👩‍🎓', '👨‍🎓', '👩‍🎤', '👨‍🎤', '👩‍🏫', '👨‍🏫', '👩‍🏭',
    '👨‍🏭', '👩‍💻', '👨‍💻', '👩‍💼', '👨‍💼', '👩‍🔧', '👨‍🔧', '👩‍🔬', '👨‍🔬', '👩‍🎨',
    '👨‍🎨', '👩‍🚒', '👨‍🚒', '👩‍✈️', '👨‍✈️', '👩‍🚀', '👨‍🚀', '👩‍⚖️', '👨‍⚖️', '👰',
    '🤵', '👸', '🤴', '🦸', '🦹', '🤶', '🎅', '🧙', '🧝', '🧛',
    '🧜', '🧞', '🧟', '💆', '💇', '🚶', '🧍', '🧎', '🏃', '💃',
    '🕺', '🕴️', '👯', '🧘', '🛀', '🛌', '👭', '👫', '👬', '💏',
    '💑', '👪', '🗣️', '👤', '👥', '👣',
    // Black People Emojis (Darker Skin Tones)
    '👶🏾', '👶🏿', '👧🏾', '👧🏿', '🧒🏾', '🧒🏿', '👦🏾', '👦🏿', '👩🏾', '👩🏿',
    '🧑🏾', '🧑🏿', '👨🏾', '👨🏿', '👵🏾', '👵🏿', '🧓🏾', '🧓🏿', '👴🏾', '👴🏿',
    '👮🏾', '👮🏿', '👮‍♀️🏾', '👮‍♀️🏿', '👮‍♂️🏾', '👮‍♂️🏿', '👷🏾', '👷🏿', '👷‍♀️🏾', '👷‍♀️🏿',
    '👷‍♂️🏾', '👷‍♂️🏿', '💂🏾', '💂🏿', '💂‍♀️🏾', '💂‍♀️🏿', '💂‍♂️🏾', '💂‍♂️🏿', '🕵️🏾', '🕵️🏿',
    '🕵️‍♀️🏾', '🕵️‍♀️🏿', '🕵️‍♂️🏾', '🕵️‍♂️🏿', '👩‍⚕️🏾', '👩‍⚕️🏿', '👨‍⚕️🏾', '👨‍⚕️🏿', '👩‍🌾🏾', '👩‍🌾🏿',
    '👨‍🌾🏾', '👨‍🌾🏿', '👩‍🍳🏾', '👩‍🍳🏿', '👨‍🍳🏾', '👨‍🍳🏿', '👩‍🎓🏾', '👩‍🎓🏿', '👨‍🎓🏾', '👨‍🎓🏿',
    '👩‍🎤🏾', '👩‍🎤🏿', '👨‍🎤🏾', '👨‍🎤🏿', '👩‍🏫🏾', '👩‍🏫🏿', '👨‍🏫🏾', '👨‍🏫🏿', '👩‍🏭🏾', '👩‍🏭🏿',
    '👨‍🏭🏾', '👨‍🏭🏿', '👩‍💻🏾', '👩‍💻🏿', '👨‍💻🏾', '👨‍💻🏿', '👩‍💼🏾', '👩‍💼🏿', '👨‍💼🏾', '👨‍💼🏿',
    '👩‍🔧🏾', '👩‍🔧🏿', '👨‍🔧🏾', '👨‍🔧🏿', '👩‍🔬🏾', '👩‍🔬🏿', '👨‍🔬🏾', '👨‍🔬🏿', '👩‍🎨🏾', '👩‍🎨🏿',
    '👨‍🎨🏾', '👨‍🎨🏿', '👩‍🚒🏾', '👩‍🚒🏿', '👨‍🚒🏾', '👨‍🚒🏿', '👩‍✈️🏾', '👩‍✈️🏿', '👨‍✈️🏾', '👨‍✈️🏿',
    '👩‍🚀🏾', '👩‍🚀🏿', '👨‍🚀🏾', '👨‍🚀🏿', '👩‍⚖️🏾', '👩‍⚖️🏿', '👨‍⚖️🏾', '👨‍⚖️🏿', '👰🏾', '👰🏿',
    '🤵🏾', '🤵🏿', '👸🏾', '👸🏿', '🤴🏾', '🤴🏿', '🦸🏾', '🦸🏿', '🦸‍♀️🏾', '🦸‍♀️🏿',
    '🦸‍♂️🏾', '🦸‍♂️🏿', '🦹🏾', '🦹🏿', '🦹‍♀️🏾', '🦹‍♀️🏿', '🦹‍♂️🏾', '🦹‍♂️🏿', '🤶🏾', '🤶🏿',
    '🎅🏾', '🎅🏿', '🧙🏾', '🧙🏿', '🧙‍♀️🏾', '🧙‍♀️🏿', '🧙‍♂️🏾', '🧙‍♂️🏿', '🧝🏾', '🧝🏿',
    '🧝‍♀️🏾', '🧝‍♀️🏿', '🧝‍♂️🏾', '🧝‍♂️🏿', '🧛🏾', '🧛🏿', '🧛‍♀️🏾', '🧛‍♀️🏿', '🧛‍♂️🏾', '🧛‍♂️🏿',
    '🧜🏾', '🧜🏿', '🧜‍♀️🏾', '🧜‍♀️🏿', '🧜‍♂️🏾', '🧜‍♂️🏿', '🧞🏾', '🧞🏿', '🧞‍♀️🏾', '🧞‍♀️🏿',
    '🧞‍♂️🏾', '🧞‍♂️🏿', '🧟🏾', '🧟🏿', '🧟‍♀️🏾', '🧟‍♀️🏿', '🧟‍♂️🏾', '🧟‍♂️🏿', '💆🏾', '💆🏿',
    '💆‍♀️🏾', '💆‍♀️🏿', '💆‍♂️🏾', '💆‍♂️🏿', '💇🏾', '💇🏿', '💇‍♀️🏾', '💇‍♀️🏿', '💇‍♂️🏾', '💇‍♂️🏿',
    '🚶🏾', '🚶🏿', '🚶‍♀️🏾', '🚶‍♀️🏿', '🚶‍♂️🏾', '🚶‍♂️🏿', '🧍🏾', '🧍🏿', '🧍‍♀️🏾', '🧍‍♀️🏿',
    '🧍‍♂️🏾', '🧍‍♂️🏿', '🧎🏾', '🧎🏿', '🧎‍♀️🏾', '🧎‍♀️🏿', '🧎‍♂️🏾', '🧎‍♂️🏿', '🏃🏾', '🏃🏿',
    '🏃‍♀️🏾', '🏃‍♀️🏿', '🏃‍♂️🏾', '🏃‍♂️🏿', '💃🏾', '💃🏿', '🕺🏾', '🕺🏿', '🕴️🏾', '🕴️🏿',
    '👯🏾', '👯🏿', '👯‍♀️🏾', '👯‍♀️🏿', '👯‍♂️🏾', '👯‍♂️🏿', '🧘🏾', '🧘🏿', '🧘‍♀️🏾', '🧘‍♀️🏿',
    '🧘‍♂️🏾', '🧘‍♂️🏿', '🛀🏾', '🛀🏿', '🛌🏾', '🛌🏿', '👭🏾', '👭🏿', '👫🏾', '👫🏿',
    '👬🏾', '👬🏿', '💏🏾', '💏🏿', '💑🏾', '💑🏿', '👪🏾', '👪🏿',
    // Objects & Items
    '🧳', '🌂', '☂️', '🧵', '🧶', '👓', '🕶️', '🥽', '🥼', '🦺',
    '👔', '👕', '👖', '🧣', '🧤', '🧥', '🧦', '👗', '👘', '🥻',
    '🩱', '🩲', '🩳', '👙', '👚', '👛', '👜', '👝', '🛍️', '🎒',
    '👞', '👟', '🥾', '🥿', '👠', '👡', '🩰', '👢', '👑', '👒',
    '🎩', '🎓', '🧢', '⛑️', '📿', '💄', '💍', '💎',
    // Music & Entertainment
    '🔇', '🔈', '🔉', '🔊', '📢', '📣', '📯', '🔔', '🔕', '🎵',
    '🎶', '🎤', '🎧', '📻', '🎷', '🪗', '🎸', '🎹', '🎺', '🎻',
    '🪕', '🥁', '🪘', '🎼',
    // Games & Activities
    '🎮', '🕹️', '🎰', '🎲', '🧩', '♟️', '🃏', '🀄', '🎴', '🎭',
    '🖼️', '🎨',
  ];

  // Handle emoji picker open
  const handleOpenEmojiPicker = (event: React.MouseEvent<HTMLButtonElement>) => {
    setEmojiAnchorEl(event.currentTarget);
    setEmojiPickerOpen(true);
  };

  // Handle emoji picker close
  const handleCloseEmojiPicker = () => {
    setEmojiPickerOpen(false);
    setEmojiAnchorEl(null);
  };

  // Insert emoji into message
  const handleInsertEmoji = (emoji: string) => {
    setNewMessage((prev) => prev + emoji);
    handleCloseEmojiPicker();
  };

  // Handle file upload
  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !user) return;

    // Validate file type and size
    const maxSize = 10 * 1024 * 1024; // 10MB
    const allowedImageTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    const allowedVideoTypes = ['video/mp4', 'video/webm', 'video/quicktime'];
    const allowedFileTypes = [...allowedImageTypes, ...allowedVideoTypes];

    if (file.size > maxSize) {
      alert('File size must be less than 10MB');
      return;
    }

    if (!allowedFileTypes.includes(file.type)) {
      alert('File type not supported. Please use images or videos.');
      return;
    }

    try {
      setUploading(true);
      
      // For now, use data URLs directly since storage bucket may not exist
      // This stores the file as a base64 data URL in the database
      const reader = new FileReader();
      reader.onloadend = () => {
        const dataUrl = reader.result as string;
        const attachmentType = allowedImageTypes.includes(file.type) ? 'image' : 'video';
        setAttachmentPreview({ url: dataUrl, type: attachmentType });
        setUploading(false);
      };
      reader.onerror = () => {
        console.error('Error reading file');
        alert('Failed to read file');
        setUploading(false);
      };
      reader.readAsDataURL(file);
      
      // Optional: Try to upload to Supabase Storage if bucket exists
      // This is commented out since the bucket doesn't exist yet
      /*
      const fileExt = file.name.split('.').pop();
      const fileName = `chat/${user.id}/${Date.now()}.${fileExt}`;
      
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('media-assets')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: false,
        });

      if (uploadError) {
        // Fallback to data URL if storage fails
        console.warn('Storage upload failed, using data URL:', uploadError);
        const reader = new FileReader();
        reader.onloadend = () => {
          const dataUrl = reader.result as string;
          const attachmentType = allowedImageTypes.includes(file.type) ? 'image' : 'video';
          setAttachmentPreview({ url: dataUrl, type: attachmentType });
        };
        reader.readAsDataURL(file);
        setUploading(false);
        return;
      }

      // Get public URL
      const { data: urlData } = supabase.storage
        .from('media-assets')
        .getPublicUrl(fileName);

      const attachmentType = allowedImageTypes.includes(file.type) ? 'image' : 'video';
      setAttachmentPreview({ url: urlData.publicUrl, type: attachmentType });
      */
    } catch (error) {
      console.error('Error uploading file:', error);
      alert('Failed to upload file');
      setUploading(false);
    } finally {
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    }
  };

  // Send message with attachment
  const handleSendMessage = async () => {
    if ((!newMessage.trim() && !attachmentPreview) || !user || sending) return;

    // SECURITY: Sanitize message before sending to prevent XSS
    const rawMessageText = newMessage || (attachmentPreview ? '📎 Attachment' : '');
    const sanitizedMessageText = sanitizeText(rawMessageText.trim());
    
    if (!sanitizedMessageText && !attachmentPreview) {
      alert('Invalid message content. Please try again.');
      return;
    }

    const messageText = sanitizedMessageText || (attachmentPreview ? '📎 Attachment' : '');
    const tempId = `temp-${Date.now()}`;
    
    // Optimistically add message immediately for instant feedback
    const optimisticMessage: ChatMessage = {
      id: tempId,
      user_id: user.id,
      message: messageText,
      attachment_url: attachmentPreview?.url,
      attachment_type: attachmentPreview?.type,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      fighter_profile: fighterProfile ? {
        id: fighterProfile.id,
        name: fighterProfile.name,
        handle: fighterProfile.handle,
      } : undefined,
    };

    // Add optimistic message immediately using startTransition
    startTransition(() => {
      setMessages((prev) => {
        // Optimize: if message is newest, just append (no sort needed)
        const lastMessage = prev[prev.length - 1];
        const isNewest = !lastMessage || 
          new Date(optimisticMessage.created_at).getTime() >= 
          new Date(lastMessage.created_at).getTime();
        
        if (isNewest) {
          return [...prev, optimisticMessage];
        }
        
        // Only sort if not newest
        const updated = [...prev, optimisticMessage];
        return updated.sort((a, b) => 
          new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
        );
      });
    });
    
    // Clear input immediately
    setNewMessage('');
    setAttachmentPreview(null);
    
    // Scroll to bottom immediately
    setTimeout(() => {
      scrollToBottom();
    }, 100);

    try {
      setSending(true);
      const sentMessage = await chatService.sendMessage(
        messageText,
        user.id,
        attachmentPreview?.url,
        attachmentPreview?.type
      );
      
      // Replace optimistic message with real message from server
      startTransition(() => {
        setMessages((prev) => {
          // Remove the temporary message
          const filtered = prev.filter((m) => m.id !== tempId);
          // Add the real message (real-time subscription will also add it, but this ensures it's there)
          // Optimize: check if it's newest before sorting
          const lastMessage = filtered[filtered.length - 1];
          const isNewest = !lastMessage || 
            new Date(sentMessage.created_at).getTime() >= 
            new Date(lastMessage.created_at).getTime();
          
          if (isNewest) {
            return [...filtered, sentMessage];
          }
          
          const updated = [...filtered, sentMessage];
          return updated.sort((a, b) => 
            new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
          );
        });
      });
      
      // Scroll to bottom after real message is added
      setTimeout(() => {
        scrollToBottom();
      }, 100);
    } catch (error: any) {
      console.error('Error sending message:', error);
      // Remove optimistic message on error
      setMessages((prev) => prev.filter((m) => m.id !== tempId));
      // Restore input on error (use original unsanitized text for user to see what they typed)
      setNewMessage(newMessage);
      if (attachmentPreview) {
        setAttachmentPreview(attachmentPreview);
      }
      alert('Failed to send message: ' + (error.message || 'Unknown error'));
    } finally {
      setSending(false);
    }
  };

  // Format timestamp
  const formatTime = (timestamp: string) => {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);

    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    if (hours < 24) return `${hours}h ago`;
    if (days < 7) return `${days}d ago`;
    return date.toLocaleDateString();
  };

  // Get display name for a message
  // SECURITY: Sanitize display names to prevent XSS
  const getDisplayName = (message: ChatMessage) => {
    let displayName = 'Unknown User';
    if (message.fighter_profile?.name) {
      displayName = message.fighter_profile.name;
    } else if (message.user?.email) {
      displayName = message.user.email.split('@')[0];
    }
    // SECURITY: Sanitize display name before returning
    return sanitizeText(displayName) || 'Unknown User';
  };

  // Load messages on mount
  useEffect(() => {
    loadMessages();
  }, []);

  // Scroll to bottom when messages change (only if at bottom)
  useEffect(() => {
    if (isAtBottom && messages.length > 0) {
      scrollToBottom();
    }
  }, [messages, isAtBottom]);

  // Initial check if at bottom
  useEffect(() => {
    const container = messagesContainerRef.current;
    if (container) {
      checkIfAtBottom();
    }
  }, []);

  // Set up real-time subscription for chat messages
  useEffect(() => {
    if (!user) return; // Don't subscribe if user is not logged in

    // Debounce queue for batching rapid updates
    let updateQueue: Array<{ type: string; payload: any }> = [];
    let debounceTimer: NodeJS.Timeout | null = null;
    const DEBOUNCE_DELAY = 150; // Batch updates within 150ms to reduce handler time

    // Helper function to process individual updates
    const processUpdate = async (eventType: string, payload: any) => {
      if (eventType === 'INSERT') {
        // New message added - fetch the full message with profile
        const newMessage = payload.new as ChatMessage;
        
        try {
          // Fetch fighter profile for the new message
          const { data: profile } = await supabase
            .from('fighter_profiles')
            .select('id, name, handle')
            .eq('user_id', newMessage.user_id)
            .maybeSingle();

          const messageWithProfile: ChatMessage = {
            ...newMessage,
            fighter_profile: profile || undefined,
          };

          // Use startTransition for state updates to prevent blocking
          startTransition(() => {
            setMessages((prev) => {
              // Check if message already exists (by real ID) to prevent duplicates
              const existingIndex = prev.findIndex((m) => m.id === messageWithProfile.id);
              if (existingIndex !== -1) {
                // Message already exists, update it (in case profile was missing)
                const updated = [...prev];
                updated[existingIndex] = messageWithProfile;
                // Use a more efficient sort - only if needed
                const needsSort = updated.length > 1 && 
                  new Date(updated[existingIndex].created_at).getTime() < 
                  new Date(updated[existingIndex - 1]?.created_at || 0).getTime();
                return needsSort 
                  ? updated.sort((a, b) => 
                      new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
                    )
                  : updated;
              }
              
              // Remove any temporary optimistic messages for the same user/content
              // This handles the case where an optimistic message was added
              const filtered = prev.filter((m) => 
                !(m.id.startsWith('temp-') && 
                  m.user_id === messageWithProfile.user_id &&
                  m.message === messageWithProfile.message)
              );
              
              // Add new message - if it's the newest, just append (no sort needed)
              const lastMessage = filtered[filtered.length - 1];
              const isNewest = !lastMessage || 
                new Date(messageWithProfile.created_at).getTime() >= 
                new Date(lastMessage.created_at).getTime();
              
              if (isNewest) {
                return [...filtered, messageWithProfile];
              }
              
              // Only sort if message is not newest
              const updated = [...filtered, messageWithProfile];
              return updated.sort((a, b) => 
                new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
              );
            });
            
            // Scroll to bottom after a brief delay to ensure DOM has updated
            setTimeout(() => {
              if (isAtBottom) {
                scrollToBottom();
              }
            }, 100);
          });
        } catch (error) {
          console.error('Error fetching profile for new message:', error);
          // Still add the message without profile
          startTransition(() => {
            setMessages((prev) => {
              const existingIndex = prev.findIndex((m) => m.id === newMessage.id);
              if (existingIndex !== -1) {
                // Message already exists, update it
                const updated = [...prev];
                updated[existingIndex] = newMessage;
                return updated;
              }
              
              // Remove any temporary optimistic messages
              const filtered = prev.filter((m) => 
                !(m.id.startsWith('temp-') && 
                  m.user_id === newMessage.user_id &&
                  m.message === newMessage.message)
              );
              
              // Add new message - optimize by checking if it's newest
              const lastMessage = filtered[filtered.length - 1];
              const isNewest = !lastMessage || 
                new Date(newMessage.created_at).getTime() >= 
                new Date(lastMessage.created_at).getTime();
              
              return isNewest 
                ? [...filtered, newMessage]
                : [...filtered, newMessage].sort((a, b) => 
                    new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
                  );
            });
            
            setTimeout(() => {
              if (isAtBottom) {
                scrollToBottom();
              }
            }, 100);
          });
        }
      } else if (eventType === 'UPDATE') {
            // Message updated - fetch the full updated message with profile
            const updatedMessage = payload.new as ChatMessage;
            
            try {
              // Fetch fighter profile for the updated message
              const { data: profile } = await supabase
                .from('fighter_profiles')
                .select('id, name, handle')
                .eq('user_id', updatedMessage.user_id)
                .maybeSingle();

              const messageWithProfile: ChatMessage = {
                ...updatedMessage,
                fighter_profile: profile || undefined,
              };

              // Use startTransition for state updates to prevent blocking
              startTransition(() => {
                setMessages((prev) => {
                  return prev.map((msg) =>
                    msg.id === messageWithProfile.id ? messageWithProfile : msg
                  );
                });

                // If editing this message, exit edit mode
                if (editingMessageIdRef.current === updatedMessage.id) {
                  setEditingMessageId(null);
                  setEditText('');
                }
              });
            } catch (error) {
              console.error('Error fetching profile for updated message:', error);
              // Still update the message without profile
              startTransition(() => {
                setMessages((prev) => {
                  return prev.map((msg) =>
                    msg.id === updatedMessage.id ? updatedMessage : msg
                  );
                });

                // If editing this message, exit edit mode
                if (editingMessageIdRef.current === updatedMessage.id) {
                  setEditingMessageId(null);
                  setEditText('');
                }
              });
            }
          } else if (eventType === 'DELETE') {
            // Message deleted - remove it from the list
            const deletedMessage = payload.old as ChatMessage;
            startTransition(() => {
              setMessages((prev) =>
                prev.filter((msg) => msg.id !== deletedMessage.id)
              );

              // If editing this message, exit edit mode
              if (editingMessageIdRef.current === deletedMessage.id) {
                setEditingMessageId(null);
                setEditText('');
              }
            });
          }
        };

        // Process all queued updates in a single batch
        const processUpdateQueue = () => {
          if (updateQueue.length === 0) return;

          // Process all queued updates
          const updates = [...updateQueue];
          updateQueue = [];
          
          // Defer processing to next event loop tick to avoid blocking
          // This ensures the handler returns quickly
          setTimeout(() => {
            // Use startTransition to mark this as non-urgent
            startTransition(() => {
              // Process updates asynchronously to avoid blocking
              (async () => {
                // Batch profile fetches for INSERT operations
                const insertUpdates = updates.filter(u => u.type === 'INSERT');
                const otherUpdates = updates.filter(u => u.type !== 'INSERT');
                
                // Batch fetch profiles for all INSERT messages at once
                if (insertUpdates.length > 0) {
                  const userIds = new Set(insertUpdates.map(u => u.payload.new?.user_id).filter(Boolean));
                  const profileMap = new Map<string, any>();
                  
                  // Fetch all profiles in parallel
                  if (userIds.size > 0) {
                    const { data: profiles } = await supabase
                      .from('fighter_profiles')
                      .select('id, name, handle, user_id')
                      .in('user_id', Array.from(userIds));
                    
                    if (profiles) {
                      profiles.forEach(profile => {
                        profileMap.set(profile.user_id, profile);
                      });
                    }
                  }
                  
                  // Process INSERT updates with cached profiles
                  for (const update of insertUpdates) {
                    const newMessage = update.payload.new as ChatMessage;
                    const profile = profileMap.get(newMessage.user_id);
                    
                    const messageWithProfile: ChatMessage = {
                      ...newMessage,
                      fighter_profile: profile || undefined,
                    };
                    
                    startTransition(() => {
                      setMessages((prev) => {
                        const existingIndex = prev.findIndex((m) => m.id === messageWithProfile.id);
                        if (existingIndex !== -1) {
                          const updated = [...prev];
                          updated[existingIndex] = messageWithProfile;
                          return updated;
                        }
                        
                        const filtered = prev.filter((m) => 
                          !(m.id.startsWith('temp-') && 
                            m.user_id === messageWithProfile.user_id &&
                            m.message === messageWithProfile.message)
                        );
                        
                        const lastMessage = filtered[filtered.length - 1];
                        const isNewest = !lastMessage || 
                          new Date(messageWithProfile.created_at).getTime() >= 
                          new Date(lastMessage.created_at).getTime();
                        
                        if (isNewest) {
                          return [...filtered, messageWithProfile];
                        }
                        
                        const updated = [...filtered, messageWithProfile];
                        return updated.sort((a, b) => 
                          new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
                        );
                      });
                      
                      setTimeout(() => {
                        if (isAtBottom) {
                          scrollToBottom();
                        }
                      }, 50);
                    });
                  }
                }
                
                // Process other updates (UPDATE, DELETE) normally
                for (const update of otherUpdates) {
                  await processUpdate(update.type, update.payload);
                }
              })();
            });
          }, 0);
        };

        const channel = supabase
          .channel('chat_messages_changes')
          .on(
            'postgres_changes',
            {
              event: '*',
              schema: 'public',
              table: 'chat_messages',
            },
            (payload) => {
              // Queue the update instead of processing immediately
              // This batches rapid updates and reduces performance warnings
              // Use requestAnimationFrame to ensure handler returns immediately
              requestAnimationFrame(() => {
                updateQueue.push({ type: payload.eventType, payload });
                
                // Clear existing timer and set a new one
                if (debounceTimer) {
                  clearTimeout(debounceTimer);
                }
                
                // Process queue after debounce delay
                debounceTimer = setTimeout(() => {
                  processUpdateQueue();
                }, DEBOUNCE_DELAY);
              });
            }
          )
          .subscribe();

    return () => {
      console.log('Unsubscribing from chat messages');
      supabase.removeChannel(channel);
    };
  }, [user]);

  // Handle Enter key to send message
  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      // Defer to avoid blocking the keypress handler
      setTimeout(() => {
        handleSendMessage();
      }, 0);
    }
  };

  return (
    <>
      {/* Background Image Layer - Fixed position behind everything */}
      <Box
        component="div"
        sx={{
          backgroundImage: boxingGymBg ? `url("${boxingGymBg}")` : 'none',
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          backgroundRepeat: 'no-repeat',
          backgroundAttachment: 'fixed',
          minHeight: '100vh',
          width: '100vw',
          position: 'fixed',
          top: 0,
          left: 0,
          zIndex: -1,
          display: 'block',
        }}
      />
      <Box 
        sx={{ 
          maxWidth: 1200, 
          mx: 'auto', 
          height: 'calc(100vh - 100px)', 
          position: 'relative',
          zIndex: 1,
        }}
      >
        <Card 
          sx={{ 
            height: '100%', 
            display: 'flex', 
            flexDirection: 'column', 
            overflow: 'hidden',
            backgroundColor: 'rgba(255, 255, 255, 0.9)',
            backdropFilter: 'blur(3px)',
            position: 'relative',
          }}
        >
        <CardContent sx={{ flex: 1, display: 'flex', flexDirection: 'column', p: 0, minHeight: 0 }}>
          {/* Header */}
          <Box
            sx={{
              p: 2,
              borderBottom: 1,
              borderColor: 'divider',
              display: 'flex',
              alignItems: 'center',
              gap: 1,
            }}
          >
            <Forum color="primary" />
            <Typography variant="h5" component="h1">
              League Chat Room
            </Typography>
            <Chip
              label={`${messages.length} messages`}
              size="small"
              color="primary"
              variant="outlined"
            />
          </Box>

          {/* Messages Container */}
          <Box
            ref={messagesContainerRef}
            onScroll={handleScroll}
            sx={{
              flex: 1,
              overflowY: 'auto',
              overflowX: 'hidden',
              p: 2,
              display: 'flex',
              flexDirection: 'column',
              gap: 1,
              position: 'relative',
              minHeight: 0, // Important for flex scrolling
              // Ensure scrollbar is visible
              '&::-webkit-scrollbar': {
                width: '12px',
              },
              '&::-webkit-scrollbar-track': {
                background: 'rgba(0, 0, 0, 0.05)',
                borderRadius: '6px',
              },
              '&::-webkit-scrollbar-thumb': {
                background: 'rgba(0, 0, 0, 0.3)',
                borderRadius: '6px',
                '&:hover': {
                  background: 'rgba(0, 0, 0, 0.5)',
                },
              },
              // Firefox scrollbar
              scrollbarWidth: 'thin',
              scrollbarColor: 'rgba(0, 0, 0, 0.3) rgba(0, 0, 0, 0.05)',
            }}
          >
            {loadingOlder && (
              <Box sx={{ display: 'flex', justifyContent: 'center', p: 2 }}>
                <CircularProgress size={24} />
                <Typography variant="caption" sx={{ ml: 1, alignSelf: 'center' }}>
                  Loading older messages...
                </Typography>
              </Box>
            )}
            {!hasMoreMessages && messages.length > 0 && (
              <Alert severity="info" sx={{ mb: 1 }}>
                No more older messages
              </Alert>
            )}
            <div ref={messagesStartRef} />
            {loading ? (
              <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
                <CircularProgress />
              </Box>
            ) : messages.length === 0 ? (
              <Alert severity="info">No messages yet. Be the first to say something!</Alert>
            ) : (
              messages.map((message) => {
                const isOwnMessage = user && message.user_id === user.id;
                const canEditMessage = canEdit(message);
                const canDeleteMessage = canDelete(message);

                return (
                  <Paper
                    key={message.id}
                    elevation={1}
                    sx={{
                      p: 1.5,
                      maxWidth: '70%',
                      ml: isOwnMessage ? 'auto' : 0,
                      mr: isOwnMessage ? 0 : 'auto',
                      backgroundColor: isOwnMessage
                        ? 'primary.light'
                        : 'background.paper',
                      position: 'relative',
                    }}
                  >
                    {editingMessageId === message.id ? (
                      <Box sx={{ display: 'flex', gap: 1, alignItems: 'flex-start' }}>
                        <TextField
                          fullWidth
                          multiline
                          value={editText}
                          onChange={(e) => setEditText(e.target.value)}
                          onKeyPress={(e) => {
                            if (e.key === 'Enter' && !e.shiftKey) {
                              e.preventDefault();
                              handleSaveEdit(message.id);
                            }
                          }}
                          autoFocus
                          size="small"
                        />
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.5 }}>
                          <IconButton
                            size="small"
                            color="primary"
                            onClick={() => handleSaveEdit(message.id)}
                          >
                            <Check fontSize="small" />
                          </IconButton>
                          <IconButton
                            size="small"
                            onClick={handleCancelEdit}
                          >
                            <Close fontSize="small" />
                          </IconButton>
                        </Box>
                      </Box>
                    ) : (
                      <>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
                          <Avatar
                            sx={{
                              width: 32,
                              height: 32,
                              bgcolor: isOwnMessage ? 'primary.dark' : 'secondary.main',
                            }}
                          >
                            {getDisplayName(message).charAt(0).toUpperCase()}
                          </Avatar>
                          <Typography variant="subtitle2" fontWeight="bold">
                            {getDisplayName(message)}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {formatTime(message.created_at)}
                          </Typography>
                          <Box sx={{ ml: 'auto', display: 'flex', gap: 0.5 }}>
                            {canEdit(message) && (
                              <Tooltip title="Edit message">
                                <IconButton
                                  size="small"
                                  onClick={() => handleStartEdit(message)}
                                >
                                  <Edit fontSize="small" />
                                </IconButton>
                              </Tooltip>
                            )}
                            {canDelete(message) && (
                              <Tooltip title="Delete message">
                                <IconButton
                                  size="small"
                                  color="error"
                                  onClick={() => handleDeleteMessage(message.id)}
                                >
                                  <Delete fontSize="small" />
                                </IconButton>
                              </Tooltip>
                            )}
                          </Box>
                        </Box>
                        <Typography 
                          variant="body1" 
                          sx={{ 
                            wordBreak: 'break-word',
                            whiteSpace: 'pre-wrap',
                            fontFamily: 'system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"'
                          }}
                        >
                          {renderMessageText(message.message)}
                        </Typography>
                        {message.attachment_url && (
                          <Box sx={{ mt: 1 }}>
                            {message.attachment_type === 'image' && (
                              <img
                                src={message.attachment_url}
                                alt="Attachment"
                                style={{
                                  maxWidth: '100%',
                                  maxHeight: '400px',
                                  borderRadius: '8px',
                                  cursor: 'pointer',
                                }}
                                onClick={() => window.open(message.attachment_url, '_blank')}
                              />
                            )}
                            {message.attachment_type === 'video' && (
                              <video
                                src={message.attachment_url}
                                controls
                                style={{
                                  maxWidth: '100%',
                                  maxHeight: '400px',
                                  borderRadius: '8px',
                                }}
                              />
                            )}
                            {message.attachment_type === 'file' && (
                              <Box
                                sx={{
                                  display: 'flex',
                                  alignItems: 'center',
                                  gap: 1,
                                  p: 1,
                                  bgcolor: 'action.hover',
                                  borderRadius: 1,
                                }}
                              >
                                <AttachFile />
                                <a
                                  href={message.attachment_url}
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  style={{ textDecoration: 'none', color: 'inherit' }}
                                >
                                  Download File
                                </a>
                              </Box>
                            )}
                          </Box>
                        )}
                      </>
                    )}
                  </Paper>
                );
              })
            )}
            <div ref={messagesEndRef} />
          </Box>
          
          {/* Scroll to bottom button - positioned relative to Card */}
          {!isAtBottom && messages.length > 0 && (
            <Box
              sx={{
                position: 'absolute',
                bottom: 120,
                right: 40,
                zIndex: 1000,
              }}
            >
              <Tooltip title="Scroll to bottom">
                <IconButton
                  color="primary"
                  onClick={scrollToBottom}
                  sx={{
                    bgcolor: 'background.paper',
                    boxShadow: 3,
                    '&:hover': {
                      bgcolor: 'primary.main',
                      color: 'white',
                    },
                  }}
                >
                  <KeyboardArrowDown />
                </IconButton>
              </Tooltip>
            </Box>
          )}

          {/* Input Area */}
          <Box
            sx={{
              p: 2,
              borderTop: 1,
              borderColor: 'divider',
            }}
          >
            {attachmentPreview && (
              <Box sx={{ mb: 1, position: 'relative', display: 'inline-block' }}>
                {attachmentPreview.type === 'image' && (
                  <img
                    src={attachmentPreview.url}
                    alt="Preview"
                    style={{
                      maxWidth: '200px',
                      maxHeight: '200px',
                      borderRadius: '8px',
                    }}
                  />
                )}
                {attachmentPreview.type === 'video' && (
                  <video
                    src={attachmentPreview.url}
                    style={{
                      maxWidth: '200px',
                      maxHeight: '200px',
                      borderRadius: '8px',
                    }}
                    controls
                  />
                )}
                <IconButton
                  size="small"
                  onClick={() => setAttachmentPreview(null)}
                  sx={{
                    position: 'absolute',
                    top: 0,
                    right: 0,
                    bgcolor: 'background.paper',
                  }}
                >
                  <Close fontSize="small" />
                </IconButton>
              </Box>
            )}
            <Box sx={{ display: 'flex', gap: 1, alignItems: 'flex-end' }}>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1, flex: 1 }}>
                <TextField
                  fullWidth
                  multiline
                  maxRows={4}
                  placeholder="Type your message... (Paste links to make them clickable, emojis work too! 😀)"
                  value={newMessage}
                  onChange={(e) => setNewMessage(e.target.value)}
                  onKeyPress={handleKeyPress}
                  disabled={sending || uploading || !user}
                  sx={{
                    '& .MuiInputBase-input': {
                      fontFamily: 'system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"'
                    }
                  }}
                />
                <Box sx={{ display: 'flex', gap: 0.5 }}>
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*,video/*"
                    onChange={handleFileSelect}
                    style={{ display: 'none' }}
                  />
                  <Tooltip title="Upload image or video">
                    <IconButton
                      size="small"
                      onClick={() => fileInputRef.current?.click()}
                      disabled={uploading || !user}
                    >
                      {uploading ? <CircularProgress size={20} /> : <Image />}
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Links are automatically detected and clickable - just paste or type them!">
                    <span>
                      <IconButton size="small" disabled>
                        <InsertLink />
                      </IconButton>
                    </span>
                  </Tooltip>
                  <Tooltip title="Click to add emojis">
                    <IconButton 
                      size="small" 
                      onClick={handleOpenEmojiPicker}
                      disabled={!user}
                    >
                      <EmojiEmotions />
                    </IconButton>
                  </Tooltip>
                </Box>
              </Box>
              <Button
                variant="contained"
                color="primary"
                startIcon={sending ? <CircularProgress size={20} /> : <Send />}
                onClick={handleSendMessage}
                disabled={(!newMessage.trim() && !attachmentPreview) || sending || uploading || !user}
                sx={{ minWidth: 100 }}
              >
                {sending ? 'Sending...' : 'Send'}
              </Button>
            </Box>
            {!user && (
              <Alert severity="warning" sx={{ mt: 1 }}>
                Please log in to send messages
              </Alert>
            )}
          </Box>

          {/* Emoji Picker Popover */}
          <Popover
            open={emojiPickerOpen}
            anchorEl={emojiAnchorEl}
            onClose={handleCloseEmojiPicker}
            anchorOrigin={{
              vertical: 'top',
              horizontal: 'left',
            }}
            transformOrigin={{
              vertical: 'bottom',
              horizontal: 'left',
            }}
            PaperProps={{
              sx: {
                width: 300,
                maxHeight: 400,
                p: 2,
              }
            }}
          >
            <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 'bold' }}>
              Select an Emoji
            </Typography>
            <Box
              sx={{
                maxHeight: 350,
                overflowY: 'auto',
                display: 'flex',
                flexWrap: 'wrap',
                gap: 0.5,
              }}
            >
              {commonEmojis.map((emoji, index) => (
                <IconButton
                  key={index}
                  onClick={() => handleInsertEmoji(emoji)}
                  sx={{
                    fontSize: '24px',
                    width: 40,
                    height: 40,
                    '&:hover': {
                      bgcolor: 'action.hover',
                    },
                  }}
                >
                  {emoji}
                </IconButton>
              ))}
            </Box>
          </Popover>
        </CardContent>
      </Card>
    </Box>
    </>
  );
};

export default Social;

