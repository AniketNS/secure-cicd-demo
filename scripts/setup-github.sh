#!/usr/bin/env bash
# Creates the public GitHub repo, pushes main, and applies the branch ruleset.
# Run from the project root AFTER you have reviewed the files:
#   ./scripts/setup-github.sh secure-cicd-demo
set -euo pipefail

REPO_NAME="${1:-secure-cicd-demo}"

command -v gh >/dev/null || { echo "Install GitHub CLI first: brew install gh"; exit 1; }
gh auth status >/dev/null || { echo "Run: gh auth login"; exit 1; }

OWNER="$(gh api user --jq .login)"
echo "Creating public repo $OWNER/$REPO_NAME ..."

if [ ! -d .git ]; then
  git init -b main
  git add .
  git commit -m "Initial commit: demo app, Dockerfile and PR check workflows"
fi

gh repo create "$OWNER/$REPO_NAME" --public --source=. --remote=origin --push

echo "Applying branch ruleset ..."
# The three required checks do not exist until the workflow has run once, but the
# API accepts them by name, so the ruleset can be applied right away.
gh api -X POST "repos/$OWNER/$REPO_NAME/rulesets" --input .github/ruleset-main.json >/dev/null

echo "Restricting merge methods to squash only and auto-deleting merged branches ..."
gh api -X PATCH "repos/$OWNER/$REPO_NAME" \
  -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true >/dev/null

cat <<EOF

Done: https://github.com/$OWNER/$REPO_NAME

Still to do by hand (needs your SonarQube Cloud account):
  1. Create the project at https://sonarcloud.io, and DISABLE "Automatic Analysis"
     (Administration > Analysis Method), otherwise CI analysis is rejected.
  2. Put your org and project keys into sonar-project.properties and commit them.
  3. Add the repo secret:  gh secret set SONAR_TOKEN --repo $OWNER/$REPO_NAME
  4. Create the "production" environment (Settings > Environments) for deploy.yml.
EOF
