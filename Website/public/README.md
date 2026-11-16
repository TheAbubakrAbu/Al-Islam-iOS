# theabubakrabu.github.io

The web side of the links shared from the Al-Islam, Al-Quran and Al-Adhan apps, such as

    https://theabubakrabu.github.io/alislam/?quran=2:255

With the app installed, the link opens that ayah, hadith or article in the app. Without it, the
app's page here leads to the App Store.

- `.well-known/apple-app-site-association` tells iOS which app owns which folder.
- `.nojekyll` lets GitHub Pages serve that dot folder. Do not remove it.
- `alislam/`, `alquran/`, `aladhan/` are the pages a visitor without the app sees, one per app.
- `links.css` and `links.js` are what those three pages share.
- `index.html` lists the three apps at the bare address.
- `404.html` hands links written as paths (`/alislam/quran/2/255`) to that app's page.

These files are copied here from the Al-Islam app's repository (`Website/public`, by
`Website/publish.sh`). Change them there, not here, or the next copy will undo the change.
