# LoyaltyCards — Handoff Notes (2026-08-21)

For picking this up in a new Claude session on the Mac. Paste this whole note in as context, or attach the file.

## Branch state as of this session

- `main`: `b0f6476`
- `develop`: `b0f6476` (same commit — equalized with `main`)
- `releases/v2.1.1-build29`: `c4919fd` (intentionally NOT updated — release branches are read-only snapshots of what actually shipped to Apple, and this predates the site migration below. Don't merge into it.)

## What's done

1. **v2.1.1+29 marked live.** Apple approved and released it to the App Store 2026-08-19 (both apps). `RELEASES.md`, `CHANGELOG.md`, and `APP_STORE_SUBMISSION_CHECKLIST.md` all updated to reflect this.

2. **Public site migrated off GitHub Pages to Cloudflare Pages.** The `site/` folder (privacy policy, ToS, support, accessibility statement, About/marketing pages — several of which are referenced directly in App Store Connect metadata) was moved off the personal GitHub account.
   - **New live URL:** `https://loyaltycards-site.pages.dev`
   - **Old URL (still resolving, not yet decommissioned):** `https://ian-hamlet.github.io/LoyaltyCards`
   - Cloudflare account: `ian.hamlet@dotconnected.com`, Account ID `afcb0151ba5852b076a195722e891375`
   - Deploy: `.github/workflows/cloudflare-pages.yml` — runs `wrangler pages deploy site --project-name=loyaltycards-site` on every push to `main` touching `site/**`. Uses Direct Upload (a Pages-scoped API token), not Cloudflare's GitHub App — Cloudflare has never been granted read access to this repo.
   - Auth: GitHub repo secret `CLOUDFLARE_API_TOKEN` (already set, Pages:Edit scope)
   - Old workflow `.github/workflows/pages.yml` (GitHub Pages) removed from `main`/`develop`
   - Verified working: all 5 ASC-referenced pages load correctly on the new host

## What's NOT done yet — the new requirement to pick up

**App Store Connect's own URL fields still point at the OLD `ian-hamlet.github.io` host, for both apps (LoyaltyCards Customer Wallet and LoyaltyCards Business):**
- Privacy Policy URL
- Terms of Service URL
- Support URL
- Marketing URL

None of these have been re-entered in ASC yet. The pages themselves are live and correct at the new Cloudflare URLs — only the ASC fields lag.

**Deliberate decision:** hold off updating ASC and disabling GitHub Pages until the *next* release is built, submitted, and approved — so this cutover rides along with a real release rather than happening as a bare metadata-only change outside the normal release cadence.

`docs/deployment/APP_STORE_SUBMISSION_CHECKLIST.md` has 5 checklist items deliberately left unchecked (`[ ]`), each with an inline note spelling out exactly what needs entering in ASC.

## Next steps for the new release

1. Build/version-bump as normal for the new release (standard `RELEASES.md` workflow: `develop` → `main` → release branch → build → TestFlight → submit).
2. Once Apple approves and releases it, update the four ASC URL fields (both apps) to the `loyaltycards-site.pages.dev` equivalents — exact URLs are listed in `APP_STORE_SUBMISSION_CHECKLIST.md` under "Quick Reference: Required URLs".
3. Tick off the 5 pending checklist items in `APP_STORE_SUBMISSION_CHECKLIST.md` once ASC actually reflects the new URLs.
4. Only then: disable GitHub Pages for `ian-hamlet/LoyaltyCards` (repo **Settings → Pages**) so the old URL stops resolving.
5. Create `releases/v{new-version}-build{number}` from `main` per the usual workflow, and merge `main` → `develop` (or vice versa) to keep all three in sync as usual.

## Key reference docs (in-repo)

- `docs/deployment/RELEASES.md` — full release history, including the 2026-08-21 site-migration note
- `docs/deployment/APP_STORE_SUBMISSION_CHECKLIST.md` — the 5 pending ASC items are flagged here with what to change
- `docs/deployment/APP_STORE_METADATA_PACKET_v2_1_1_29.md` — current metadata packet; doc text already shows the new host, ASC itself doesn't yet
- `.github/workflows/cloudflare-pages.yml` — the deploy workflow itself
