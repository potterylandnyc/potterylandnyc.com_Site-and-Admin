# CLAUDE.md — Pottery & Glass Land website + admin

Read this and claude/style-guide.md before doing anything. Keep answers short, in plain English (I'm not a coder).

## What it is
- potterylandnyc.com — public website: homepage (hours, classes, inquiry form), class booking pages, Sunday Club registration, privacy/terms.
- admin.potterylandnyc.com — staff admin: classes, bookings, Sunday Club, inquiries, website settings.
- Shares one Supabase backend with the order app (app.potterylandnyc.com — separate repo, its own CLAUDE.md).

## Stack
- Plain HTML/CSS/JS. No build step, no framework, no npm.
- Supabase (project `pehllmkuvrccfuvcskvj`): database, auth, Edge Functions (emails, Google hours sync), pg_cron.
- Cloudflare Workers with static assets — one per site, each with its own `wrangler.toml`. Admin is behind Cloudflare Access (Google login).
- Email via Mailtrap (from Edge Functions). CDN: supabase-js v2.

## Files
- `potterylandnyc.com/public/` — the public site:
  - `index.html` + `index.css` — homepage
  - `class.html` + `class.css` — ONE booking page for every class (/classes/<slug>, via `_redirects`)
  - `classes.html` + `classes.css` — class list
  - `sunday-club.html` + `sunday-club.css`
  - `privacy.html`, `terms.html` + `legal.css`
  - `styles.css` (site-wide) and `registration.css` (shared by landing/registration pages)
  - `_redirects`, `_headers`, `contact-*.vcf` (WhatsApp "save our number" cards), `images/`
- `admin.potterylandnyc.com/public/index.html` — the whole admin (markup, styles, JS).
- `claude/style-guide.md` — CSS system, phone-field pattern, page rules. Follow it; don't duplicate it here.
- `Claude outputs/` — throwaway previews. Not deployed.

## Main Supabase tables
settings (website keys start `website_`), branches (+ public view `branches_public`), customers, class_types, staff_allowlist, pgl_classes, pgl_pricing, pgl_discounts, pgl_inquiries, pgl_programs, pgl_program_offerings, pgl_signups, pgl_signup_payments, pgl_wheel_bookings (all class bookings), pgl_wheel_payments, pgl_campaigns, pgl_ref_counters.
Edge Functions: notify-inquiry, notify-signup, notify-wheel, sc-complete, inquiry-digest, sync-google-hours (hours/address/phone from Google Business Profile, every 6 hrs).

## Auth / security
- Public site uses the publishable key (fine to expose) with narrow RLS: anon can only read what the site shows (e.g. `website_%` settings, `branches_public`) and insert its own forms.
- Admin staff sign in with Google; staff-only access = email in `staff_allowlist` (`is_staff()` in RLS).
- Never put a service/secret key in a page. Never add "allow all / anon" policies.
- Edge Functions only email addresses stored on the record, never one passed in the request.
- New tables: enable RLS and add policies in the same SQL that creates the table.

## Rules
- Before any code change, new/overwritten file, or Supabase schema/data change: tell me in plain English what and why, and wait for "confirmed".
- Make the smallest change that does the job. Don't reformat or restructure code I didn't ask about.
- Deleting things (records, files, features) always asks first.
- Don't reintroduce things that were removed. If a fix seems to undo earlier work, stop and ask.
- Search current docs before giving dashboard/UI steps (Cloudflare, Supabase, Google…); flag anything uncertain.
- When I say something isn't working, I've already deployed and hard-refreshed — check your side first.
- Commit messages: short and specific. No "update".

## Deploy
From the repo root (give me exact commands; never plain git/wrangler sequences):
- `.\save.ps1 "what changed"` — add, commit, pull, push, then deploy both sites. Stops at the first error.
- `.\save.ps1 "what changed" -NoDeploy` — save to GitHub only.
- `.\deploy.ps1` — deploy only. Never run `wrangler deploy` directly.
deploy.ps1 refuses to deploy unless everything is committed, pushed, and this PC matches GitHub.
Supabase Edge Function / database changes are live immediately — no save command needed for those.

## Where the repo lives
- Yudgimmel (also "spotlight"): `C:\Users\ber\Pottery Land\Main Site and Admin`
- pgraphics-1: `D:\Pottery Land\potterylandnyc.com_Site-and-Admin`
Always `git pull` before starting on either PC.
Wrong-PC safeguard: at chat start and before any file write, Claude checks which computer the chat is linked to, says "Linked to: <PC>", and asks which PC I'm at — stops if they don't match. Every write and every save command names the PC and path. `save.ps1` prints the computer name at the top.

## Writing files on the PC (Claude) — required
Writes to the PC have silently landed an older draft ("deployed but nothing changed").
- Write each finished file to a new, uniquely named file in the outputs folder (e.g. `index-v3.html`) and save to the PC from that. Never reuse a file name for a second version, and never re-stage a file right before writing it.
- After every write, wait a few seconds, then check the PC file with a directory listing — size must match and the time must be new — before saying it's saved.
- `save.ps1` stops with "Nothing changed" if there's nothing to commit — if that happens, check the PC files first.
