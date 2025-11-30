import React, { useState, useEffect, useRef } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  TextField,
  Button,
  List,
  ListItem,
  ListItemButton,
  ListItemText,
  ListItemAvatar,
  Avatar,
  Divider,
  IconButton,
  Chip,
  CircularProgress,
  Alert,
  Paper,
  InputAdornment,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Autocomplete,
  Stack,
} from '@mui/material';
import {
  Send as SendIcon,
  Message as MessageIcon,
  Person as PersonIcon,
  Close as CloseIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import { fighterMessageService, Conversation, FighterDirectMessage, SendMessageRequest } from '../../services/fighterMessageService';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../services/supabase';

interface FighterDirectMessagesProps {
  fighterId: string;
}

const FighterDirectMessages: React.FC<FighterDirectMessagesProps> = ({ fighterId }) => {
  const { user } = useAuth();
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [selectedConversation, setSelectedConversation] = useState<Conversation | null>(null);
  const [messages, setMessages] = useState<FighterDirectMessage[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [unreadCount, setUnreadCount] = useState(0);
  const [newMessageDialogOpen, setNewMessageDialogOpen] = useState(false);
  const [selectedRecipient, setSelectedRecipient] = useState<{ user_id: string; name: string; handle: string } | null>(null);
  const [recipientOptions, setRecipientOptions] = useState<Array<{ user_id: string; name: string; handle: string; tier: string }>>([]);
  const [loadingRecipients, setLoadingRecipients] = useState(false);
  const [newMessageText, setNewMessageText] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Load conversations
  const loadConversations = async () => {
    try {
      setLoading(true);
      setError(null);
      const convos = await fighterMessageService.getConversations(fighterId);
      setConversations(convos);
      const unread = await fighterMessageService.getUnreadCount(fighterId);
      setUnreadCount(unread);
    } catch (err: any) {
      console.error('Error loading conversations:', err);
      setError(err.message || 'Failed to load conversations');
    } finally {
      setLoading(false);
    }
  };

  // Load messages for selected conversation
  const loadMessages = async (otherFighterId: string) => {
    try {
      setLoadingMessages(true);
      setError(null);
      const msgs = await fighterMessageService.getConversationMessages(fighterId, otherFighterId);
      setMessages(msgs);
      
      // Mark conversation as read
      await fighterMessageService.markConversationAsRead(fighterId, otherFighterId);
      
      // Reload conversations to update unread count
      await loadConversations();
      
      // Scroll to bottom
      setTimeout(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
      }, 100);
    } catch (err: any) {
      console.error('Error loading messages:', err);
      setError(err.message || 'Failed to load messages');
    } finally {
      setLoadingMessages(false);
    }
  };

  // Send message
  const handleSendMessage = async () => {
    if (!newMessage.trim() || !selectedConversation) return;

    try {
      setSending(true);
      setError(null);
      
      const request: SendMessageRequest = {
        recipient_id: selectedConversation.other_fighter_id,
        message: newMessage.trim(),
      };

      const sentMessage = await fighterMessageService.sendMessage(request, fighterId);
      
      // Add message to local state
      setMessages([...messages, sentMessage]);
      setNewMessage('');
      
      // Reload conversations to update last message
      await loadConversations();
      
      // Scroll to bottom
      setTimeout(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
      }, 100);
    } catch (err: any) {
      console.error('Error sending message:', err);
      setError(err.message || 'Failed to send message');
    } finally {
      setSending(false);
    }
  };

  // Send new message to a new recipient
  const handleSendNewMessage = async () => {
    if (!newMessageText.trim() || !selectedRecipient) return;

    try {
      setSending(true);
      setError(null);
      
      const request: SendMessageRequest = {
        recipient_id: selectedRecipient.user_id,
        message: newMessageText.trim(),
      };

      await fighterMessageService.sendMessage(request, fighterId);
      
      // Close dialog and reload conversations
      setNewMessageDialogOpen(false);
      setSelectedRecipient(null);
      setNewMessageText('');
      await loadConversations();
    } catch (err: any) {
      console.error('Error sending new message:', err);
      setError(err.message || 'Failed to send message');
    } finally {
      setSending(false);
    }
  };

  // Load recipients for new message
  const loadRecipients = async () => {
    try {
      setLoadingRecipients(true);
      const fighters = await fighterMessageService.getFightersForMessaging(fighterId);
      setRecipientOptions(fighters);
    } catch (err: any) {
      console.error('Error loading recipients:', err);
    } finally {
      setLoadingRecipients(false);
    }
  };

  // Select conversation
  const handleSelectConversation = (conversation: Conversation) => {
    setSelectedConversation(conversation);
    loadMessages(conversation.other_fighter_id);
  };

  // Real-time subscription for new messages
  useEffect(() => {
    if (!fighterId) return;

    loadConversations();

    // Subscribe to new messages
    const channel = supabase
      .channel(`fighter_messages_${fighterId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'fighter_direct_messages',
          filter: `recipient_id=eq.${fighterId}`,
        },
        (payload) => {
          console.log('New message received:', payload);
          loadConversations();
          if (selectedConversation && payload.new.sender_id === selectedConversation.other_fighter_id) {
            loadMessages(selectedConversation.other_fighter_id);
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fighterId]);

  // Auto-scroll to bottom when messages change
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    if (hours < 24) return `${hours}h ago`;
    if (days < 7) return `${days}d ago`;
    return date.toLocaleDateString();
  };

  return (
    <>
      <Card>
        <CardContent>
          <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
            <Box display="flex" alignItems="center" gap={1}>
              <MessageIcon sx={{ color: 'primary.main' }} />
              <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                Direct Messages
              </Typography>
              {unreadCount > 0 && (
                <Chip label={unreadCount} size="small" color="error" />
              )}
            </Box>
            <Button
              variant="contained"
              size="small"
              startIcon={<MessageIcon />}
              onClick={() => {
                setNewMessageDialogOpen(true);
                loadRecipients();
              }}
            >
              New Message
            </Button>
          </Box>
          <Divider sx={{ mb: 2 }} />

          {error && (
            <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
              {error}
            </Alert>
          )}

          {loading ? (
            <Box display="flex" justifyContent="center" p={3}>
              <CircularProgress />
            </Box>
          ) : (
            <Box sx={{ display: 'flex', gap: 2, height: '600px' }}>
              {/* Conversations List */}
              <Box sx={{ width: '300px', borderRight: 1, borderColor: 'divider', overflowY: 'auto' }}>
                {conversations.length === 0 ? (
                  <Box p={3} textAlign="center">
                    <Typography variant="body2" color="text.secondary">
                      No conversations yet. Start a new message!
                    </Typography>
                  </Box>
                ) : (
                  <List>
                    {conversations.map((conversation, index) => (
                      <React.Fragment key={conversation.other_fighter_id}>
                        <ListItem
                          disablePadding
                        >
                          <ListItemButton
                            selected={selectedConversation?.other_fighter_id === conversation.other_fighter_id}
                            onClick={() => handleSelectConversation(conversation)}
                          >
                          <ListItemAvatar>
                            <Avatar>
                              {conversation.other_fighter_name?.charAt(0) || '?'}
                            </Avatar>
                          </ListItemAvatar>
                          <ListItemText
                            primary={
                              <Box display="flex" alignItems="center" gap={1}>
                                <Typography variant="body1" fontWeight={conversation.unread_count > 0 ? 'bold' : 'normal'}>
                                  {conversation.other_fighter_name}
                                </Typography>
                                {conversation.unread_count > 0 && (
                                  <Chip label={conversation.unread_count} size="small" color="error" />
                                )}
                              </Box>
                            }
                            secondary={
                              <>
                                <Typography variant="caption" color="text.secondary" component="span" display="block" noWrap>
                                  @{conversation.other_fighter_handle}
                                </Typography>
                                {conversation.last_message && (
                                  <Typography variant="caption" color="text.secondary" component="span" display="block" noWrap>
                                    {conversation.last_message.message.substring(0, 30)}
                                    {conversation.last_message.message.length > 30 ? '...' : ''}
                                  </Typography>
                                )}
                                <Typography variant="caption" color="text.secondary" component="span" display="block">
                                  {conversation.last_message ? formatTime(conversation.last_message.created_at) : ''}
                                </Typography>
                              </>
                            }
                          />
                          </ListItemButton>
                        </ListItem>
                        {index < conversations.length - 1 && <Divider />}
                      </React.Fragment>
                    ))}
                  </List>
                )}
              </Box>

              {/* Messages View */}
              <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
                {selectedConversation ? (
                  <>
                    {/* Messages Header */}
                    <Box p={2} borderBottom={1} borderColor="divider">
                      <Typography variant="h6">
                        {selectedConversation.other_fighter_name}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        @{selectedConversation.other_fighter_handle}
                      </Typography>
                    </Box>

                    {/* Messages List */}
                    <Box sx={{ flex: 1, overflowY: 'auto', p: 2 }}>
                      {loadingMessages ? (
                        <Box display="flex" justifyContent="center" p={3}>
                          <CircularProgress />
                        </Box>
                      ) : messages.length === 0 ? (
                        <Box textAlign="center" p={3}>
                          <Typography variant="body2" color="text.secondary">
                            No messages yet. Start the conversation!
                          </Typography>
                        </Box>
                      ) : (
                        <Stack spacing={1}>
                          {messages.map((msg) => {
                            const isSent = msg.sender_id === fighterId;
                            return (
                              <Box
                                key={msg.id}
                                sx={{
                                  display: 'flex',
                                  justifyContent: isSent ? 'flex-end' : 'flex-start',
                                }}
                              >
                                <Paper
                                  sx={{
                                    p: 1.5,
                                    maxWidth: '70%',
                                    bgcolor: isSent ? 'primary.main' : 'grey.200',
                                    color: isSent ? 'white' : 'text.primary',
                                  }}
                                >
                                  <Typography variant="body2">{msg.message}</Typography>
                                  <Typography variant="caption" sx={{ opacity: 0.7, display: 'block', mt: 0.5 }}>
                                    {formatTime(msg.created_at)}
                                  </Typography>
                                </Paper>
                              </Box>
                            );
                          })}
                          <div ref={messagesEndRef} />
                        </Stack>
                      )}
                    </Box>

                    {/* Message Input */}
                    <Box p={2} borderTop={1} borderColor="divider">
                      <TextField
                        fullWidth
                        placeholder="Type a message..."
                        value={newMessage}
                        onChange={(e) => setNewMessage(e.target.value)}
                        onKeyPress={(e) => {
                          if (e.key === 'Enter' && !e.shiftKey) {
                            e.preventDefault();
                            handleSendMessage();
                          }
                        }}
                        disabled={sending}
                        InputProps={{
                          endAdornment: (
                            <InputAdornment position="end">
                              <IconButton
                                color="primary"
                                onClick={handleSendMessage}
                                disabled={!newMessage.trim() || sending}
                              >
                                <SendIcon />
                              </IconButton>
                            </InputAdornment>
                          ),
                        }}
                      />
                    </Box>
                  </>
                ) : (
                  <Box display="flex" alignItems="center" justifyContent="center" height="100%">
                    <Box textAlign="center">
                      <MessageIcon sx={{ fontSize: 64, color: 'text.secondary', mb: 2 }} />
                      <Typography variant="h6" color="text.secondary">
                        Select a conversation to start messaging
                      </Typography>
                    </Box>
                  </Box>
                )}
              </Box>
            </Box>
          )}
        </CardContent>
      </Card>

      {/* New Message Dialog */}
      <Dialog open={newMessageDialogOpen} onClose={() => setNewMessageDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>
          <Box display="flex" justifyContent="space-between" alignItems="center">
            <Typography variant="h6">New Message</Typography>
            <IconButton onClick={() => setNewMessageDialogOpen(false)} size="small">
              <CloseIcon />
            </IconButton>
          </Box>
        </DialogTitle>
        <DialogContent>
          <Box sx={{ mt: 2 }}>
            <Autocomplete
              options={recipientOptions}
              getOptionLabel={(option) => `${option.name} (@${option.handle})`}
              loading={loadingRecipients}
              value={selectedRecipient}
              onChange={(_, newValue) => setSelectedRecipient(newValue)}
              renderInput={(params) => (
                <TextField
                  {...params}
                  label="Select Fighter"
                  placeholder="Search for a fighter..."
                />
              )}
            />
            <TextField
              fullWidth
              multiline
              rows={4}
              label="Message"
              value={newMessageText}
              onChange={(e) => setNewMessageText(e.target.value)}
              sx={{ mt: 2 }}
              placeholder="Type your message..."
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setNewMessageDialogOpen(false)}>Cancel</Button>
          <Button
            variant="contained"
            onClick={handleSendNewMessage}
            disabled={!selectedRecipient || !newMessageText.trim() || sending}
            startIcon={<SendIcon />}
          >
            Send
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
};

export default FighterDirectMessages;

