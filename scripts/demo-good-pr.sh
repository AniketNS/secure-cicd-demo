#!/usr/bin/env bash
# Opens a harmless PR that SHOULD pass every check and become mergeable.
set -euo pipefail

BRANCH="demo/good-change-$(date +%H%M%S)"
git checkout main && git pull --ff-only
git checkout -b "$BRANCH"

cat > src/version.js <<'JS'
'use strict';

const { version } = require('../package.json');

module.exports = { version };
JS

# Expose the version on the existing health route's sibling
python3 - <<'PY'
import re, pathlib
p = pathlib.Path("src/app.js")
s = p.read_text()
if "/version" not in s:
    s = s.replace("module.exports = app;", "app.get('/version', (_req, res) => {\n  res.json({ version: require('./version').version });\n});\n\nmodule.exports = app;")
    p.write_text(s)
PY

git add -A
git commit -m "Add /version endpoint"
git push -u origin "$BRANCH"
gh pr create --base main --head "$BRANCH" \
  --title "Add /version endpoint" \
  --body "Demo PR. Expect all three checks to pass and the merge button to turn green."
