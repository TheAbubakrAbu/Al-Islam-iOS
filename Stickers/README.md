# Al-Islam Stickers

An iMessage sticker pack: the three Al-Islam-family app icons and the four wallpapers the app already ships.

| Sticker | Source | Size |
|---|---|---:|
| Al-Islam | `Assets.xcassets/Apps/Al-Islam` | 618×618 |
| Al-Quran | `Assets.xcassets/Apps/Al-Quran` | 618×618 |
| Al-Adhan | `Assets.xcassets/Apps/Al-Adhan` | 618×618 |
| Phone Wallpaper | `Assets.xcassets/Wallpapers` | 285×618 |
| Desktop Wallpaper | `Assets.xcassets/Wallpapers` | 618×260 |
| Laptop Wallpaper | `Assets.xcassets/Wallpapers` | 618×399 |
| Free Palestine | `Assets.xcassets/Wallpapers` | 285×618 |

All seven are regenerated from art already in the app — nothing new was drawn, and nothing is borrowed from another project.

## How it is wired up

This ships as the **`Stickers`** target — product type `com.apple.product-type.app-extension.messages-sticker-pack`,
bundle ID `com.Quran.Elmallah.Islamic-Pillars.Stickers`. It is source-less: one Resources build phase carrying
[`Stickers.xcassets`](Stickers.xcassets), and nothing else.

- Info.plist: [`Resources/Info-Stickers.plist`](../Resources/Info-Stickers.plist) — declares the
  `com.apple.message-payload-provider` extension point with the system `StickerBrowserViewController`.
- The `iPhone` target depends on it and embeds `Stickers.appex` through **Embed Foundation Extensions**,
  so it rides along in every app build; there is no separate scheme to remember.
- `INFOPLIST_KEY_NSStickerSharingLevel = OS` lets stickers be shared out of Messages.

## The iMessage app icon

`iMessage App Icon.stickersiconset` is the icon Messages shows in its app drawer, and App Store
validation rejects a sticker extension without it. It needs **12 sizes**, most of them 4:3 rather than
square, so it cannot just reuse the app icon file.

All twelve are generated from `Assets.xcassets/AppIcon Phone/al-islam.png` (square 1024²). The square art is
aspect-fit and centred, and the letterbox bars are filled by **stretching the source's own edge columns**
outward rather than with a flat colour — the app icon's background is a left-to-right orange→green gradient,
so a single pad colour matches one side and clashes with the other. Extending the edges continues the
gradient and the floor strip seamlessly, and the letterboxing is invisible.

Regenerate them with `Stickers/mkstickericon.swift`:

```bash
xcrun swiftc -O Stickers/mkstickericon.swift -o /tmp/mkstickericon
/tmp/mkstickericon "Resources/Assets.xcassets/AppIcon Phone.appiconset/al-islam.png" \
                   "Stickers/Stickers.xcassets/iMessage App Icon.stickersiconset"
```

## Why these sizes

iMessage caps a sticker at **500 KB** and 618×618. The wallpapers ship at 542 KB – 1 MB and are not square, so each was scaled so its **longest** side is 618 and re-encoded as JPEG. Aspect ratio is preserved rather than cropped or letterboxed — a wallpaper sticker should show the whole wallpaper, and a tall sticker reads perfectly well in Messages.

The app icons are already square 1024², so they scale straight to 618² as PNG.

`grid-size` is `large`, matching the 618 px art. Changing it to `regular` or `small` makes Messages show more per row and downscale the images.

## Regenerating

If the wallpapers or icons change, rebuild the images with:

```bash
sips -s format png  -Z 618 "<icon>.jpg"      --out "<name>.png"
sips -s format jpeg -s formatOptions 80 -Z 618 "<wallpaper>.jpg" --out "<name>.jpg"
```

Then confirm every file is under 500 KB — Messages silently refuses oversized stickers.
