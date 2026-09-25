# Site styling — shared CSS system

## The rule
Every page on `potterylandnyc.com` links two stylesheets in `<head>`, in this order:

```html
<link rel="stylesheet" href="styles.css">
<link rel="stylesheet" href="index.css">   <!-- that page's own file, named to match -->
```

No inline `<style>` blocks in any page's HTML — both `index.html` and `sunday-club.html` are markup-only as of 2026-09-16.

**`styles.css` is the site's design system, not just "what two pages happen to share."** When deciding whether something belongs in `styles.css` vs. a page's own file, the test is: *is this a generic, reusable pattern (a component any future page would plausibly want), or is it specific to one page's actual content/feature?* Reusable patterns get promoted even if only one page currently uses them — don't wait for a second page to prove it before making it available. Specific features (an interactive booking widget, a particular section's exact layout) stay local even if they look superficially similar to something elsewhere.

Two separate checks before finishing any change to a page's CSS:
1. **Duplicate check:** does this exact rule already exist in another page's CSS file? If so, promote it into `styles.css` instead of leaving it duplicated.
2. **Name-collision check:** does this class *name* already exist in another page's CSS file with *different* content? If so, rename one of them — don't let two different things share a name (found + fixed 2026-09-16: `.price-line` meant two unrelated things on index vs. sunday-club; renamed sunday-club's to `.price-row`).

(Both checks are also in the project's custom instructions — this doc is the backstop.)

## Where the files live
- `styles.css` - ONE file, at `potterylandnyc.com/Public/styles.css`. Edit it there. There are no copies and nothing is synced (changed 2026-09-25; the old root master + copy step in deploy.ps1 were removed).
- `index.css`, `sunday-club.css` - each page's own file, also in `potterylandnyc.com/Public/`.
- The admin site uses the shared styles by linking the live file by URL: `<link rel="stylesheet" href="https://potterylandnyc.com/styles.css">`. A change to styles.css reaches the admin site as soon as the main site is deployed.

## What's in `styles.css`
- Design tokens (`:root`): colors, fonts, `--radius`, `--container-padding` (default 24px). `--max-width` is not here — genuinely differs per page (index: 1100px, sunday-club: 820px), each page sets its own.
- Reset (`*`), `body`, `a`.
- Base element styles: `h1`–`h4`, `p`, `button`, `input`/`select`/`textarea` — a plain tag looks right with no class.
- `.btn` / `.btn-primary` / `.btn-accent` / `.btn-outline` — generic button system.
- `.form-group`, `.form-group label`, `.form-row` — generic form layout.
- `.phone-row`, `.phone-row .phone-country` — generic phone-field-with-country-selector layout (added 2026-09-18, see "Phone number fields" below).
- `.on-dark` utility — see below.
- `.container` — generic centering layout, parameterized by `--max-width` and `--container-padding` so each page just sets two variables instead of redeclaring the rule.
- `.nav-highlight` — generic "highlight this nav link" utility.
- Section header pattern: `section` (spacing), `.section-label`, `.section-title`, `.section-body` — the eyebrow/title/intro-paragraph pattern for the top of any content section on any page.
- `.card`, `.card h2`/`.card h3` (size), `.card .card-sub` — generic bordered content box, used for any grouped content.
- `.hint` — generic form helper-text.
- `.modal-overlay`, `.modal`, `.modal-close` — generic centered popup dialog (renamed from index.html's original `.info-popup*` naming, since it's a reusable pattern, not something specific to the "info" popups it was first built for; index.html already reused it for two different popups before this rename, confirming it was already functioning as generic).

## The `.on-dark` utility
Any wrapper that sets its own background + text color (a dark card, a colored banner) gets `class="on-dark"` added to it:

```css
.on-dark, .on-dark h1, .on-dark h2, .on-dark h3, .on-dark h4, .on-dark p { color: inherit; }
```

**Why this exists:** `styles.css` gives bare headings/paragraphs an explicit color. That's right on the normal light background, but it silently overrides inheritance inside any section that expected its children to pick up its own `color: white` — a declared rule always beats an inherited one. This broke `.party-card`, `.walkin-banner`, and the Sunday Club `.pricing-card` (found + fixed 2026-09-16). **Currently applied to:** `.walkin-banner` and `.parties-section` (index.html), `.pricing-card` (sunday-club.html). Any new dark/colored section gets `class="on-dark"` at build time, not after it visibly breaks.

## Phone number fields (added 2026-09-18)
Every phone field on every form — today's three (Sunday Club registration, the Sunday Club waitlist, the main site's inquiry form) and any future one — uses the same pattern instead of a plain text box. This was added after a real bad entry (`171-837-5471`, an impossible area code) sat in the customer list unnoticed and made that customer unreachable by SMS/WhatsApp.

**Markup:** a small country-code `<select class="phone-country">` (defaults to `US +1`, same option list as the order app's customer form — UK, IL, AU, and a couple dozen others, plus "Other") sits next to the `<input type="tel">`, wrapped in `.phone-row` (defined in `styles.css`). Copy the exact `<select>` markup from `sunday-club.html`'s `parent-phone-country` — don't hand-write a shorter option list.

**Behavior (three small JS functions, copied verbatim into each page's own `<script>` block — there's no shared JS file across pages the way there is for CSS, so this is the one thing that's duplicated on purpose):**
- `formatPhone(input, countrySelectId)` — auto-inserts dashes as you type (`917-555-1234`), only when the selected country is US/Canada. Leaves anything else untouched, since international formats vary too much to mask the same way.
- `getFullPhone(countrySelectId, phoneInputId)` — combines the selected country code + the typed number into the single string that actually gets saved (e.g. `+1 917-555-1234`, or just the typed value for a country with no code prefix needed).
- `isValidPhone(countrySelectId, phoneInputId)` — the actual gate before saving. For US/Canada: must be a complete 10-digit number, and the area code / exchange can't start with 0 or 1 (real North American numbers never do — this is exactly the rule that would have caught `171-837-5471`). For anywhere else: just has to be non-empty with a plausible number of digits (7+), since we don't police other countries' formats the same way.

A required phone field blocks submission until `isValidPhone` passes. An optional one (the waitlist, the inquiry form) only runs the check if something was actually typed — leaving it blank is still fine.

**Database backstop:** the same rule is enforced a second time at the database level, so it can't be bypassed by a bug, a future form that forgets to wire this up, or a direct API call. A single shared Postgres function, `is_valid_phone(text)`, implements the identical logic (strict for numbers that look North American, lenient for anything with a different country's `+` prefix) and is attached as a `CHECK` constraint to every phone column: `customers.phone`, `pgl_signups.parent_phone`, `pgl_inquiries.phone`. Any new table with a phone column should attach the same constraint (`check (is_valid_phone(<column>))`) rather than writing a new rule. `customers.phone` had one pre-existing bad row (Toby Shain's, the one that triggered this whole change) that the correct number can no longer be recovered for — that constraint was added `NOT VALID`, meaning the old row is left alone but every new or edited row is checked from 2026-09-18 onward.

**Order app difference:** `app.potterylandnyc.com` already had a working version of this (country `<select id="phoneCountry">` + `formatPhone`/`getFullPhone`) before this change — its new-customer form was the source the public-site option list was copied from. This update mainly added the same validity check there (`isValidPhone`) to both the new-customer and edit-customer save paths (neither previously checked more than "is it non-empty"), and added the missing country selector to the edit-customer panel, which didn't have one before (editing a non-US number there used to silently mangle it — fixed via a new `splitPhone()` helper that correctly re-splits a stored `+<code> <number>` string back into the two fields).

## What's deliberately NOT shared (page-specific features, not patterns)
- Header/nav/hero/footer *sizing* (padding, breakpoints, sticky behavior) — genuinely differs page to page today. Note: index's header is `position: sticky`, sunday-club's isn't — that's a real, currently-undiscussed UX difference, not just a CSS artifact. Worth a deliberate decision later if it should be consistent, not something to silently unify.
- Index's interactive class-booking system (`.class-row`, `.schedule-popup` internals, `.booking-cart`) — one specific feature, not a pattern other pages need.
- Index's `.parties-grid`/`.party-card`, `.contact-section`/`.hours-table` — specific homepage content sections.
- Index's `.activities-grid`/`.activity-card` — could arguably become a generic "feature card" pattern later if a second page needs the same shape, but wait for that actual second use before generalizing it (don't build speculatively).
- Sunday-club's `.location-options`/`.child-block`/pricing breakdown — specific to the registration flow.

Audited fully 2026-09-16, both directions (index → shared and sunday-club → shared). Don't re-merge the page-specific items above without checking pixel-for-pixel differences or getting explicit sign-off that a visual/behavioral change is wanted.

## Page types (future — not yet built)
If a second club/program is added later, check first whether it can be a new row in `pgl_programs`/`pgl_program_offerings` read by the same page (parameterized by a URL slug, e.g. `/clubs/spring-club` rewritten via `_redirects`) rather than a duplicated file — the database schema already avoids hardcoding per-program details, so this likely means zero new files per club.

If a genuinely different page type is needed (different flow, not just different details), the CSS gets a third tier: `styles.css` (site-wide) → `<type>.css` (shared by every page of that type) → that page's own tiny file for anything truly unique. Don't build this tier speculatively — wait for an actual second instance of a type.

A duplicate-CSS-rule check in `deploy.ps1` was discussed and deferred until there are enough pages that eyeballing duplication stops being realistic (not needed at 2 pages).

## Admin site
`admin.potterylandnyc.com` still has its own separate design system (different variable names, system font). Plan (decided 2026-09-25): convert it to the shared styles over time. When converting, link `https://potterylandnyc.com/styles.css` (see "Where the files live") - never copy the file into the admin folder.

## Images
Images are always real files, never inline base64 data URIs in the HTML. Each page's images live in that page's own `Public/images/` folder (e.g. `potterylandnyc.com/Public/images/activity-1.jpg`) and are referenced with a normal relative `src="images/activity-1.jpg"`.

**Why:** an embedded base64 image bloats the HTML file itself (found + fixed 2026-09-16: 5 embedded photos made `index.html` 591KB instead of 41KB), can't be cached by the browser separately from the page, and makes the HTML source unreadable. A real image file is cached independently, keeps the HTML readable, and costs nothing extra to deploy (Cloudflare only uploads files that actually changed, by content hash).

Exception: a favicon as a tiny inline `data:image/svg+xml` is fine — that's a few hundred bytes of vector markup, not a photo, and inlining it avoids an extra request for something so small.

## Starting a new page
1. Copy an existing page's `<head>` boilerplate (doctype, meta tags, Supabase script tag if needed, the two stylesheet `<link>` tags) and rename the second link to the new page's own CSS file.
2. Create that page's own CSS file in the same `Public/` folder; set `--max-width` (and `--container-padding` if not 24px) in a local `:root` block.
3. Build with plain semantic HTML where possible — `<h1>`–`<h4>`, `<button>`, `<input>`/`<select>`/`<textarea>`, `.container`, `.card`, `.section-label`/`.section-title`/`.section-body`, `.modal-overlay`/`.modal` already work with no page-specific CSS.
4. Any dark/colored-background section gets `class="on-dark"` on its wrapper immediately.
5. Any phone field uses the standard country-select + `.phone-row` pattern and the three shared `formatPhone`/`getFullPhone`/`isValidPhone` functions (copy them in) — see "Phone number fields" above. Never a plain, unvalidated phone `<input>`.
6. Any image goes in that page's `Public/images/` folder as a real file, referenced with a relative `src` — never inline base64.
7. Before considering the page done: run both CSS checks above (duplicate rule, name collision) against every other page's CSS file, and ask "is anything I just wrote actually a generic pattern, not just this page's content?" — promote accordingly.