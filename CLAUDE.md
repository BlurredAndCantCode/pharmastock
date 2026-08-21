# PharmaStock — CLAUDE.md

Read this first. It's the project handoff/context file for Claude Code sessions on any machine.

## What this is

**PharmaStock** (live at **https://pharmastocker.com**) is the user's personal inventory
web app for tracking their own supplements, peptides, and compounds. It started as an
Excel sheet conversion and grew into a small multi-user SaaS: open signup, each account
sees only its own private data. Friends of the owner use it too.

## Tech stack (deliberately minimal)

- **One self-contained file: `index.html`** — all HTML, CSS, and vanilla JS. No framework,
  no build step, no node_modules. ~everything lives in one `<script>` block at the bottom.
- **Supabase** — email/password auth + Postgres. **Row-Level Security** on every table
  (`auth.uid() = user_id`) is the actual security wall. The Supabase URL + anon key are
  baked into index.html (`BAKED` constants) — that is safe and by design; the anon key is
  public, RLS protects the data.
- **Netlify** — hosts the site, auto-deploys from GitHub repo
  **BlurredAndCantCode/pharmastock**, branch `main`. Custom domain via Namecheap DNS
  (A `@` → 75.2.60.5, CNAME `www` → pharmastock.netlify.app, plus a Google-site-verification
  TXT and the hCaptcha/Google records).
- **hCaptcha** on login/signup — widget in the auth card (site key baked in, fine),
  token passed via `options.captchaToken` to `signUp`/`signInWithPassword`. The matching
  secret + "Captcha protection" toggle live in Supabase → Auth → Attack Protection.
  **If you ever remove the widget, disable it in Supabase first or all logins break.**

## Deploy workflow (this is the whole pipeline)

```
edit index.html  →  syntax-check the JS  →  git commit  →  git push origin main
                                                     ↓
                              Netlify rebuilds; live in ~30–60s
```

- **Always syntax-check before pushing** (a broken script = broken live site):
  - macOS (no node installed): extract the last `<script>` block, prepend DOM/supabase
    stubs, run through JavaScriptCore `jsc`
    (`/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Helpers/jsc`).
  - Windows/other: `node --check` on the extracted script block works fine.
- Git auth: fine-grained GitHub PAT (on the Mac it's in the keychain; on a new machine
  generate a fresh PAT and let git prompt for it).
- Commit author used so far: `BlurredAndCantCode <dc.digz@gmail.com>`.

## Files

| File | Purpose |
|---|---|
| `index.html` | The entire app. Only file that deploys. |
| `schema-full.sql` | **Canonical, idempotent schema** — items + cycles tables + all RLS policies. Safe to re-run. |
| `migration-*.sql` | Historical one-off migrations (already applied to prod, superseded by schema-full.sql, EXCEPT see "current state" below). |
| `SECURITY.md` | Supabase hardening checklist (RLS, captcha, leaked-password protection…). |
| `og-image.png` | Link-preview image referenced by the OG/Twitter meta tags. |
| `.github/workflows/keepalive.yml` | Pings Supabase twice a week (Mon/Thu) so the free tier never auto-pauses. Fails loudly → GitHub emails the owner = free downtime alert. |

DB migrations are applied by **pasting SQL into the Supabase SQL Editor manually**
("Option B"). A direct-connection Python runner was tried and abandoned (pooler auth
pain) — don't resurrect it, manual paste is fine for how rare migrations are.

## Database (Supabase)

- `items` — user_id, name, category, form, qty, unit, dose, uses, price, status
  ('In Stock' / 'On the Way' / 'Out' / idea-status), reorder, expiry, notes, source,
  effect (comma-separated), tags (comma-separated), priority, **unit_price, pack** (newest).
- `cycles` — user_id, title, start/end dates, cost, notes, `rows` (jsonb: array of
  topic sections, each `{group, rows:[{compound, dosing, ...}]}`).
- 4 RLS policies per table, all `auth.uid() = user_id`.

## App architecture notes (inside index.html)

- Sections: Overview · Inventory · Restock · Purchase Ideas · Cycles, switched by
  `setSection()`; sidebar is nav-only, Account modal holds theme + logout.
- Current UI = "SaaS dashboard" redesign: 3 header stat cards, toolbar (search /
  Filters popover / Table–Cards segment / + Add item), one big rounded `.surface`
  containing **category tabs** + a 5-column table (Product, Stock, Form, Price, Status)
  with a per-row **⋮ menu** and a header **⋮ menu** (exports/backup/import).
  Blue `--accent:#3b82f6` is reserved for primary actions/selected states.
- Item detail modal (`showDetail`), bulk select + green bulk bar, CSV/PDF export,
  JSON backup, CSV/JSON import (`parseCSV` handles quoted fields).
- Animations layer: keyframes `modalin/popin/fadeup/rowin` + hover/active transitions,
  with a `prefers-reduced-motion` kill switch.
- Cycle editor: sections model (`editSections`), compound input autofills dosing from
  matching inventory item (`cyAutofill`).
- UI state in localStorage (theme, accent, view mode, collapsed groups); all real data
  in Supabase. `render()` is the single re-render entry point.

## Important decisions / constraints

1. **Scope boundary (firm):** personal tracker features only. Do NOT build a public
   compound catalog, preset dosing library, or stack/combination builder for other
   users — the inventory includes AAS/prescription/research compounds and shipping
   curated dosing guidance publicly crosses the line. Extending private per-user
   features is fine.
2. **Single file, no build step** — keep it that way; it's the deploy model.
3. **Never expose the Supabase `service_role` key** anywhere client-side.
4. Security posture: RLS + email confirmation + hCaptcha + (optionally) leaked-password
   protection. The anon key being public is fine.
5. Free tiers are plenty (Supabase free ≈ 500MB DB / 5GB egress; Netlify 100GB).
   Supabase Pro (~$25/mo) is the upgrade path if usage ever grows.
   Note: free Supabase pauses after ~1 week of zero activity — mitigated by the
   keep-alive GitHub Action (see Files). If the site ever shows no data, check
   whether the Supabase project is paused and hit Resume in the dashboard.

## Current state / what was in flight

Last commit: `80bfcc4` — unit-price feature. **Everything is deployed and working**, but:

- **VERIFY:** the unit-price feature needs two DB columns. `migration-unitprice.sql`
  (`alter table items add column if not exists unit_price numeric;` + same for `pack`)
  was written and the user was told to run it in the Supabase SQL Editor — **confirm they
  actually ran it**; if not, saving items will error. Ask, or test by saving an item.
- The unit-price UX: "Unit price ($)" + "Per" (1 = vial/bottle, 10 = strip) auto-compute
  "Total price" (`calcTotal()`); typing a manual Total clears the unit fields. Total
  price still feeds all value stats.
- **Open question posed to the user, unanswered:** show unit price in the table rows
  (e.g. a small "$38 ea" under Price) or leave it detail-modal-only?
- Feature backlog the user has seen and may pick from: quantity +/− steppers, command
  palette (⌘K), inline edit, quick-add bar, toasts + undo delete, density toggle,
  show/hide columns, custom category colors, item photos, duplicate/active cycle,
  value-trend snapshots, row stagger animation, "Saved ✓" toast.

## Working with this user

- Non-technical but sharp; explain in plain language, no jargon walls.
- Ship fast: small edits → check → push; they test live and give screenshot feedback.
- They like polished modern UI (the sci-wiki-inspired look, animations) and often ask
  "what else can we add" — offer a short menu of options rather than one big plan.
