# secure-cicd-demo

Demo repo for the Ubucon India 2026 talk **Secure GitHub CI/CD Pipelines**.

```
Commit -> Pull request -> SonarQube scan -> Trivy scan -> Docker build -> Deploy (only if green)
```

## What protects `main`

Defined in [`.github/ruleset-main.json`](.github/ruleset-main.json) (a GitHub Ruleset, the newer
replacement for classic branch protection):

| Rule | Effect |
|---|---|
| Require a pull request | No direct pushes to `main` |
| Required status checks | `SonarQube Cloud Scan`, `Trivy Filesystem Scan`, `Docker Build and Trivy Image Scan` must pass |
| Branch must be up to date | Checks run against the latest `main` |
| Block force pushes, block deletion | History cannot be rewritten |
| **Empty bypass list** | Admins are held to the same rules, so a red PR cannot be merged by anyone |

Approvals are set to **0** because on a solo repo the PR author cannot approve their own PR.
With a second account, raise `required_approving_review_count` to 1.

## Workflows

- `.github/workflows/pr-checks.yml` runs on every PR into `main` (three parallel jobs, the required checks above).
- `.github/workflows/deploy.yml` runs only on push to `main`, i.e. after a merge. The EC2 deploy step is a placeholder.
- Third-party actions are pinned to full commit SHAs, not moving tags.

## One-time setup

1. `brew install gh && gh auth login`
2. Create a project at <https://sonarcloud.io>, **turn off Automatic Analysis**, and put the org and project keys in `sonar-project.properties`.
3. `./scripts/setup-github.sh secure-cicd-demo` (creates the public repo, pushes, applies the ruleset)
4. `gh secret set SONAR_TOKEN` (token from SonarQube Cloud > My Account > Security)
5. Settings > Environments > create `production` (optional manual approval for deploys)

## Live demo script

1. **Blocked PR:** `./scripts/demo-bad-pr.sh`. Open the PR. SonarQube and Trivy go red and the merge button stays disabled, even for the repo admin.
2. **Direct push:** `git push origin main` is rejected by the ruleset.
3. **Good PR:** `./scripts/demo-good-pr.sh`. All three checks go green and the merge button enables.
4. **Merge:** `deploy.yml` starts on `main`.

## Run locally

```bash
npm ci && npm test
docker build -t secure-cicd-demo . && docker run -p 3000:3000 secure-cicd-demo
trivy fs --scanners vuln,secret,misconfig --severity HIGH,CRITICAL .
trivy image --severity HIGH,CRITICAL secure-cicd-demo
```
