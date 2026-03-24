#!/usr/bin/env python3
"""
build_temples_json.py
Reads the temple CSV, deduplicates, geocodes via Wikipedia API (batched),
fetches descriptions + image URLs, and writes temples.json.
"""

import csv, json, re, time, unicodedata, ssl
from collections import defaultdict
from pathlib import Path
import requests, certifi

# ── Paths ─────────────────────────────────────────────────────────────────────
REPO       = Path(__file__).parent.parent
CSV        = Path.home() / "Downloads" / "categories - temples2.csv"
OUT        = REPO / "PadYatra/Data/Static/temples.json"
CACHE      = Path(__file__).parent / "cache"
CACHE.mkdir(exist_ok=True)
WIKI_CACHE = CACHE / "wikipedia2.json"
GEO_CACHE  = CACHE / "geocode.json"   # keep old Nominatim hits (42 coords)

SESSION = requests.Session()
SESSION.headers["User-Agent"] = "PadYatra/1.0 (iOS app; contact@padyatra.app)"
SESSION.verify = certifi.where()

# ── Category map ──────────────────────────────────────────────────────────────
CAT_SLUGS = {
    "Shakti Peetha":                "c_shakti_peetha",
    "Jyotirlinga":                  "c_jyotirlinga",
    "Char Dham":                    "c_char_dham",
    "Chota Char Dham":              "c_chota_char_dham",
    "Ashta Vinayaka":               "c_ashta_vinayaka",
    "Pancha Kedar":                 "c_pancha_kedar",
    "Pancha Bhoota Lingas":         "c_pancha_bhoota_linga",
    "Pancha Sabhai":                "c_pancha_sabhai",
    "Pancha Kailash":               "c_pancha_kailash",
    "Pancha Badri":                 "c_pancha_badri",
    "Pancha Prayag":                "c_pancha_prayag",
    "Pancha Narasimha":             "c_pancha_narasimha",
    "Nava Graha":                   "c_nava_graha",
    "Nava Tirupati":                "c_nava_tirupati",
    "Sapta Puri":                   "c_sapta_puri",
    "Rama Circuit":                 "c_rama_circuit",
    "Krishna Circuit":              "c_krishna_circuit",
    "Hanuman Circuit":              "c_hanuman_circuit",
    "UNESCO Temple Site":           "c_unesco",
    "Rock-cut Temple":              "c_rock_cut",
    "Cave Temple":                  "c_cave_temple",
    "Hilltop Temple":               "c_hilltop",
    "Riverbank Temple":             "c_riverbank",
    "Chola Temple":                 "c_chola",
    "Pallava Temple":               "c_pallava",
    "Hoysala Temple":               "c_hoysala",
    "Vijayanagara Temple":          "c_vijayanagara",
    "Chandela Temple":              "c_chandela",
    "Solanki Temple":               "c_solanki",
    "Swayambhu Vishnu":             "c_swayambhu_vishnu",
    "ISKCON Temple":                "c_iskcon",
    "Ancient Temple (>1000 years)": "c_ancient_1000",
    "Largest Temple":               "c_largest",
    "Tallest Temple Tower":         "c_tallest_tower",
    "Oldest Functioning Temple":    "c_oldest_functioning",
    "Major Pilgrimage Center":      "c_major_pilgrimage",
    "Modern Major Pilgrimage Site": "c_modern_pilgrimage",
    "New Landmark Temple (2000+)":  "c_new_landmark",
}

# (name, iconAssetName, achievementID, color, deity, rarity)
CAT_META = {
    "c_jyotirlinga":         ("Jyotirlinga",            "flame.fill",              "a_jyotirlinga_complete",    "#FF6B35", "Shiva",   "legendary"),
    "c_shakti_peetha":       ("Shakti Peetha",           "sparkles",                "a_shakti_peetha_complete",  "#8B1A4A", "Shakti",  "legendary"),
    "c_char_dham":           ("Char Dham",               "building.columns.fill",   "a_char_dham_complete",      "#DAA520", "Vishnu",  "legendary"),
    "c_chota_char_dham":     ("Chota Char Dham",         "mountain.2.fill",         "a_chota_char_dham_complete","#5C8A3C", "Vishnu",  "epic"),
    "c_ashta_vinayaka":      ("Ashta Vinayaka",          "seal.fill",               "a_ashta_vinayaka_complete", "#E87722", "Ganesha", "epic"),
    "c_pancha_kedar":        ("Pancha Kedar",            "snowflake",               "a_pancha_kedar_complete",   "#4A90D9", "Shiva",   "epic"),
    "c_pancha_bhoota_linga": ("Pancha Bhoota Linga",    "flame",                   None,                        "#C0392B", "Shiva",   "epic"),
    "c_pancha_sabhai":       ("Pancha Sabhai",           "music.note",              None,                        "#9B59B6", "Shiva",   "rare"),
    "c_pancha_kailash":      ("Pancha Kailash",          "cloud.fill",              None,                        "#7F8C8D", "Shiva",   "epic"),
    "c_pancha_badri":        ("Pancha Badri",            "leaf.fill",               "a_pancha_badri_complete",   "#27AE60", "Vishnu",  "epic"),
    "c_pancha_prayag":       ("Pancha Prayag",           "water.waves",             None,                        "#2980B9", "Ganga",   "rare"),
    "c_pancha_narasimha":    ("Pancha Narasimha",        "shield.fill",             None,                        "#E67E22", "Vishnu",  "rare"),
    "c_nava_graha":          ("Nava Graha",              "moon.stars.fill",         "a_nava_graha_complete",     "#2C3E50", None,      "rare"),
    "c_nava_tirupati":       ("Nava Tirupati",           "star.fill",               None,                        "#F39C12", "Vishnu",  "rare"),
    "c_sapta_puri":          ("Sapta Puri",              "7.circle.fill",           "a_sapta_puri_complete",     "#8E44AD", None,      "epic"),
    "c_rama_circuit":        ("Rama Circuit",            "figure.walk",             None,                        "#3498DB", "Rama",    "rare"),
    "c_krishna_circuit":     ("Krishna Circuit",         "music.note",              None,                        "#1ABC9C", "Krishna", "rare"),
    "c_hanuman_circuit":     ("Hanuman Circuit",         "figure.arms.open",        None,                        "#E74C3C", "Hanuman", "rare"),
    "c_unesco":              ("UNESCO World Heritage",   "star.circle.fill",        None,                        "#F1C40F", None,      "epic"),
    "c_rock_cut":            ("Rock-cut Temple",         "diamond.fill",            None,                        "#95A5A6", None,      "common"),
    "c_cave_temple":         ("Cave Temple",             "circle.hexagonpath.fill", None,                        "#7D6608", None,      "common"),
    "c_hilltop":             ("Hilltop Temple",          "mountain.2.fill",         None,                        "#5D6D7E", None,      "common"),
    "c_riverbank":           ("Riverbank Temple",        "water.waves",             None,                        "#1A5276", None,      "common"),
    "c_chola":               ("Chola Temple",            "building.2.fill",         None,                        "#A04000", None,      "common"),
    "c_pallava":             ("Pallava Temple",          "building.2.fill",         None,                        "#784212", None,      "common"),
    "c_hoysala":             ("Hoysala Temple",          "building.2.fill",         None,                        "#6E2F1A", None,      "common"),
    "c_vijayanagara":        ("Vijayanagara Temple",     "building.2.fill",         None,                        "#922B21", None,      "common"),
    "c_chandela":            ("Chandela Temple",         "building.2.fill",         None,                        "#7B241C", None,      "common"),
    "c_solanki":             ("Solanki Temple",          "building.2.fill",         None,                        "#873600", None,      "common"),
    "c_swayambhu_vishnu":    ("Swayambhu Vishnu",        "seal.fill",               None,                        "#1F618D", "Vishnu",  "rare"),
    "c_iskcon":              ("ISKCON Temple",           "person.3.fill",           None,                        "#FFC300", "Krishna", "common"),
    "c_ancient_1000":        ("Ancient Temple",          "clock.fill",              None,                        "#6C3483", None,      "common"),
    "c_largest":             ("Largest Temples",         "building.fill",           None,                        "#117A65", None,      "rare"),
    "c_tallest_tower":       ("Tallest Temple Tower",    "arrow.up.circle.fill",    None,                        "#0E6655", None,      "rare"),
    "c_oldest_functioning":  ("Oldest Functioning",      "calendar.circle.fill",    None,                        "#4A235A", None,      "rare"),
    "c_major_pilgrimage":    ("Major Pilgrimage Center", "person.3.fill",           None,                        "#B7950B", None,      "common"),
    "c_modern_pilgrimage":   ("Modern Pilgrimage Site",  "mappin.circle.fill",      None,                        "#2E86C1", None,      "common"),
    "c_new_landmark":        ("New Landmark Temple",     "flag.fill",               None,                        "#1E8449", None,      "common"),
}

SIG_MAP = {
    "c_jyotirlinga":     "jyotirlinga",
    "c_shakti_peetha":   "shaktipeeth",
    "c_char_dham":       "charDham",
    "c_chota_char_dham": "charDham",
    "c_pancha_kedar":    "panchaKedar",
    "c_ashta_vinayaka":  "ashtavinayak",
    "c_nava_tirupati":   "divyaDesam",
}

DEITY_FESTIVALS = {
    "Shiva": [
        {"name": "Mahashivratri", "approximateMonth": 2, "isLunar": True,
         "description": "The great night of Shiva — all-night vigils, fasting and special abhisheka.", "significance": "high"},
        {"name": "Shravan Month", "approximateMonth": 7, "isLunar": True,
         "description": "Month-long special poojas and abhisheka during the holy month of Shravan.", "significance": "medium"},
    ],
    "Vishnu": [
        {"name": "Vaikuntha Ekadashi", "approximateMonth": 12, "isLunar": True,
         "description": "The most auspicious Ekadashi, celebrated with special darshan and all-night devotion.", "significance": "high"},
        {"name": "Brahmotsavam", "approximateMonth": 9, "isLunar": False,
         "description": "Grand annual festival with processions and elaborate rituals over several days.", "significance": "high"},
    ],
    "Krishna": [
        {"name": "Janmashtami", "approximateMonth": 8, "isLunar": True,
         "description": "Celebration of Krishna's birth with midnight prayers, devotional singing and fasting.", "significance": "high"},
        {"name": "Radhashtami", "approximateMonth": 9, "isLunar": True,
         "description": "Birth anniversary of Radha, celebrated with special devotional programmes.", "significance": "medium"},
    ],
    "Ganesha": [
        {"name": "Ganesh Chaturthi", "approximateMonth": 8, "isLunar": True,
         "description": "Ten-day festival celebrating Ganesha's birth with grand processions and daily poojas.", "significance": "high"},
        {"name": "Sankashti Chaturthi", "approximateMonth": None, "isLunar": True,
         "description": "Monthly observance with fasting and moonrise prayers.", "significance": "medium"},
    ],
    "Shakti": [
        {"name": "Navratri", "approximateMonth": 10, "isLunar": True,
         "description": "Nine nights of the goddess with special poojas, fasting and celebrations.", "significance": "high"},
        {"name": "Durga Puja", "approximateMonth": 10, "isLunar": True,
         "description": "Five-day festival with idol worship, cultural programmes and immersion.", "significance": "high"},
    ],
    "Hanuman": [
        {"name": "Hanuman Jayanti", "approximateMonth": 4, "isLunar": True,
         "description": "Celebration of Hanuman's birth with special poojas, recitation of Hanuman Chalisa and processions.", "significance": "high"},
    ],
    "Rama": [
        {"name": "Ram Navami", "approximateMonth": 4, "isLunar": True,
         "description": "Celebration of Rama's birth with special poojas, Ramayana recitations and processions.", "significance": "high"},
    ],
}

def get_festivals(deity):
    deity_clean = deity.split("/")[0].strip()
    for key, festivals in DEITY_FESTIVALS.items():
        if key.lower() in deity_clean.lower():
            return festivals
    return [{"name": "Annual Festival", "approximateMonth": None, "isLunar": False,
             "description": "Annual celebration with special poojas, processions and devotional programmes.", "significance": "medium"}]

# ── Helpers ───────────────────────────────────────────────────────────────────
def slugify(text):
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    text = re.sub(r"[^\w\s-]", "", text.lower())
    return re.sub(r"[\s_-]+", "-", text).strip("-")

def temple_id(name):
    s = slugify(name)
    s = re.sub(r"-(temple|mandir|mata|devi|swamy|kovil|peeth|shrine)$", "", s)
    return ("t_" + s.replace("-", "_"))[:42]

def load_cache(path):
    return json.loads(path.read_text()) if path.exists() else {}

def save_cache(path, data):
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False))

# ── Step 1: Parse & deduplicate CSV ──────────────────────────────────────────
print("Step 1: Parsing CSV...")
rows = []
with open(CSV, encoding="utf-8-sig") as f:
    reader = csv.DictReader(f)
    for row in reader:
        rows.append({k.strip(): v.strip() for k, v in row.items() if k})
print(f"  Total rows: {len(rows)}")

temples_map = {}
for row in rows:
    name  = row.get("name", "").strip()
    city  = row.get("city", "").strip()
    state = row.get("state", "").strip()
    if not name:
        continue
    # Normalise key: lowercase + remove common suffixes for better matching
    norm_name = re.sub(r"\s+(temple|mandir|mata|devi|kovil|peeth|shrine)$", "",
                       name.lower().strip(), flags=re.I)
    norm_state = state.lower().replace(" & ", " and ").replace("&", "and")
    norm_city  = city.lower().strip()
    key = (norm_name, norm_city, norm_state)
    if key not in temples_map:
        temples_map[key] = {
            "name": name,
            "city": city,
            "district": row.get("district", "").strip() or None,
            "state": state,
            "country": row.get("country", "India").strip(),
            "deity": row.get("primary_deity", "").strip(),
            "year_established": row.get("year_established", "").strip() or None,
            "historical_period": row.get("historical_period", "").strip() or None,
            "categories": set(),
        }
    cat = row.get("category", "").strip()
    if cat:
        temples_map[key]["categories"].add(cat)

unique_temples = list(temples_map.values())
print(f"  Unique temples: {len(unique_temples)}")

# Assign IDs (disambiguate collisions with city)
id_counts = defaultdict(list)
for t in unique_temples:
    id_counts[temple_id(t["name"])].append(t)
for tid, group in id_counts.items():
    if len(group) > 1:
        for t in group:
            t["_id"] = temple_id(t["name"] + " " + t["city"])
    else:
        group[0]["_id"] = tid

# ── Step 2: Wikipedia batch fetch (coords + extract + image) ─────────────────
print("\nStep 2: Fetching Wikipedia data in batches of 50...")
wiki_cache = load_cache(WIKI_CACHE)
geo_cache  = load_cache(GEO_CACHE)  # keep 42 Nominatim hits

BATCH = 50
todo = [t for t in unique_temples if t["_id"] not in wiki_cache]
print(f"  Need to fetch: {len(todo)}")

for batch_start in range(0, len(todo), BATCH):
    batch = todo[batch_start:batch_start + BATCH]
    titles = "|".join(t["name"] for t in batch)
    try:
        r = SESSION.get(
            "https://en.wikipedia.org/w/api.php",
            params={
                "action":    "query",
                "titles":    titles,
                "prop":      "coordinates|extracts|pageimages",
                "exintro":   "1",
                "explaintext": "1",
                "exsentences": "5",
                "piprop":    "original",
                "redirects": "1",
                "format":    "json",
            },
            timeout=20
        )
        data = r.json()
    except Exception as e:
        print(f"  !! batch {batch_start}: {e}")
        time.sleep(2)
        continue

    pages = data.get("query", {}).get("pages", {})

    # Build title→page map (normalized titles from redirects)
    redirects = {rd["from"].lower(): rd["to"].lower()
                 for rd in data.get("query", {}).get("redirects", [])}
    normalised = {n["from"].lower(): n["to"].lower()
                  for n in data.get("query", {}).get("normalized", [])}

    title_to_page = {}
    for page in pages.values():
        title_to_page[page.get("title", "").lower()] = page

    for t in batch:
        tid   = t["_id"]
        tname = t["name"].lower()
        # Follow normalization / redirect chain
        resolved = normalised.get(tname, tname)
        resolved = redirects.get(resolved, resolved)
        page = title_to_page.get(resolved) or title_to_page.get(tname)

        entry = {"extract": None, "lat": None, "lon": None,
                 "image_url": None, "source_url": None}

        if page and page.get("pageid", -1) != -1:
            coords = page.get("coordinates")
            if coords:
                entry["lat"] = round(coords[0]["lat"], 6)
                entry["lon"] = round(coords[0]["lon"], 6)
            entry["extract"]    = page.get("extract") or None
            orig = page.get("original")
            if orig:
                entry["image_url"] = orig.get("source")
            entry["source_url"] = (
                f"https://en.wikipedia.org/wiki/{page['title'].replace(' ', '_')}"
            )

        wiki_cache[tid] = entry

    print(f"  Fetched {min(batch_start + BATCH, len(todo))}/{len(todo)}")
    save_cache(WIKI_CACHE, wiki_cache)
    time.sleep(0.5)

# Merge Wikipedia coords into geo_cache for temples that Nominatim missed
for t in unique_temples:
    tid = t["_id"]
    w = wiki_cache.get(tid, {})
    if w.get("lat") and (not geo_cache.get(tid) or not geo_cache[tid]):
        geo_cache[tid] = {"lat": w["lat"], "lon": w["lon"]}
save_cache(GEO_CACHE, geo_cache)

# ── Step 3: Nominatim fallback for temples still missing coords ───────────────
missing_geo = [t for t in unique_temples
               if not geo_cache.get(t["_id"]) or not geo_cache[t["_id"]]]
print(f"\nStep 3: Nominatim fallback for {len(missing_geo)} temples without coords...")

for i, t in enumerate(missing_geo):
    tid = t["_id"]
    queries = [
        f"{t['name']}, {t['city']}, {t['state']}, India",
        f"{t['city']}, {t['state']}, India",
    ]
    for q in queries:
        try:
            r = SESSION.get(
                "https://nominatim.openstreetmap.org/search",
                params={"q": q, "format": "json", "limit": 1},
                timeout=10
            )
            if r.status_code == 200 and r.text.strip():
                data = r.json()
                if data:
                    geo_cache[tid] = {
                        "lat": round(float(data[0]["lat"]), 6),
                        "lon": round(float(data[0]["lon"]), 6),
                    }
                    break
        except Exception:
            pass
        time.sleep(1.2)

    if (i + 1) % 10 == 0:
        save_cache(GEO_CACHE, geo_cache)
        print(f"  Nominatim {i+1}/{len(missing_geo)}")

save_cache(GEO_CACHE, geo_cache)
geo_ok = sum(1 for t in unique_temples if geo_cache.get(t["_id"]) and geo_cache[t["_id"]])
print(f"  Coords resolved: {geo_ok}/{len(unique_temples)}")

# ── Step 4: Build categories ──────────────────────────────────────────────────
print("\nStep 4: Building categories...")
cat_temple_ids = defaultdict(list)
for t in unique_temples:
    for cat_name in t["categories"]:
        cat_id = CAT_SLUGS.get(cat_name)
        if cat_id:
            cat_temple_ids[cat_id].append(t["_id"])

categories = []
achievements = []
for sort_idx, (cat_id, meta) in enumerate(CAT_META.items()):
    cat_name, icon, achievement_id, color, deity, rarity = meta
    categories.append({
        "id":            cat_id,
        "name":          cat_name,
        "description":   f"Temples belonging to the {cat_name} pilgrimage circuit or classification.",
        "iconAssetName": icon,
        "color":         color,
        "deity":         deity,
        "sortOrder":     sort_idx,
        "templeIDs":     sorted(cat_temple_ids.get(cat_id, [])),
        "achievementID": achievement_id,
    })
    if achievement_id:
        achievements.append({
            "id":           achievement_id,
            "categoryID":   cat_id,
            "name":         f"Complete {cat_name}",
            "description":  f"Visit all temples in the {cat_name} pilgrimage circuit.",
            "iconAssetName": icon,
            "rarity":       rarity,
            "colors": {
                "locked":   "#9E9E9E",
                "unlocked": color,
            },
        })

# ── Step 5: Build temple objects ──────────────────────────────────────────────
print("Step 5: Building temple objects...")

def trim(text, max_len=600):
    if not text or len(text) <= max_len:
        return text
    cut = text[:max_len]
    dot = cut.rfind(".")
    return (cut[:dot + 1] if dot > max_len // 2 else cut.rstrip() + "…")

def short_desc(text, max_len=130):
    if not text:
        return None
    s = re.split(r"(?<=[.!?])\s", text, maxsplit=1)[0]
    return s if len(s) <= max_len else s[:max_len].rstrip() + "…"

def get_sig(cat_ids):
    for cid, sig in SIG_MAP.items():
        if cid in cat_ids:
            return sig
    return "other"

temples_out = []
for t in unique_temples:
    tid     = t["_id"]
    cat_ids = sorted({CAT_SLUGS[c] for c in t["categories"] if c in CAT_SLUGS})
    geo     = geo_cache.get(tid) or {}
    wiki    = wiki_cache.get(tid) or {}

    extract   = wiki.get("extract") or ""
    image_url = wiki.get("image_url")

    if not extract:
        extract = (f"{t['name']} is a Hindu temple located in {t['city']}, {t['state']}, India, "
                   f"dedicated to {t['deity']}. It dates to the {t['historical_period'] or 'ancient period'}.")

    temples_out.append({
        "id":               tid,
        "slug":             slugify(t["name"] + "-" + t["city"]),
        "legacyIDs":        [],
        "isActive":         True,
        "name":             t["name"],
        "alternateName":    None,
        "deity":            t["deity"],
        "location": {
            "latitude":  geo.get("lat"),
            "longitude": geo.get("lon"),
            "city":      t["city"],
            "district":  t["district"],
            "state":     t["state"],
            "country":   t["country"],
            "address":   None,
            "pincode":   None,
        },
        "categoryIDs":       cat_ids,
        "description":       trim(extract, 600),
        "shortDescription":  short_desc(extract, 130) or f"{t['name']}, {t['city']}",
        "facts": {
            "established":       t["year_established"],
            "dynasty":           t["historical_period"],
            "architectureStyle": None,
            "openingMonth":      None,
            "closingMonth":      None,
            "altitude":          None,
            "dresscode":         None,
            "photographyAllowed": None,
            "entryFee":          None,
            "darshanaTimings":   None,
        },
        "images": {
            "heroImageName":      f"{tid}_hero",
            "galleryImageNames":  [],
            "thumbnailImageName": f"{tid}_thumb",
            "remoteHeroURL":      image_url,
        },
        "festivals":    get_festivals(t["deity"]),
        "significance": get_sig(cat_ids),
        "isUNESCO":     "c_unesco" in cat_ids,
        "sourceURL":    wiki.get("source_url"),
    })

# ── Step 6: Write JSON ────────────────────────────────────────────────────────
print("Step 6: Writing temples.json...")
output = {
    "version":      4,
    "lastUpdated":  "2026-03-23",
    "categories":   categories,
    "achievements": achievements,
    "temples":      temples_out,
}
OUT.write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8")

geo_ok  = sum(1 for t in temples_out if t["location"]["latitude"])
wiki_ok = sum(1 for t in temples_out if t["images"]["remoteHeroURL"])
desc_ok = sum(1 for t in temples_out if (wiki_cache.get(t["id"]) or {}).get("extract"))
print(f"\n✅  temples: {len(temples_out)}  |  coords: {geo_ok}  |  wiki images: {wiki_ok}  |  descriptions: {desc_ok}  |  categories: {len(categories)}")
print(f"   Output: {OUT}")
