# The Book Loop — Supabase-connected version

## 1. Set up the database
In Supabase SQL Editor, run `schema.sql` once. It creates tables, row-level security policies, private book-cover storage, and parent-only moderation rules. Inspect the SQL before running it. **Do not put `schema.sql` into a public GitHub repository if you later add private operational details to it.**

## 2. Authentication
In Supabase Authentication > URL Configuration, set Site URL to `https://diellezw.github.io/the-book-loop/` and add the same URL to Redirect URLs. Enable email OTP/magic links. Supabase email sending limits apply; for a larger community configure custom SMTP. Do not invite minors to register without a parent-approved process.

## 3. Set up the adult administrator
Sign in to the website once using the adult's email address. In Supabase Authentication > Users, copy **that adult user's UUID**. In SQL Editor run:

```sql
insert into public.admins(user_id) values ('PASTE-ADULT-USER-UUID-HERE') on conflict do nothing;
```

Then sign out and sign in again. The **Parent admin** navigation will appear. Never put this UUID into browser code to grant access.

## 4. Upload website files
Replace the old `index.html`, `styles.css`, and `app.js` in the repository with these versions; add `config.js`. Upload the actual approved logo to `images/logo/book-loop-logo.png`. If you have a logo PNG under another name, rename it locally before uploading.

## 5. Safety and limitations
- All submissions require a signed-in account and remain pending until adult approval.
- Cover images are stored in a **private** Supabase Storage bucket; approved book images can be viewed via time-limited signed URLs.
- Anonymous users can see only approved books and reviews, not private requests.
- A public GitHub Pages site cannot safely contain service-role keys or database passwords. `config.js` contains only a publishable key.
- This first version intentionally **does not** automate credit accounting, verify physical drop-offs, provide private chat, collect home addresses, or expose user email addresses in public listings.
- Parent review for swap requests is basic; it does not yet reserve inventory or enforce a credit balance. Approval should not be interpreted as a confirmed physical exchange.
- Configure Supabase rate limits, bot protection/CAPTCHA, acceptable-use rules, and data retention before inviting a large public audience. Image moderation should be performed by an adult before approving a listing.
- Public registration by minors requires a clear guardian-led consent and safeguarding process appropriate to local laws.
- Instagram is a link placeholder. Replace the URL in `config.js` when the supervised account is ready. An automatic feed requires an additional supported integration.
