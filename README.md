# CFNEW Auto Update for Cloudflare Pages

This repository mirrors the latest `byJoey/cfnew` release asset `Pages.zip`
into the `site/` directory by using GitHub Actions. Cloudflare Pages can then
deploy `site/` automatically after every synced commit.

## What is included

- `.github/workflows/auto-update.yml`
  - Runs every 6 hours.
  - Supports manual trigger from GitHub Actions.
  - Commits only when files actually changed.
- `scripts/sync-cfnew.sh`
  - Reads the latest GitHub release metadata.
  - Downloads `Pages.zip`.
  - Extracts the archive into `site/`.
  - Stores the synced release tag in `.cfnew-release-version`.
  - Uses the workflow token for GitHub API requests when available.
- `site/index.html`
  - Placeholder page before the first successful sync.

## Setup

1. Create a GitHub repository and push this project.
2. In GitHub, open `Settings -> Actions -> General`.
3. Set `Workflow permissions` to `Read and write permissions`.
4. In Cloudflare Pages, connect this repository.
5. Use these Pages settings:
   - Framework preset: `None`
   - Build command: leave empty
   - Build output directory: `site`
6. Run the workflow once from `Actions -> Auto Update CFNEW -> Run workflow`.

## Sync flow

1. GitHub Actions fetches the latest release from `byJoey/cfnew`.
2. The workflow looks for the `Pages.zip` asset.
3. The archive is extracted into `site/`.
4. If `site/` changed, the workflow commits and pushes the update.
5. Cloudflare Pages detects the new commit and deploys the latest static site.

## Notes

- The schedule `0 */6 * * *` uses UTC in GitHub Actions.
- The repository keeps workflow files and docs outside `site/`, so sync will not
  overwrite project automation files.
- If the upstream release asset name or structure changes, update:
  - `.github/workflows/auto-update.yml`
  - `scripts/sync-cfnew.sh`
