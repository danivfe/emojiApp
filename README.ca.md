# Emojis 😀

[English](README.md) · **Català** · [Español](README.es.md)

Un selector d'emojis ràpid per al Mac, en català, castellà i anglès.

## Instal·lació

Cal macOS 14 (Sonoma) o posterior. Funciona en Macs amb xip Apple i amb Intel.

1. Descarrega `Emojis.dmg` de l'[última versió](https://github.com/danivfe/emojiApp/releases/latest).
2. Obre el `.dmg` i arrossega **Emojis** a la carpeta **Applications** (Aplicacions).
3. Obre Emojis. Com que l'app no està signada per Apple, la primera vegada el Mac la bloquejarà:
   - Ves a **Configuració del Sistema › Privacitat i seguretat**, baixa fins a baix i prem **Obre igualment**.
4. Perquè Emojis pugui enganxar per tu, activa-la a **Configuració del Sistema › Privacitat i seguretat › Accessibilitat**. Sense aquest permís, l'emoji només es copia i l'has d'enganxar tu amb ⌘V.

Apareix una icona 🙂 a la barra de menús. Per obrir Emojis automàticament en iniciar la sessió, ves a **Configuració › General**.

## Com es fa servir

- Prem **⌃⌥E** (Control + Opció + E) en qualsevol app per obrir el selector. Pots canviar la drecera a la configuració.
- També pots clicar la icona 🙂 de la barra de menús. Amb el clic dret hi trobaràs la configuració, les actualitzacions i l'opció de sortir.
- Escriu per cercar, per exemple «cor», «riure», «cafè» o «gat». Els noms en anglès sempre funcionen, sigui quin sigui l'idioma de l'app.

| Tecla | Què fa |
|---|---|
| ↩ | Enganxa l'emoji a l'app on escrivies |
| ⌘↩ | Només el copia |
| ← → ↑ ↓ | Mou la selecció |
| ⇥ / ⇧⇥ | Salta a la secció següent / anterior |
| ⌘D | Afegeix o treu de preferits |
| ⌘, | Configuració |
| Esc | Esborra la cerca o tanca |

Amb el clic dret sobre un emoji el pots enganxar amb un altre to de pell o afegir-li una paraula clau teva.

## Què inclou

- Preferits i recents.
- Combinacions: grups d'emojis o frases que s'enganxen d'un sol cop, com «Bon dia ☀️☕».
- Paraules clau pròpies: per exemple, que «visca» trobi 🎉 el primer.
- Caràcters útils (€, →, ½, «», l·l…) i kaomojis ¯\\\_(ツ)\_/¯.
- To de pell preferit.
- Els meus emojis: imatges teves que s'enganxen com a imatge a Missatges, WhatsApp, Mail i altres apps. Les pots afegir a **Configuració › Els meus emojis**.

## Idiomes

Emojis fa servir l'idioma del Mac si és català, castellà o anglès, i l'anglès en cas contrari. Es pot canviar a **Configuració › General › Idioma**.

## Actualitzacions

Un cop al dia, Emojis comprova si hi ha una versió nova a les [Releases de GitHub](https://github.com/danivfe/emojiApp/releases). Si n'hi ha, pregunta si la vols instal·lar, la descarrega, se substitueix i es torna a obrir. També ho pots comprovar a mà des de la icona de la barra de menús o a **Configuració › General**.

Després d'una actualització, el Mac pot oblidar el permís d'Accessibilitat. Si deixa d'enganxar, torna'l a activar: treu Emojis de la llista d'Accessibilitat i torna-la a afegir.

## Desenvolupament

Compila l'app, la copia a `~/Applications` i l'obre:

```bash
./scripts/build_app.sh --install
```

`./scripts/build_app.sh --dmg` crea l'instal·lador, `build/Emojis.dmg`.

### Publicar una versió

```bash
./scripts/release.sh 1.2 "Què hi ha de nou"
```

Crea l'etiqueta `v1.2` amb les novetats i la puja a GitHub. Llavors GitHub Actions (`.github/workflows/release.yml`) compila l'app i l'instal·lador i publica la release, cosa que tarda uns minuts. El número de versió de l'app surt de l'etiqueta. Les apps instal·lades troben la versió nova en la següent comprovació diària.

### Dades dels emojis

Els fitxers de `Sources/Emojis/Resources/` es generen amb `scripts/generate_emojis.py` a partir de l'`emoji-test.txt` d'Unicode i de les anotacions del CLDR de cada idioma. A la capçalera de l'script hi ha els enllaços de descàrrega.

### Afegir un idioma

1. Afegeix un cas a `AppLanguage` i la traducció de cada text a `Localization.swift`.
2. Afegeix-ne els noms a `Extras`, a `Catalog.swift`.
3. Genera `names-<codi>.json` amb `scripts/generate_emojis.py`.
