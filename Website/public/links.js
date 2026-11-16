// Shared by the three apps' links pages (/alislam/, /alquran/, /aladhan/). Each page says which
// app it is on its <main>: data-app (the name), data-scheme (the app's own URL scheme, which is
// also its folder here) and data-store (its App Store id). The link grammar is the same in all
// three apps (iPhone/Helpers/System/AppLink.swift).
(function () {
  "use strict";
  var main = document.querySelector("main[data-scheme]");
  if (!main) return;
  var APP = main.getAttribute("data-app");
  var SCHEME = main.getAttribute("data-scheme");
  var STORE = "https://apps.apple.com/app/id" + main.getAttribute("data-store");
  var BOOKS = {
    bukhari: "Sahih al-Bukhari", muslim: "Sahih Muslim", ibnmajah: "Sunan Ibn Majah",
    abudawud: "Sunan Abi Dawud", tirmidhi: "Jami‘ at-Tirmidhi", nasai: "Sunan an-Nasa’i",
    malik: "Muwatta Malik", ahmed: "Musnad Ahmad", darimi: "Sunan ad-Darimi",
    qudsi40: "Forty Hadith Qudsi", nawawi40: "The Forty Hadith of Imam Nawawi",
    shahwaliullah40: "Forty Hadith of Shah Waliullah", aladab_almufrad: "Al-Adab Al-Mufrad",
    shamail_muhammadiyah: "Shama’il Muhammadiyah", riyad_assalihin: "Riyad as-Salihin",
    mishkat_almasabih: "Mishkat al-Masabih", bulugh_almaram: "Bulugh al-Maram"
  };
  var RESOURCES = {
    arabicalphabet: "Arabic Alphabet", tajweedfoundations: "Tajweed Foundations", tajweedcourse: "Tajweed Course",
    commonadhkar: "Dhikr & Remembrances", commonduas: "Dua & Supplications", tasbihcounter: "Tasbih Counter",
    namesofallah: "99 Names of Allah", zakahcalculator: "Zakah Calculator",
    inheritancecalculator: "Inheritance Calculator", hijricalendarconverter: "Hijri Date Converter",
    masjidlocator: "Masjid Locator", halalfoodlocator: "Halal Food Locator", islamicwallpapers: "Islamic Wallpapers",
    pillarsandbasics: "Pillars & Beliefs", howtoguides: "How-To Guides", miraclesofquran: "Miracles of the Quran",
    miraclesofprophets: "Miracles of the Prophets", propheciesofprophet: "Prophecies of the Prophet",
    sunnahsofprophet: "Sunnahs of the Prophet", provingislam: "Proving Islam", askai: "Ask AI"
  };
  var KINDS = ["quran", "hadith", "article", "sunnah", "prophecy", "sign", "miracle", "name", "islam", "tab"];
  var SAFE = /^[A-Za-z0-9._:\-]{1,96}$/;

  // The link is one key=value pair. An older or hand-made link may carry it as a path
  // (/alislam/quran/2/255, which 404.html hands over after a #); both are read the same way.
  function pair() {
    var query = new URLSearchParams(location.search);
    for (var i = 0; i < KINDS.length; i++) {
      var value = query.get(KINDS[i]);
      if (value && SAFE.test(value)) return [KINDS[i], value];
    }
    var rest = location.hash.replace(/^#\/?/, "");
    var parts = rest.split("/").filter(Boolean);
    if (parts.length > 1 && KINDS.indexOf(parts[0].toLowerCase()) >= 0) {
      var joined = parts.slice(1).join(":");
      if (SAFE.test(joined)) return [parts[0].toLowerCase(), joined];
    }
    return null;
  }

  function describe(kind, value) {
    var lower = value.toLowerCase();
    if (kind === "quran") {
      var q = value.split(/[:.\-]/);
      return q.length > 1 ? ["Quran " + q[0] + ":" + q[1], "An ayah of the Quran."] : ["Surah " + q[0], "A surah of the Quran."];
    }
    if (kind === "hadith") {
      var cut = lower.indexOf(":");
      var slug = cut < 0 ? lower : lower.slice(0, cut);
      var ref = cut < 0 ? "" : lower.slice(cut + 1);
      var book = BOOKS[slug] || "A hadith";
      if (!ref || ref.indexOf("id-") === 0) return [book, cut < 0 ? "A book of hadith." : "A hadith."];
      if (ref.indexOf("intro-") === 0) return [book + ", Introduction " + ref.slice(6), "A hadith."];
      return [book + " " + ref, "A hadith."];
    }
    if (kind === "name") return ["The 99 Names of Allah", "Name " + value + " of the 99."];
    if (kind === "islam") return [RESOURCES[lower] || APP, "A page of " + APP + "."];
    if (kind === "article") return ["An article", "From Pillars & Beliefs, the How-To Guides or Proving Islam."];
    if (kind === "sunnah") return ["A sunnah of the Prophet ﷺ", "From Sunnahs of the Prophet."];
    if (kind === "prophecy") return ["A prophecy of the Prophet ﷺ", "From Prophecies of the Prophet."];
    if (kind === "sign") return ["A sign given to the prophets", "From Miracles of the Prophets."];
    if (kind === "miracle") return ["A miracle of the Quran", "From Miracles of the Quran."];
    return ["Open in " + APP, ""];
  }

  var found = pair();
  var open = document.getElementById("open");
  if (found) {
    var text = describe(found[0], found[1]);
    document.getElementById("what").textContent = text[0];
    document.title = text[0] + " · " + APP;
    if (text[1]) {
      document.getElementById("about").textContent =
        text[1] + " It opens in " + APP + ", a free app for iPhone, iPad, Mac and Apple Watch.";
    }
    open.href = SCHEME + "://open?" + encodeURIComponent(found[0]) + "=" + encodeURIComponent(found[1]).replace(/%3A/g, ":");
  }

  // An iPhone or iPad that reaches this page does not have the app (with the app, the link opens
  // it and this page never loads), so it goes on to the App Store. Once per visit: coming back
  // from the store leaves the page and its two buttons in place.
  var ua = navigator.userAgent || "";
  var handheld = /iPhone|iPad|iPod/.test(ua) || (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1);
  var seen = false;
  try { seen = sessionStorage.getItem(SCHEME + "-store") === "1"; sessionStorage.setItem(SCHEME + "-store", "1"); } catch (e) {}
  if (handheld && !seen) {
    document.getElementById("note").textContent = "Taking you to the App Store…";
    var timer = setTimeout(function () { location.href = STORE; }, 1600);
    open.addEventListener("click", function () {
      clearTimeout(timer);
      document.getElementById("note").textContent = "";
    });
  }
})();
