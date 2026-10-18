# The Book Loop — website prototype

A responsive, static prototype for a youth-led book swap and reading community.

## Run locally
Open `index.html` in a browser, or serve this directory with `python3 -m http.server 8000` and visit `http://localhost:8000`.

## Deploy
Upload these files to a new GitHub repository and deploy with GitHub Pages or Vercel (framework preset: Other; output directory: project root). No build command is needed.

## Included
- Mobile-first landing page, catalogue search and genre filters
- Book submission form and swap request form
- Moderated reading reviews
- Instagram placeholder and outbound link
- Parent-review **demo queue** with approve/reject and JSON export

## Important limitations
**This is a prototype, not a production-ready service.** Submissions and decisions exist only in each browser's `localStorage`, not on a server. They are not synchronized between visitors, and anyone on the same browser can see or modify the queue. Demo books are fictional inventory examples, not actual swap stock. Image selection records only the file name; it does not upload or save photos. Swap credits are not verified or awarded. The Instagram section is a placeholder, not a connected feed. Do not use this demo to collect personal information or arrange real swaps.

## Before public launch
1. Add a hosted database, secure authentication and parent-only authorization for moderation.
2. Add private image storage, size limits, image moderation, rate limiting and spam controls.
3. Replace sample stock with real, approved inventory and implement server-side credit and reservation transactions.
4. Establish guardian consent and safeguarding policies, with supervised pickup only and no public contact details.
5. Connect a parent-managed Instagram account using an approved Instagram embed/feed solution and update the Instagram URL.
6. Create a privacy notice, reporting process, and data retention/deletion controls.

## Files
- `index.html` — page layout and accessible forms
- `styles.css` — responsive visual design
- `app.js` — browser-only prototype logic
