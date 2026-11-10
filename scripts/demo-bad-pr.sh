#!/usr/bin/env bash
# Opens a PR that SHOULD be blocked: a vulnerable dependency (Trivy) plus insecure
# code (SonarQube). Run from the project root on a clean main.
set -euo pipefail

BRANCH="demo/bad-change-$(date +%H%M%S)"
git checkout main && git pull --ff-only
git checkout -b "$BRANCH"

# 1) Old lodash with known HIGH/CRITICAL CVEs -> Trivy filesystem scan fails
npm install lodash@4.17.15 --save --no-audit --no-fund

# 2) eval() on user input -> SonarQube flags a security hotspot / vulnerability
cat > src/calc.js <<'JS'
'use strict';

const express = require('express');
const _ = require('lodash');

const router = express.Router();

// INTENTIONALLY INSECURE (demo): evaluates user-supplied input
router.get('/calc', (req, res) => {
  const result = eval(req.query.expr);
  res.json({ result: _.toString(result) });
});

module.exports = router;
JS

git add -A
git commit -m "Add calculator endpoint (intentionally insecure for demo)"
git push -u origin "$BRANCH"
gh pr create --base main --head "$BRANCH" \
  --title "Add calculator endpoint" \
  --body "Demo PR. Expect SonarQube and Trivy to fail and the merge button to stay disabled."
