#!/usr/bin/env python3
"""Genera Sources/Emojis/Resources/emojis.json a partir d'emoji-test.txt (Unicode)
i les anotacions en català del CLDR (annotations + annotationsDerived).

Ús: generate_emojis.py emoji-test.txt ca.json ca-derived.json sortida.json
"""
import json
import re
import sys

test_path, ca_path, ca_derived_path, out_path = sys.argv[1:5]

GROUPS_CA = {
    "Smileys & Emotion": "Cares i emocions",
    "People & Body": "Persones i cos",
    "Animals & Nature": "Animals i natura",
    "Food & Drink": "Menjar i beure",
    "Travel & Places": "Viatges i llocs",
    "Activities": "Activitats",
    "Objects": "Objectes",
    "Symbols": "Símbols",
    "Flags": "Banderes",
}
# Modificadors de to de pell, de més clar (1) a més fosc (5)
TONES = [0x1F3FB, 0x1F3FC, 0x1F3FD, 0x1F3FE, 0x1F3FF]


def load(path):
    data = json.load(open(path, encoding="utf-8"))
    return (data.get("annotations") or data["annotationsDerived"])["annotations"]


ann = load(ca_path)
for k, v in load(ca_derived_path).items():
    ann.setdefault(k, v)


def lookup(ch):
    return ann.get(ch) or ann.get(ch.replace("️", "")) or {}


line_re = re.compile(r"^([0-9A-F ]+?)\s*;\s*fully-qualified\s*#\s*(\S+)\s+E([\d.]+)\s+(.*)$")
emojis, by_key, group = [], {}, None

for line in open(test_path, encoding="utf-8"):
    if line.startswith("# group:"):
        group = line.split(":", 1)[1].strip()
        continue
    m = line_re.match(line)
    if not m or group not in GROUPS_CA:
        continue
    cps = [int(c, 16) for c in m.group(1).split()]
    ch = "".join(map(chr, cps))
    tones = [c for c in cps if c in TONES]
    key = tuple(c for c in cps if c not in TONES and c != 0xFE0F)

    if tones:
        # Les variants amb un sol to (👍🏽) es guarden dins l'emoji base
        base = by_key.get(key)
        if base is not None and len(set(tones)) == 1:
            base.setdefault("t", [None] * 5)[TONES.index(tones[0])] = ch
        continue

    a = lookup(ch)
    name = (a.get("tts") or [m.group(4)])[0]
    item = {
        "e": ch,
        "n": name,
        "k": [k for k in a.get("default", []) if k != name],
        "en": m.group(4),
        "v": float(m.group(3)),
        "g": GROUPS_CA[group],
    }
    emojis.append(item)
    by_key[key] = item

for item in emojis:
    if "t" in item and None in item["t"]:
        del item["t"]

json.dump(emojis, open(out_path, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
print(f"{len(emojis)} emojis, {sum('t' in i for i in emojis)} amb tons de pell -> {out_path}")
