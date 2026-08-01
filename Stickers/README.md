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

## Adding it to the project (needs Xcode)

A sticker pack is a separate **extension target**; it cannot just be dragged into the app target.

1. **File ▸ New ▸ Target… ▸ Sticker Pack Extension**. Name it `Al-Islam Stickers`. Xcode creates a folder with an `Info.plist` and an empty `Stickers.xcassets`.
2. **Delete the `Stickers.xcassets` Xcode generated**, and drag in [`Stickers.xcassets`](Stickers.xcassets) from this folder instead — *Copy items if needed*, target = the new sticker extension only.
3. Set the extension's **Display Name** to `Al-Islam` (this is the name shown in the iMessage drawer) and give it the same **Deployment Target** as the app.
4. Build and run the sticker target on a device or simulator — it launches Messages with the pack loaded.

Leave the `Info.plist` Xcode generates alone; it is target-specific and correct as generated. This folder deliberately contains only the asset catalog, which is the part with real content.

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
