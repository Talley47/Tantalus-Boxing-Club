# Instructions: Copy Canelo undisputed.png to Public Folder

To make the background image work on the Analytics page, you need to manually copy the file:

**FROM:** `tantalus-boxing-club/src/Canelo undisputed.png`  
**TO:** `tantalus-boxing-club/public/Canelo undisputed.png`

After copying, refresh the page and the Analytics page will display `Canelo undisputed.png` as the background image.

The code is configured to:
1. First try importing from `src/` folder (webpack processed)
2. Fall back to `/Canelo undisputed.png` from public folder if import fails

Copying to the public folder ensures it works in both cases.




