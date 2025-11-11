# Instructions: Copy FB cover Undisputed.png to Public Folder

To make the background image work on the Home page, you need to manually copy the file:

**FROM:** `tantalus-boxing-club/src/FB cover Undisputed.png`  
**TO:** `tantalus-boxing-club/public/FB cover Undisputed.png`

After copying, refresh the page and the Home page will display `FB cover Undisputed.png` as the background image.

The code is configured to:
1. First try importing from `src/` folder (webpack processed)
2. Fall back to `/FB cover Undisputed.png` from public folder if import fails

Copying to the public folder ensures it works in both cases.

