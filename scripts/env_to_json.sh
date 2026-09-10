#!/usr/bin/env bash
set -euo pipefail
INPUT="${1:-.env}"
OUTPUT="${2:-env.production.json}"
python3 - "$INPUT" "$OUTPUT" <<'PY'
import json, sys
src, dst = sys.argv[1:]
out = {}
for raw in open(src, encoding='utf-8'):
    line = raw.strip()
    if not line or line.startswith('#') or '=' not in line:
        continue
    k, v = line.split('=', 1)
    k, v = k.strip(), v.strip()
    if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
        v = v[1:-1]
    out[k] = v
with open(dst, 'w', encoding='utf-8') as f:
    json.dump(out, f, indent=2)
print(f'Created {dst}')
PY
