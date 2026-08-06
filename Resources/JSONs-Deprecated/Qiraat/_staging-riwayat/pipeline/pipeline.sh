#!/bin/bash
set -e
SCRATCH="/private/tmp/claude-501/-Users-theabubakrabu-Library-Mobile-Documents-com-apple-CloudDocs-Projects--1--iOS-Al-Islam-iOS/7856440a-4d9e-4a8a-88d5-6232803459c6/scratchpad"
PY="$SCRATCH/venv/bin/python"
cd "$SCRATCH/rq"
"$PY" -c "import sys; sys.path.insert(0,'.'); import extract; assert hasattr(extract,'_bracket_kind'), 'extract.py missing gid helpers'" || exit 1
# slugs stay short; extract.pdf_path maps them to the full riwayah filenames
vols=(shubah qaloon duriabiamr susi warsh hisham ibndhakwan khalaf khallad abuharith durikisai ibnwardan ibnjammaz ruways rawh ishaq idris)
echo "=== precache (4-way parallel) ==="
i=0
for s in "${vols[@]}"; do
  nice -n 10 "$PY" -c "import sys; sys.path.insert(0,'.'); from extract import raw_ayahs; r=raw_ayahs('$s'); vals=[v for g,v in r]; print('$s', len(r), 'None:', sum(1 for v in vals if v is None), flush=True)" &
  i=$((i+1)); if [ $((i % 4)) -eq 0 ]; then wait; fi
done
wait
echo "=== bootstrap shubah ==="
"$PY" extract.py bootstrap shubah
echo "=== learn shubah ==="
"$PY" extract.py learn shubah
echo "=== decoder eval shubah ==="
rm -f data/charlm.json
"$PY" decode.py eval shubah 2>&1 | tail -14
