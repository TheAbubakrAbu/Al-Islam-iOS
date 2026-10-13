# Al-Islam Stickers

An iMessage sticker pack: the three Al-Islam-family app icons and the four wallpapers the app already ships.

| Sticker | Source | Size | Corners |
|---|---|---:|---:|
| Al-Islam | `Resources/Images.xcassets/Apps/Al-Islam` | 618×618 | 138 |
| Al-Quran | `Resources/Images.xcassets/Apps/Al-Quran` | 618×618 | 138 |
| Al-Adhan | `Resources/Images.xcassets/Apps/Al-Adhan` | 618×618 | 138 |
| Phone Wallpaper | `Resources/Images.xcassets/Wallpapers` | 285×618 | 40 |
| Desktop Wallpaper | `Resources/Images.xcassets/Wallpapers` | 618×261 | 40 |
| Laptop Wallpaper | `Resources/Images.xcassets/Wallpapers` | 618×399 | 40 |
| Free Palestine | `Resources/Images.xcassets/Wallpapers` | 285×618 | 40 |

All seven are regenerated from art already in the app: nothing new was drawn, and nothing is borrowed from another project.
Every sticker has rounded corners (2026-10-13), so none of them lands in a conversation as a sharp-cornered rectangle.

## How it is wired up

This ships as the **`Stickers`** target, product type `com.apple.product-type.app-extension.messages-sticker-pack`,
bundle ID `com.Quran.Elmallah.Islamic-Pillars.Stickers`. It is source-less: one Resources build phase carrying
[`Stickers.xcassets`](Stickers.xcassets), and nothing else.

- Info.plist: [`Resources/Info-Stickers.plist`](../Resources/Info-Stickers.plist), which declares the
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
outward rather than with a flat colour: the app icon's background is a left-to-right orange→green gradient,
so a single pad colour matches one side and clashes with the other. Extending the edges continues the
gradient and the floor strip seamlessly, and the letterboxing is invisible.

Regenerate them with `Stickers/mkstickericon.swift`:

```bash
xcrun swiftc -O Stickers/mkstickericon.swift -o /tmp/mkstickericon
/tmp/mkstickericon "Resources/Assets.xcassets/AppIcon Phone.appiconset/al-islam.png" \
                   "Stickers/Stickers.xcassets/iMessage App Icon.stickersiconset"
```

## Why these sizes

iMessage caps a sticker at **500 KB** and 618×618. The wallpapers ship at 542 KB – 1 MB and are not square, so each is scaled so its **longest** side is 618. Aspect ratio is preserved rather than cropped or letterboxed: a wallpaper sticker should show the whole wallpaper, and a tall sticker reads perfectly well in Messages.

The app icons are already square 1024², so they scale straight to 618².

`grid-size` is `large`, matching the 618 px art. Changing it to `regular` or `small` makes Messages show more per row and downscale the images.

## Rounded corners

The corners are cut to transparency with continuous (squircle) curves, the shape iOS uses for app icons and screens, so every sticker is a **PNG**: JPEG has no alpha channel.

- The three app icons use a radius of **138 px**, 22.37% of 618: the home screen icon shape, so the sticker looks like the icon on the phone.
- The four wallpapers share one radius of **40 px**, so they look alike side by side in the drawer. On the 285 px phone wallpapers that is about a phone screen's own corner.

## Regenerating

If the wallpapers or icons change, rebuild the images with `Stickers/mkroundsticker.swift` (scales the longest side to 618, cuts the corners, writes PNG):

```bash
xcrun swiftc -O Stickers/mkroundsticker.swift -o /tmp/mkroundsticker
P="Stickers/Stickers.xcassets/Al-Islam.stickerpack"
/tmp/mkroundsticker "Resources/Images.xcassets/Apps/Al-Islam.imageset/al-islam.jpg" "$P/Al-Islam.sticker/Al-Islam.png" 138
/tmp/mkroundsticker "Resources/Images.xcassets/Wallpapers/Phone Wallpaper.dataset/Phone Wallpaper.jpg" \
                    "$P/Phone Wallpaper.sticker/Phone Wallpaper.png" 40
# ...and the same for the other five (radius 138 for an app icon, 40 for a wallpaper)
oxipng -o 4 --strip safe "$P"/*.sticker/*.png
```

Then confirm every file is under 500 KB; Messages silently refuses oversized stickers. Lossless oxipng brings
them to 152–369 KB today; if one ever goes over, `pngquant --quality 85-98` it rather than shrinking the art.
