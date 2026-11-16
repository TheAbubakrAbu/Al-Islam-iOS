# Shared links: Al-Islam, Al-Quran, Al-Adhan

The app's "Share Link" makes addresses like

    https://theabubakrabu.github.io/alislam/?quran=2:255

On an iPhone, iPad or Mac with Al-Islam installed, iOS opens the app on that ayah. Everywhere else
the address is a small web page (`public/alislam/index.html`) that sends the visitor to the App
Store. Both halves depend on the files in `public/` being live at that host.

One site serves the three apps. Each has a folder of its own, named by the app's URL scheme:

    /alislam/    Al-Islam    the app makes and opens these links
    /alquran/    Al-Quran    the site side is ready; the app does not make or open links yet
    /aladhan/    Al-Adhan    the same

## Publishing

Everything in `public/` goes at the ROOT of the site, keeping the folder names:

    .nojekyll                                  lets GitHub Pages serve the dot folder below
    .well-known/apple-app-site-association     tells iOS which app owns which folder
    alislam/, alquran/, aladhan/               each app's page (index.html) and icon (icon.jpg)
    links.css, links.js                        what the three pages share
    index.html                                 the bare address: a list of the three apps
    404.html                                   sends /alislam/quran/2/255 style paths to that app's page
    README.md, .gitignore                      for the GitHub repository itself

GitHub Pages serves an account's own site from a PUBLIC repository named after the host,
`theabubakrabu.github.io`. A repository with any other name is served under a sub-path, where iOS
never looks for the association file, so it has to be this one.

`public/` is the source; the repository is only a copy of it:

    Website/publish.sh            copies public/ into ../theabubakrabu.github.io (beside this repository)
    Website/publish.sh --check    after a push: asks the live site, then Apple, for the files

After a change to `public/`: run `Website/publish.sh`, then commit and push that repository, then
run `Website/publish.sh --check`.

The association file must answer 200 with the JSON and no redirect. GitHub serves it as
`application/octet-stream`, which Apple accepts. iPhones do not ask the site for it: they ask
Apple, which fetches it and keeps a copy, so the first publish, or a later change, can take up to a
day to reach a phone. `--check` says whether Apple's copy is this one yet.

Setting the site up from nothing (done once, 2026-11-16): make the empty public repository on
github.com, run `Website/publish.sh`, then in `../theabubakrabu.github.io` run `git init -b main`,
`git add -A`, commit, `git remote add origin https://github.com/TheAbubakrAbu/theabubakrabu.github.io.git`
and `git push -u origin main`. GitHub turns Pages on by itself for a repository with this name.

## The app's side

Three things in each app name its link identity, and the Apple Developer account has to allow it:

- `AppIdentifiers.linkHost`, `linkScheme` and `linkPath` (iPhone/Settings/Model/Globals.swift). The
  scheme is derived from the app's name ("Al-Quran" gives `alquran`) and the path from the scheme,
  so the copy of that file each companion app receives names its own folder, not Al-Islam's.
- the scheme registered in `Resources/Info-Main.plist`, and `applinks:theabubakrabu.github.io` in
  the main app's entitlements (here `Entitlements-Main.entitlements` and
  `Entitlements-Main-CarPlay.entitlements`)
- the App ID needs the Associated Domains capability. Running the app on a phone from Xcode with
  automatic signing turns it on; so does ticking it for the App ID at developer.apple.com.

To try a link without a phone: install a build on a simulator, give it about twenty seconds to
fetch the association file, then
`xcrun simctl openurl <udid> "https://theabubakrabu.github.io/alislam/?quran=2:255"`.

## Al-Quran and Al-Adhan

Their folders, pages and association entries are here already, so nothing on the site has to change
when they gain the feature. What each app still needs is listed in
`Docs/Engineering/Sibling Sync Guide.md`, section 11: the shared code (it arrives with a port), its
own scheme in Info-Main.plist, the entitlement, and the two URL handlers in its root.

A new app is one more entry in the association file, one more folder with a page and an icon, its
name in `404.html` and `index.html`, its App Store number in `AppIdentifiers.appStoreIDs` (each page's
`data-store` has to match it), and its line in `AppLinkTests.testEachAppOwnsItsFolderOfTheSite`.

## Moving to another address

To use your own domain instead (say `links.example.com`), publish `public/` at that domain's root
and change the host in: `AppIdentifiers.linkHost`, the entitlements, the `og:image` address in each
app's page, and this file (with `public/README.md`). `publish.sh` reads the host from
`AppIdentifiers.linkHost` and refuses to copy while the entitlements or a page name a different one.
The `appIDs` lines in the association file are the team id plus each bundle id, and only change if
those do.

## What a link can carry

`quran=2` (a surah), `quran=2:255`, `hadith=bukhari` (a book), `hadith=muslim:8a`,
`article=pillars.shahadah`, `sunnah=`, `prophecy=`, `sign=`, `miracle=` (a page of those libraries),
`name=5`, `islam=zakahCalculator` (a resource of the Islam tab), `tab=settings`.
The grammar and its checks are in iPhone/Helpers/System/AppLink.swift, the same file in every app.
An app without the Quran or the hadith shelf opens its Islam tab for a link to one.
