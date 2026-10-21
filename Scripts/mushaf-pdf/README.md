# Hafs printed-mushaf facsimile

`Resources/Mushaf PDFs/01-asim-hafs.pdf.xz` is generated here, not downloaded. Every ornate Hafs
mushaf PDF available online stores its text as outlines (the Complex's own 1441 AH Illustrator
pages, the "True PDF" Madinah editions), which packs to 80 MB or more; the one font-based source,
the Islamweb volume, is set on an 11-line page with Islamweb's own chrome. So the app typesets its
own: the app's KFGQPC text in the app's Uthmani face, on the Madinah Mushaf's 15-line page layout,
inside a vector teal-and-gold frame. Packed: 1.3 MB.

- `fetch_lines.py <dir>`: pulls each page's words with their printed line numbers from the public
  Quran.com API (the Madinah 1421 AH layout, the same page and line division as the KFGQPC print).
- `build_layout.py <dir> Quran.json layout.json`: turns that into 15 lines per page (ayah lines,
  surah banners, basmalahs; a banner that opens the next page's text sits on the previous page's
  last line, as in the print), aligns the API's words to the app's own tokens by letter skeleton
  (two-token words such as "بَعۡدَ مَا", one-token pairs such as "لَّوۡمَا"), and audits that every token
  is placed exactly once and in order. `layout.json.xz` is the checked-in result.
- `mushafgen.swift`: CoreText + CGPDFContext. Per line, the exact-fit size is clamped to 92-110% of
  the mushaf-wide nominal (the 25th percentile of exact fits) and the rest is word-space justified;
  the last line of a surah and the opening spread are centered. Ayah numbers are the Uthmani face's
  own digit ornaments. The frame, cartouches, banners and medallions are CoreGraphics paths; the
  labels are Amiri (OFL, `fonts/`).
- `build.sh`: the whole chain, ending in the packed `.pdf.xz`.

The reader (`MushafPDFReader.swift`) keys this edition's content window to the whole page and
extracts the `.pdf.xz` into a cache folder stamped with the bundled file's size, so replacing the
file never serves a previous build's extraction.
