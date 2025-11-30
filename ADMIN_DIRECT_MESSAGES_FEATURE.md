# Admin Direct Messages Feature

## Overview
This feature allows Admins to send direct messages to fighters, which will appear in the fighter's "My Profile" section. This is primarily used to notify fighters that they have been selected for Live Events.

## Database Setup

### 1. Run the SQL Schema
Execute the SQL script in Supabase SQL Editor:

```sql
-- File: database/admin-direct-messages-schema.sql
```

This creates:
- `admin_direct_messages` table
- RLS (Row Level Security) policies
- Indexes for performance
- Triggers for `updated_at` timestamp

### 2. Verify Table Creation
After running the SQL, verify the table exists:

```sql
SELECT table_name FROM information_schema.tables 
WHERE table_name = 'admin_direct_messages';
```

## Features

### Admin Panel
1. Navigate to **Admin Panel** → **System Settings**
2. Click **"Send Direct Messages to Fighters"** button
3. The dialog opens with:
   - **Fighter Selection**: Multi-select autocomplete to choose fighters
   - **Subject**: Message subject (default: "Live Event Selection")
   - **Message Type**: 
     - Live Event Selection
     - Tournament Selection
     - General
     - Announcement
   - **Event Name**: Optional event name (e.g., "King of the Hill Event")
   - **Event Type**: Live Event or Tournament (if applicable)
   - **Message**: The message content

4. **Send Options**:
   - Single message to one fighter
   - Bulk message to multiple fighters at once

5. **Message History**: View all sent messages with:
   - Fighter name and handle
   - Subject and type
   - Event name (if provided)
   - Read/Unread status
   - Delete functionality

### Fighter Profile
1. Navigate to **My Profile** (or `/profile`)
2. **"Messages from Admin"** section appears at the top (after Stats Cards)
3. Features:
   - Unread message count badge
   - "Mark All as Read" button (if unread messages exist)
   - Individual message cards showing:
     - Subject with type badge
     - Event name (if provided)
     - Message content
     - Timestamp
     - "Mark as Read" button for unread messages
   - Visual distinction: Unread messages have a colored left border

## Message Types

1. **Live Event Selection**: Notify fighters selected for live events
2. **Tournament Selection**: Notify fighters selected for tournaments
3. **General**: General admin messages
4. **Announcement**: Important announcements

## Security (RLS Policies)

- **Admins**: Can view all messages, send messages, and delete messages
- **Fighters**: Can only view their own messages and mark them as read
- All operations require authentication

## API Service

The `adminMessageService` provides:

- `getAllMessages()`: Get all messages (admin only)
- `getFighterMessages(fighterId)`: Get messages for a specific fighter
- `getUnreadCount(fighterId)`: Get unread message count
- `sendMessage(request)`: Send a single message
- `sendBulkMessage(fighterIds, request)`: Send messages to multiple fighters
- `markAsRead(messageId)`: Mark a message as read
- `markAllAsRead(fighterId)`: Mark all messages as read for a fighter
- `deleteMessage(messageId)`: Delete a message (admin only)
- `getFightersForSelection()`: Get list of fighters for selection (excludes admins)

## Files Created/Modified

### New Files
1. `database/admin-direct-messages-schema.sql` - Database schema
2. `src/services/adminMessageService.ts` - Service for message operations
3. `src/components/Admin/AdminDirectMessages.tsx` - Admin UI component

### Modified Files
1. `src/components/Admin/AdminPanel.tsx` - Added button to open messages dialog
2. `src/components/FighterProfile/FighterProfile.tsx` - Added messages display section

## Usage Example

### Admin Sending a Message

1. Go to Admin Panel
2. Click "Send Direct Messages to Fighters"
3. Select fighters from the dropdown (can select multiple)
4. Enter subject: "Live Event Selection"
5. Select message type: "Live Event Selection"
6. Enter event name: "King of the Hill Event"
7. Select event type: "Live Event"
8. Enter message: "Congratulations! You have been selected to participate in the King of the Hill Event..."
9. Click "Send Message"

### Fighter Viewing Messages

1. Go to My Profile
2. Scroll to "Messages from Admin" section
3. View unread messages (highlighted with colored border)
4. Click "Mark as Read" on individual messages or "Mark All as Read"
5. Messages remain visible after being read

## Notes

- Messages are only visible to the fighter they were sent to
- Unread messages are highlighted with a colored left border
- The unread count badge appears next to the section title
- Admins can delete messages from the message history
- The `event_name` column is optional and can be added later if needed (the code handles its absence gracefully)

