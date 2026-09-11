# Website and preview releases

The public website is https://specter-terminal-umber.vercel.app. Vercel serves static HTML, CSS, JavaScript, theme files, and the 74.7-second demo video. There is no backend, database, API key, or running local server required. Specter itself runs on each user’s Mac. GitHub hosts the source and versioned app downloads.

## Website updates

The Vercel project is `specter-terminal` in the existing `biswas07` Hobby scope, connected to `shellcat-com/Specter`. Production branch: `main`. The repository-root `vercel.json` runs `python3 scripts/check-website.py` and publishes only `website/`. A push to main is intended to deploy the site through the Git integration. Check the Vercel deployment status after each push.

For a manual production deploy from a reviewed checkout:

```sh
vercel link --yes --project specter-terminal --scope biswas07
vercel deploy --prod --yes --scope biswas07
```

Vercel CLI authentication is required. Credentials and `.vercel/` project state are not committed. No paid features or custom domain are configured. Vercel’s [Hobby plan](https://vercel.com/docs/plans/hobby) is free for personal, noncommercial use, within its limits. If this becomes a commercial product, reassess hosting terms before monetizing it.

## App releases

A website deployment does not rebuild the native macOS app. On Apple silicon with full Xcode and Metal tools, run the checks and package a new preview:

```sh
scripts/check.sh
scripts/package-preview.sh 0.1.0-preview.2
```

The packager refuses an existing output directory, builds and verifies the app, and places a ZIP plus `SHA256SUMS.txt` in `.artifacts/releases/<version>/`. It signs only ad hoc; it does not use Developer ID, notarize, upload, or release anything. Keep the versioned GitHub prerelease tag tied to the reviewed source commit, upload both files together, then update the site and installation guide links. Publishing future releases requires maintainer authorization.

No automatic updater is included. The current downloadable build is for testers: macOS may block it, older target OS versions are not runtime-verified, and a clean-machine quarantined installation has not been validated. Developer ID signing, Apple notarization, and broader compatibility testing remain necessary before calling this a stable public release.
