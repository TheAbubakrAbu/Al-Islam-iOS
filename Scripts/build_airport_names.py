#!/usr/bin/env python3
"""Build Resources/Data/Islam/AirportNames-<language>.tsv: the airports of Airports.tsv and their
cities, named in each language the app is translated into.

    ./Scripts/build_airport_names.py <airports.csv> <cache folder>

Airports.tsv (build_airports.py) carries OurAirports' English names. A traveler who reads the app
in Arabic types "جدة", not "Jeddah", and should read "مطار الملك عبدالعزيز الدولي" in the list. The names
come from Wikidata's labels (CC0), which are written by speakers of each language:

    the airport   the item behind the Wikipedia article OurAirports links for it, accepted only
                  when that item carries the same IATA code (P238) or lies within 20 km (P625),
                  so a link to a city or to another field never lends its name
    the city      the place that airport serves (P931), accepted only when its ENGLISH label is the
                  city OurAirports gives, so "Orange County" never stands in for "Santa Ana"

One file per language, one row per airport that has anything to say, tab separated:

    IATA  airport name  city name

Either name may be empty: the app then shows the English one. A label with no letter of the
language's own script (an English name copied across) is dropped, for the languages written in
Latin letters a label identical to the English is left out, since the English file already has it,
and so is an airport's label that is only its city's name.

Everything is asked of Wikidata's entity API (wbgetentities), fifty items a request: about a
hundred and fifty requests in all. Its SPARQL service would take four, but is rationed to a
request a minute whenever it is under load. The answers are cached in the folder given, so a
rerun asks nothing. Compress afterwards like every shipped file: ./Scripts/compress_shipped.py
"""
import csv
import json
import math
import os
import re
import sys
import time
import unicodedata
import urllib.parse
import urllib.request

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(REPO, "Resources", "Data", "Islam")
API = "https://www.wikidata.org/w/api.php"
SIZES = {"large_airport", "medium_airport", "small_airport"}

# Language code -> the Unicode script its names must be written in (None: Latin letters, any).
LANGUAGES = {
    "ar": "ARABIC", "ur": "ARABIC", "id": None, "ms": None, "tr": None, "fr": None, "bn": "BENGALI",
    "ru": "CYRILLIC", "hi": "DEVANAGARI", "de": None, "es": None, "ml": "MALAYALAM", "ta": "TAMIL",
    "nl": None,
}


def fetch(params):
    url = API + "?" + urllib.parse.urlencode(dict(params, format="json", maxlag="5"))
    request = urllib.request.Request(url, headers={
        "User-Agent": "airport-names-build/1.0 (offline data build script)",
        "Accept": "application/json",
    })
    last = None
    for attempt in range(8):
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                answer = json.load(response)
            if "entities" in answer:
                return answer["entities"]
            last = str(answer.get("error", answer))[:200]
        except Exception as error:
            last = error
        print(f"  waiting on Wikidata ({last})", flush=True)
        time.sleep(10 * (attempt + 1))
    sys.exit(f"Wikidata's entity API did not answer: {last}")


def cached(path, build):
    if os.path.exists(path):
        with open(path, encoding="utf-8") as handle:
            return json.load(handle)
    value = build()
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(value, handle, ensure_ascii=False)
    return value


def slim(entity):
    """What is kept of an item: its labels, its IATA codes, its coordinates, the places it serves."""
    claims = entity.get("claims", {})

    def values(prop):
        found = []
        for claim in claims.get(prop, []):
            value = claim.get("mainsnak", {}).get("datavalue", {}).get("value")
            if value is not None:
                found.append(value)
        return found

    return {
        "labels": {language: value["value"] for language, value in entity.get("labels", {}).items()},
        "iata": [value for value in values("P238") if isinstance(value, str)],
        "coords": [(value["latitude"], value["longitude"]) for value in values("P625") if isinstance(value, dict)],
        "serves": [value["id"] for value in values("P931") if isinstance(value, dict) and "id" in value],
    }


def by_article(site, titles):
    """The items behind Wikipedia articles, keyed by title."""
    found = {}
    wanted = "|".join(list(LANGUAGES) + ["en"])
    for start in range(0, len(titles), 50):
        batch = titles[start:start + 50]
        entities = fetch({"action": "wbgetentities", "sites": site, "titles": "|".join(batch),
                          "props": "labels|claims|sitelinks", "sitefilter": site, "languages": wanted})
        for qid, entity in entities.items():
            title = entity.get("sitelinks", {}).get(site, {}).get("title")
            if title and not qid.startswith("-"):
                found[title] = dict(slim(entity), id=qid)
        if start % 500 == 0:
            print(f"  {site}: {start + len(batch)} of {len(titles)}", flush=True)
        time.sleep(0.4)
    return found


def by_id(ids):
    found = {}
    wanted = "|".join(list(LANGUAGES) + ["en"])
    for start in range(0, len(ids), 50):
        batch = ids[start:start + 50]
        entities = fetch({"action": "wbgetentities", "ids": "|".join(batch), "props": "labels", "languages": wanted})
        for qid, entity in entities.items():
            found[qid] = {language: value["value"] for language, value in entity.get("labels", {}).items()}
        if start % 500 == 0:
            print(f"  cities: {start + len(batch)} of {len(ids)}", flush=True)
        time.sleep(0.4)
    return found


def fold(text):
    text = unicodedata.normalize("NFKD", text)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    return re.sub(r"[^a-z0-9]+", " ", text.lower()).strip()


def distance_km(lat1, lon1, lat2, lon2):
    p1, p2 = math.radians(lat1), math.radians(lat2)
    h = math.sin((p2 - p1) / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(math.radians(lon2 - lon1) / 2) ** 2
    return 2 * 6371 * math.asin(min(1, math.sqrt(h)))


def in_script(text, script):
    if script is None:
        return True
    return any(script in unicodedata.name(ch, "") for ch in text if ch.isalpha())


def clean(text):
    text = " ".join(text.replace("\t", " ").split())
    # No em dash reaches the app: between two words it is a comma, inside a compound a hyphen.
    text = text.replace(" \u2014 ", ", ").replace("\u2014", "-")
    return text


def same_city(wikidata_english, ours):
    """Whether Wikidata's place is the city OurAirports names: the same words, or ours with "City"
    after it ("New York City" for "New York"), or ours carrying more than Wikidata's ("Frankfurt am
    Main" for "Frankfurt"). Not a longer Wikidata name in general: "New York metropolitan area"
    is not the city."""
    a, b = fold(wikidata_english), fold(ours)
    if not a or not b:
        return False
    return a == b or a == b + " city" or b.startswith(a + " ")


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    source, cache = sys.argv[1], sys.argv[2]
    os.makedirs(cache, exist_ok=True)

    ours = {}
    articles = {}
    with open(source, newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            if row["type"] not in SIZES or not row["iata_code"] or row["scheduled_service"] != "yes":
                continue
            code = row["iata_code"]
            ours[code] = (float(row["latitude_deg"]), float(row["longitude_deg"]),
                          " ".join(row["municipality"].split()), " ".join(row["name"].split()))
            link = re.match(r"https?://([a-z\-]+)\.wikipedia\.org/wiki/([^#?]+)", row["wikipedia_link"].strip())
            if link:
                title = urllib.parse.unquote(link.group(2)).replace("_", " ").strip()
                articles.setdefault(link.group(1).replace("-", "_") + "wiki", {})[title] = code

    # Which Wikidata item is each of our airports: the one behind its Wikipedia article.
    def airports():
        found = {}
        for site, titles in sorted(articles.items()):
            for title, entity in by_article(site, sorted(titles)).items():
                code = titles.get(title)
                if code is not None:
                    found[code] = entity
        return found

    items = cached(os.path.join(cache, "airports.json"), airports)
    item_of = {}
    for code, entity in items.items():
        if code not in ours:
            continue
        near = any(distance_km(lat, lon, ours[code][0], ours[code][1]) <= 20 for lat, lon in entity["coords"])
        if code in entity["iata"] or near:
            item_of[code] = entity
    print(f"{len(ours)} airports, {len(item_of)} found on Wikidata and confirmed by code or place")

    served = sorted({city for entity in item_of.values() for city in entity["serves"]})
    cities = cached(os.path.join(cache, "cities.json"), lambda: by_id(served))

    city_of = {}
    for code, entity in item_of.items():
        matching = [city for city in entity["serves"] if same_city(cities.get(city, {}).get("en", ""), ours[code][2])]
        # The place with exactly our name before one that only begins like it.
        matching.sort(key=lambda city: fold(cities[city].get("en", "")) != fold(ours[code][2]))
        if matching:
            city_of[code] = cities[matching[0]]
    print(f"{len(city_of)} of them serve the city OurAirports names")

    for language, script in LANGUAGES.items():
        lines = []
        named = towns = 0
        for code in sorted(ours):
            english_city, english_name = ours[code][2], ours[code][3]
            name = clean(item_of[code]["labels"].get(language, "")) if code in item_of else ""
            city = clean(city_of[code].get(language, "")) if code in city_of else ""
            if not in_script(name, script) or (script is None and name == english_name):
                name = ""
            if not in_script(city, script) or (script is None and city == english_city):
                city = ""
            # An airport labelled with nothing but its city's name ("Каир") says less than the
            # English name does beside that city: the English one is kept.
            if name and name == (city or english_city):
                name = ""
            if not name and not city:
                continue
            named += bool(name)
            towns += bool(city)
            lines.append(f"{code}\t{name}\t{city}")
        path = os.path.join(OUT_DIR, f"AirportNames-{language}.tsv")
        with open(path, "w", encoding="utf-8") as handle:
            handle.write("\n".join(lines) + "\n")
        print(f"{language}: {named} airports and {towns} cities named, {os.path.getsize(path) // 1024} KB")


if __name__ == "__main__":
    main()
