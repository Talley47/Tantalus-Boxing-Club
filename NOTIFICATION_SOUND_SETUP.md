# Notification Sound Setup

## Audio File Location

To enable notification sounds, place your audio file in one of these locations:

1. **Recommended**: `tantalus-boxing-club/public/boxing-bell-signals-6115 (1).mp3`
2. Alternative: `tantalus-boxing-club/public/assets/boxing-bell-signals-6115 (1).mp3`

## Supported File Formats

The system will automatically try to find the file with these extensions:
- `.mp3` (recommended)
- `.mpeg`
- `.mpe`

## File Naming

The system looks for files named:
- `boxing-bell-signals-6115 (1).mp3` (with parentheses)
- `boxing-bell-signals-6115.mp3` (without parentheses)

## How It Works

- When a fighter receives a new notification (via real-time subscription), the sound will automatically play
- The sound volume is set to 70% to avoid being too loud
- If the file is not found, a warning will be logged to the console but the app will continue to work normally
- The sound will play for all notification types (@mentions, callouts, training camps, etc.)

## Testing

After placing the file, test by:
1. Having another fighter mention you in League Chat (@your_handle)
2. The sound should play automatically when the notification is received

