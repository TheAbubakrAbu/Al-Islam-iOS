#!/bin/zsh
# Rebuilds Resources/Mushaf PDFs/01-asim-hafs.pdf.xz, the app's own Hafs printed-mushaf facsimile.
#
#   Scripts/mushaf-pdf/build.sh [path/to/Quran.json]
#
# Inputs: the app's Quran text (Quran.json from the Quran-Tajweed-Engine sources, the file quran.qpk is
# built from), layout.json.xz (the Madinah 1421H line breaks, see fetch_lines.py + build_layout.py), the
# app's Uthmani and QuranCommon fonts, and Amiri (OFL) for the frame labels. Needs Xcode (swiftc), qpdf, xz.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
QURAN="${1:-$HOME/Downloads/Islam/Quran-Tajweed-Engine/sources/Quran.json}"
WORK="$(mktemp -d)"
mkdir -p "$WORK/fonts"
cp "$ROOT/Resources/Fonts/Uthmani.ttf" "$ROOT/Resources/Fonts/QuranCommon.ttf" "$HERE/fonts/Amiri-Regular.ttf" "$HERE/fonts/Amiri-Bold.ttf" "$WORK/fonts/"
xz -dk -c "$HERE/layout.json.xz" > "$WORK/layout.json"
swiftc -O -o "$WORK/mushafgen" "$HERE/mushafgen.swift"
"$WORK/mushafgen" "$QURAN" "$WORK/layout.json" "$WORK/fonts" "$WORK/hafs.pdf"
# The app's .pdf.xz convention: every stream unflated, no object streams, then ONE solid xz stream.
qpdf --warning-exit-0 --stream-data=uncompress --object-streams=disable "$WORK/hafs.pdf" "$WORK/01-asim-hafs.pdf"
xz -9e -T0 -c "$WORK/01-asim-hafs.pdf" > "$ROOT/Resources/Mushaf PDFs/01-asim-hafs.pdf.xz"
ls -la "$ROOT/Resources/Mushaf PDFs/01-asim-hafs.pdf.xz"
echo "work dir: $WORK (page renders: pdftoppm -r 80 -f 50 -l 50 -png $WORK/hafs.pdf p)"
