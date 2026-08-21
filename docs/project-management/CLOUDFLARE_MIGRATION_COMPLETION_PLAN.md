# Cloudflare Pages Migration — Completion Plan

**Source:** consolidated from `docs/review/loyaltycards-handoff-2026-08-21.md` (a session handoff note), 2026-08-21.

## Status as of 2026-08-21

The public site (`site/` — Privacy Policy, Terms of Service, Support, Accessibility Statement, About/marketing pages) has been migrated off GitHub Pages to Cloudflare Pages:

- **New live URL:** `https://loyaltycards-site.pages.dev` — verified working, all 5 ASC-referenced pages load correctly.
- **Old URL (still resolving, not yet decommissioned):** `https://ian-hamlet.github.io/LoyaltyCards`
- Cloudflare account: `ian.hamlet@dotconnected.com`, Account ID `afcb0151ba5852b076a195722e891375`
- Deploy workflow: `.github/workflows/cloudflare-pages.yml` — runs `wrangler pages deploy site --project-name=loyaltycards-site` on every push to `main` touching `site/**`. Uses Direct Upload (a Pages-scoped API token), not Cloudflare's GitHub App — Cloudflare has never been granted read access to this repo.
- Auth: GitHub repo secret `CLOUDFLARE_API_TOKEN` (already set, Pages:Edit scope).
- Old GitHub Pages workflow (`.github/workflows/pages.yml`) already removed from `main`/`develop`.

**Branch state at time of migration:** `main` and `develop` both equalized at `b0f6476`. `releases/v2.1.1-build29` deliberately left at its earlier commit (`c4919fd`) — release branches are read-only snapshots of what actually shipped to Apple, and this predates the migration. Don't merge the migration into that release branch.

## What's not done yet

**App Store Connect's own URL fields still point at the OLD `ian-hamlet.github.io` host, for both apps** (LoyaltyCards Customer Wallet and LoyaltyCards Business):
- Privacy Policy URL
- Terms of Service URL
- Support URL
- Marketing URL

None of these have been re-entered in ASC yet. The pages themselves are live and correct at the new Cloudflare URLs — only the ASC fields lag. `docs/deployment/APP_STORE_SUBMISSION_CHECKLIST.md` has 5 checklist items deliberately left unchecked (`[ ]`) for this, each with an inline note.

**Deliberate decision (carried forward from the handoff note):** hold off updating ASC and disabling GitHub Pages until the *next* release is built, submitted, and approved — so this cutover rides along with a real release rather than happening as a bare metadata-only change outside the normal release cadence.

## Completion checklist, for whenever the next release goes out

1. Build/version-bump as normal for the new release (standard `RELEASES.md` workflow: `develop` → `main` → release branch → build → TestFlight → submit).
2. Once Apple approves and releases it, update the four ASC URL fields (both apps) to the `loyaltycards-site.pages.dev` equivalents — exact URLs are listed in `APP_STORE_SUBMISSION_CHECKLIST.md` under "Quick Reference: Required URLs".
3. Tick off the 5 pending checklist items in `APP_STORE_SUBMISSION_CHECKLIST.md` once ASC actually reflects the new URLs.
4. Only then: disable GitHub Pages for `ian-hamlet/LoyaltyCards` (repo **Settings → Pages**) so the old URL stops resolving.
5. Create `releases/v{new-version}-build{number}` from `main` per the usual workflow, and keep `main`/`develop` in sync as usual.

## Key reference docs (in-repo)

- `docs/deployment/RELEASES.md` — full release history, including the 2026-08-21 site-migration note
- `docs/deployment/APP_STORE_SUBMISSION_CHECKLIST.md` — the 5 pending ASC items are flagged here with what to change
- `docs/deployment/APP_STORE_METADATA_PACKET_v2_1_1_29.md` — current metadata packet; doc text already shows the new host, ASC itself doesn't yet
- `.github/workflows/cloudflare-pages.yml` — the deploy workflow itself
