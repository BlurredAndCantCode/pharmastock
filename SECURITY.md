# PharmaStock — Security Hardening Checklist

No website is "unhackable." The goal is to close the doors that actually matter.
For this app, **your real security wall is Supabase Row-Level Security (RLS)** —
because the app runs in the browser, anyone can read the code and the anon key,
but RLS means they can still only ever touch THEIR OWN rows.

Everything below is done in the **Supabase dashboard**, not the code.

## Must-do
- [ ] **RLS enabled on `items`** — Table Editor → `items` → confirm the "RLS enabled"
      badge. (schema.sql already turned it on; just verify.)
- [ ] **Policies exist** — Authentication → Policies → `items` should show 4 policies
      (select/insert/update/delete), each restricted to `auth.uid() = user_id`.
- [ ] **Email confirmation ON** — Authentication → Providers → Email → "Confirm email"
      enabled. Blocks junk/bot signups.
- [ ] **CAPTCHA on signup** — Authentication → Attack Protection → enable hCaptcha.
      This is the big one for a public open-signup site; stops bots mass-creating accounts.

## Strongly recommended
- [ ] **Leaked Password Protection** — Authentication → Policies → enable. Rejects
      passwords found in known breaches.
- [ ] **Minimum password length** — Authentication → set to at least 8.
- [ ] **Site URL + Redirect allowlist** — Authentication → URL Configuration → set your
      real domain once you have it, so auth/confirmation links only work there.
- [ ] **Rate limits** — Authentication → Rate Limits → keep the defaults or tighten
      the signup/email rates.

## Never do
- [ ] **Never expose the `service_role` / secret key.** It bypasses RLS entirely.
      It belongs only on a server, never in this HTML file or any public place.
      (The `anon`/publishable key IS safe to expose — that's its job.)

## Good to know
- The **anon key in the HTML is fine** — it's designed to be public. RLS protects the data.
- A **free Supabase project pauses after ~1 week idle** — just log in to wake it.
- If you ever rotate keys (Supabase → API → roll), update the `BAKED` values in
  index.html and re-deploy.
