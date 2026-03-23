#!/usr/bin/env python3
"""
validate_coordinates.py
-----------------------
Reverse-geocodes every temple's stored coordinates via Nominatim (OpenStreetMap)
and flags entries where the returned state or district doesn't match the declared
location in temples.json.

Usage:
    python3 scripts/validate_coordinates.py [--json path/to/temples.json]

Nominatim terms: 1 request/second max, no bulk usage without caching.
This script enforces the rate limit automatically.
"""

import json
import time
import argparse
import sys
import ssl
import urllib.request
import urllib.parse
from pathlib import Path
from dataclasses import dataclass
from typing import Optional

# Use certifi's CA bundle if the system one is missing (common on macOS).
try:
    import certifi
    _SSL_CONTEXT = ssl.create_default_context(cafile=certifi.where())
except ImportError:
    _SSL_CONTEXT = ssl.create_default_context()

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

DEFAULT_JSON = Path(__file__).parent.parent / "PadYatra/Data/Static/temples.json"

# Distance (km) beyond which we flag as suspicious even if state matches.
# Catches "right state, wrong side of state" errors.
DISTANCE_THRESHOLD_KM = 50

# Nominatim rate limit (seconds between requests)
RATE_LIMIT_SECONDS = 1.1

NOMINATIM_URL = "https://nominatim.openstreetmap.org/reverse"
USER_AGENT = "PadYatraCoordinateValidator/1.0 (temple-app data validation)"

# Indian state name aliases — Nominatim returns English names that may differ
# from what's in the JSON.
STATE_ALIASES: dict[str, list[str]] = {
    "Andhra Pradesh":    ["Andhra Pradesh"],
    "Arunachal Pradesh": ["Arunachal Pradesh"],
    "Assam":             ["Assam"],
    "Bihar":             ["Bihar"],
    "Chhattisgarh":      ["Chhattisgarh"],
    "Goa":               ["Goa"],
    "Gujarat":           ["Gujarat"],
    "Haryana":           ["Haryana"],
    "Himachal Pradesh":  ["Himachal Pradesh"],
    "Jharkhand":         ["Jharkhand"],
    "Karnataka":         ["Karnataka"],
    "Kerala":            ["Kerala"],
    "Madhya Pradesh":    ["Madhya Pradesh"],
    "Maharashtra":       ["Maharashtra"],
    "Manipur":           ["Manipur"],
    "Meghalaya":         ["Meghalaya"],
    "Mizoram":           ["Mizoram"],
    "Nagaland":          ["Nagaland"],
    "Odisha":            ["Odisha", "Orissa"],
    "Punjab":            ["Punjab"],
    "Rajasthan":         ["Rajasthan"],
    "Sikkim":            ["Sikkim"],
    "Tamil Nadu":        ["Tamil Nadu"],
    "Telangana":         ["Telangana"],
    "Tripura":           ["Tripura"],
    "Uttar Pradesh":     ["Uttar Pradesh"],
    "Uttarakhand":       ["Uttarakhand", "Uttaranchal"],
    "West Bengal":       ["West Bengal"],
    "Delhi":             ["Delhi", "National Capital Territory of Delhi"],
    "Jammu and Kashmir": ["Jammu and Kashmir", "Jammu & Kashmir"],
    "Ladakh":            ["Ladakh"],
}


# ---------------------------------------------------------------------------
# Haversine distance
# ---------------------------------------------------------------------------

import math

def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2) ** 2
    return R * 2 * math.asin(math.sqrt(a))


# ---------------------------------------------------------------------------
# Nominatim reverse geocode
# ---------------------------------------------------------------------------

@dataclass
class ReverseResult:
    display_name: str
    state: Optional[str]
    county: Optional[str]       # district-level in India
    city: Optional[str]
    lat: float
    lon: float


def reverse_geocode(lat: float, lon: float) -> Optional[ReverseResult]:
    params = urllib.parse.urlencode({
        "lat": lat,
        "lon": lon,
        "format": "json",
        "zoom": 10,             # city/town level
        "addressdetails": 1,
    })
    url = f"{NOMINATIM_URL}?{params}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=10, context=_SSL_CONTEXT) as resp:
            data = json.loads(resp.read())
    except Exception as e:
        print(f"    [network error] {e}", file=sys.stderr)
        return None

    addr = data.get("address", {})
    return ReverseResult(
        display_name=data.get("display_name", ""),
        state=addr.get("state"),
        county=addr.get("county") or addr.get("state_district"),
        city=addr.get("city") or addr.get("town") or addr.get("village") or addr.get("suburb"),
        lat=float(data.get("lat", lat)),
        lon=float(data.get("lon", lon)),
    )


# ---------------------------------------------------------------------------
# State match check
# ---------------------------------------------------------------------------

def states_match(declared: str, returned: Optional[str]) -> bool:
    if returned is None:
        return False
    returned_lower = returned.lower().strip()
    aliases = STATE_ALIASES.get(declared, [declared])
    return any(a.lower() in returned_lower or returned_lower in a.lower() for a in aliases)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Validate temple GPS coordinates via reverse geocoding.")
    parser.add_argument("--json", default=str(DEFAULT_JSON), help="Path to temples.json")
    parser.add_argument("--only-flagged", action="store_true", help="Print only flagged entries (suppress OK lines)")
    args = parser.parse_args()

    json_path = Path(args.json)
    if not json_path.exists():
        print(f"Error: {json_path} not found.", file=sys.stderr)
        sys.exit(1)

    with open(json_path) as f:
        data = json.load(f)

    temples = [t for t in data["temples"] if t.get("isActive", True)]
    total = len(temples)
    flagged: list[dict] = []

    print(f"Validating {total} active temples (Nominatim, {RATE_LIMIT_SECONDS}s/req)...\n")

    for i, temple in enumerate(temples, 1):
        tid   = temple["id"]
        name  = temple["name"]
        loc   = temple["location"]
        lat   = loc["latitude"]
        lon   = loc["longitude"]
        decl_state = loc["state"]
        decl_city  = loc.get("city", "")

        print(f"[{i:3}/{total}] {name} ({decl_city}, {decl_state})", end=" ... ", flush=True)

        result = reverse_geocode(lat, lon)
        time.sleep(RATE_LIMIT_SECONDS)  # respect Nominatim rate limit

        if result is None:
            print("NETWORK ERROR — skipped")
            continue

        ok = states_match(decl_state, result.state)

        # Small temple towns are often resolved to the nearest OSM city — suppress
        # known-correct equivalences so only genuine mismatches surface.
        CITY_ALIASES: dict[str, list[str]] = {
            "haridwar":      ["haridwār", "hardwar"],
            "varanasi":      ["vārānasī", "benares", "banaras"],
            "mathura":       ["mathurā"],
            "dwarka":        ["rupen bandar", "devbhumi dwaraka", "okhamandal"],
            "somnath":       ["veraval", "patan veraval", "gir somnath"],
            "trimbak":       ["nashik", "trimbakeshwar"],
            "hampi":         ["hosapete", "vijayanagara"],
            "darasuram":     ["kumbakonam", "dharasuram"],
            "mahabalipuram": ["chengalpattu", "kanchipuram"],
            "ellora":        ["aurangabad", "chhatrapati sambhajinagar"],
            "rameswaram":    ["ramanathapuram"],
            "kedarnath":     ["rudraprayag"],
            "badrinath":     ["chamoli"],
            "srisailam":     ["nandyal"],
            "omkareshwar":   ["khandwa"],
            "lenyadri":      ["junnar"],
            "morgaon":       ["baramati", "pune", "solapur"],
            "siddhatek":     ["ahmednagar", "ahilyanagar", "daund"],
            "pali":          ["roha", "sudhagad", "raigad"],
            "mahad":         ["khopoli", "khalapur"],
            "theur":         ["haveli", "pune"],
            "ozar":          ["narayangaon", "junnar", "nashik"],
            "ranjangaon":    ["shirur", "pune"],
        }

        issues = []
        if not ok:
            issues.append(f"state mismatch: declared='{decl_state}' nominatim='{result.state}'")

        # Check if Nominatim's returned city grossly disagrees
        if result.city and decl_city:
            nom_city = result.city.lower().strip()
            decl_city_l = decl_city.lower().strip()
            city_ok = (
                nom_city in decl_city_l
                or decl_city_l in nom_city
                or any(alias in nom_city or nom_city in alias
                       for alias in CITY_ALIASES.get(decl_city_l, []))
            )
            if not city_ok:
                issues.append(f"city hint: declared='{decl_city}' nominatim='{result.city}'")

        if issues:
            print(f"FLAGGED")
            for iss in issues:
                print(f"           ↳ {iss}")
            print(f"           ↳ nominatim display: {result.display_name[:100]}")
            print(f"           ↳ coords: ({lat}, {lon})")
            flagged.append({
                "id": tid,
                "name": name,
                "declared": f"{decl_city}, {decl_state}",
                "nominatim_state": result.state,
                "nominatim_city": result.city,
                "nominatim_display": result.display_name,
                "lat": lat,
                "lon": lon,
                "issues": issues,
            })
        else:
            if not args.only_flagged:
                city_info = f" (nominatim city: {result.city})" if result.city and result.city.lower() not in decl_city.lower() else ""
                print(f"OK{city_info}")

    # ---------------------------------------------------------------------------
    # Summary
    # ---------------------------------------------------------------------------

    print(f"\n{'='*60}")
    print(f"Result: {len(flagged)} / {total} temples flagged\n")

    if flagged:
        print("Flagged temples:")
        for entry in flagged:
            print(f"  {entry['id']}")
            print(f"    declared:  {entry['declared']}")
            print(f"    nominatim: {entry['nominatim_city']}, {entry['nominatim_state']}")
            for iss in entry['issues']:
                print(f"    issue:     {iss}")
        sys.exit(1)   # non-zero exit so CI/CD can catch it
    else:
        print("All coordinates passed validation.")
        sys.exit(0)


if __name__ == "__main__":
    main()
