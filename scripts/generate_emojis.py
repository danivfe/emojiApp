#!/usr/bin/env python3
"""Genera les dades d'emojis de l'app a partir d'Unicode i del CLDR.

Sortida (a Sources/Emojis/Resources/):
  emojis.json        llista d'emojis en l'ordre d'Unicode, amb grup, versió i tons de pell
  names-<idioma>.json  nom i paraules clau de cada emoji en aquell idioma

Ús: generate_emojis.py emoji-test.txt carpeta_cldr carpeta_sortida ca es en

carpeta_cldr ha de tenir <idioma>.json i <idioma>-derived.json per a cada idioma:
  https://unicode.org/Public/emoji/latest/emoji-test.txt
  https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-annotations-full/annotations/<idioma>/annotations.json
  https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-annotations-derived-full/annotationsDerived/<idioma>/annotations.json
"""
import json
import os
import re
import sys

test_path, cldr_dir, out_dir, *languages = sys.argv[1:]

GROUPS = ["Smileys & Emotion", "People & Body", "Animals & Nature", "Food & Drink",
          "Travel & Places", "Activities", "Objects", "Symbols", "Flags"]
# Modificadors de to de pell, de més clar (1) a més fosc (5)
TONES = [0x1F3FB, 0x1F3FC, 0x1F3FD, 0x1F3FE, 0x1F3FF]


def load_annotations(lang):
    result = {}
    for suffix in ("", "-derived"):
        data = json.load(open(os.path.join(cldr_dir, f"{lang}{suffix}.json"), encoding="utf-8"))
        for k, v in (data.get("annotations") or data["annotationsDerived"])["annotations"].items():
            result.setdefault(k, v)
    return result


line_re = re.compile(r"^([0-9A-F ]+?)\s*;\s*fully-qualified\s*#\s*(\S+)\s+E([\d.]+)\s+(.*)$")
emojis, by_key, group = [], {}, None

for line in open(test_path, encoding="utf-8"):
    if line.startswith("# group:"):
        group = line.split(":", 1)[1].strip()
        continue
    m = line_re.match(line)
    if not m or group not in GROUPS:
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

    item = {"e": ch, "en": m.group(4), "v": float(m.group(3)), "g": group}
    emojis.append(item)
    by_key[key] = item

for item in emojis:
    if "t" in item and None in item["t"]:
        del item["t"]

os.makedirs(out_dir, exist_ok=True)
json.dump(emojis, open(os.path.join(out_dir, "emojis.json"), "w", encoding="utf-8"),
          ensure_ascii=False, separators=(",", ":"))
print(f"{len(emojis)} emojis, {sum('t' in i for i in emojis)} amb tons de pell")

for lang in languages:
    ann = load_annotations(lang)
    names, missing = {}, 0
    for item in emojis:
        a = ann.get(item["e"]) or ann.get(item["e"].replace("️", ""))
        if not a:
            missing += 1
            continue
        name = (a.get("tts") or [item["en"]])[0]
        names[item["e"]] = {"n": name, "k": [k for k in a.get("default", []) if k != name]}
    json.dump(names, open(os.path.join(out_dir, f"names-{lang}.json"), "w", encoding="utf-8"),
              ensure_ascii=False, separators=(",", ":"))
    print(f"  {lang}: {len(names)} noms ({missing} sense traducció)")
