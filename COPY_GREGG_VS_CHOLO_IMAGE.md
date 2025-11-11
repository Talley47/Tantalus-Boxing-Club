# Instructions: Copy Gregg Vs Cholo.png to Public Folder

To make the background image work on the Matchmaking page, you may need to manually copy the file:

**FROM:** `tantalus-boxing-club/src/Gregg Vs Cholo.png`  
**TO:** `tantalus-boxing-club/public/Gregg Vs Cholo.png`

After copying, refresh the page and the Matchmaking page will display `Gregg Vs Cholo.png` as the background image.

The code is configured to:
1. First try importing from `src/` folder (webpack processed)
2. Fall back to `/Gregg Vs Cholo.png` from public folder if import fails

Copying to the public folder ensures it works in both cases.

