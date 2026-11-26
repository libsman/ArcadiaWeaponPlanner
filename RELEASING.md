# Releases

Publish a GitHub release with its named installable addon ZIP attached before publishing. The CurseForge workflow tests the tagged source, validates the ZIP against that source, and uploads the exact asset with GitHub release notes. Prereleases become Beta files. Ordinary pushes do not publish. CurseForge approval still applies.

Set the repository Actions secret `CURSEFORGE_API_TOKEN` using an author token from https://authors.curseforge.com/#/settings/api-tokens . Never commit the token. The game catalog currently uses `11.0.0.0000`; update the uploader if CurseForge adds a newer supported version.

Use Actions > Publish to CurseForge > Run workflow to validate an existing tag. Dry run is enabled by default. Disable it only to upload a release not already on CurseForge. Previously uploaded releases are not imported automatically.

A successful upload adds `curseforge-upload.json` to the GitHub release. Subsequent runs skip recorded uploads. If the upload or receipt step fails, inspect CurseForge before rerunning: the server may have accepted the upload. POST uploads are never automatically retried.

Releases created by another Actions workflow using GITHUB_TOKEN do not trigger release events; create them locally with gh or in the GitHub UI, or dispatch this workflow explicitly.
