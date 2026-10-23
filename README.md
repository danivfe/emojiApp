# Emojis 😀

Selector d'emojis per al Mac, en català, castellà i anglès.

## Com es fa servir

- **⌃⌥E** (Control + Opció + E) obre el selector des de qualsevol app. La drecera es pot canviar a la configuració.
- També s'obre clicant la icona 🙂 de la barra de menús. Amb el clic dret hi ha el menú amb la configuració i l'opció de sortir.
- Escriu per cercar, per exemple «cor», «riure», «cafe» o «gat». El nom anglès dels emojis també es pot fer servir.

| Tecla | Què fa |
|---|---|
| ↩ | Enganxa l'emoji a l'app on escrivies |
| ⌘↩ | Només el copia |
| ← → ↑ ↓ | Mou la selecció |
| ⇥ / ⇧⇥ | Salta a la secció següent / anterior |
| ⌘D | Afegeix o treu de preferits |
| ⌘, | Configuració |
| Esc | Esborra la cerca o tanca |

Amb el clic dret sobre un emoji pots triar un altre to de pell o afegir-li una paraula clau teva.

## Què inclou

- Preferits i recents.
- Combinacions: grups d'emojis o frases que s'enganxen d'un sol cop, com «Bon dia ☀️☕».
- Paraules clau pròpies: per exemple, que «visca» doni 🎉.
- Caràcters útils (l·l, «», €, →, ½…) i kaomojis ¯\\\_(ツ)\_/¯.
- To de pell preferit.
- Els meus emojis: imatges pròpies de `~/Library/Application Support/Emojis/Images` que s'enganxen com a imatge.

## Idiomes

L'app fa servir l'idioma del sistema, si és català, castellà o anglès. Si no, fa servir l'anglès. Es pot canviar a **Configuració › General › Idioma**.

Per afegir un idioma nou:
1. Afegeix-lo a `AppLanguage` i als textos de `Localization.swift`.
2. Afegeix-ne els noms a `Extras` (`Catalog.swift`).
3. Genera'n el fitxer `names-<codi>.json` amb `scripts/generate_emojis.py`.

## Permís d'Accessibilitat

Per enganxar l'emoji automàticament, l'app necessita el permís a **Configuració del Sistema › Privacitat i seguretat › Accessibilitat**. Sense aquest permís, l'emoji només es copia i l'has d'enganxar tu amb ⌘V.

Cada vegada que es recompila l'app, macOS pot oblidar aquest permís. Si deixa d'enganxar, treu Emojis de la llista i torna-la a afegir.

## Compilar

```bash
./scripts/build_app.sh --install
```

Compila l'app, la copia a `~/Applications/Emojis.app` i l'obre.

Les dades dels emojis (`Sources/Emojis/Resources/`) es generen amb `scripts/generate_emojis.py` a partir de les dades d'Unicode (`emoji-test.txt`) i dels noms de cada idioma del CLDR.

## Actualitzacions automàtiques

Cada dia, l'app comprova si hi ha una versió nova a les [Releases de GitHub](https://github.com/danivfe/emojiApp/releases). Si n'hi ha, pregunta si la vols instal·lar, la descarrega, substitueix l'app i la torna a obrir. També es pot comprovar a mà des del menú de la barra de menús o a **Configuració › General**.

Per publicar una versió nova:

```bash
./scripts/release.sh 1.2 "Què hi ha de nou"
```

L'script crea l'etiqueta `v1.2` amb les novetats i la puja a GitHub. Allà, un Mac de GitHub (GitHub Actions, `.github/workflows/release.yml`) compila l'app i els `.dmg` i publica la release. Tarda uns minuts i no cal instal·lar res. El número de versió de l'app surt de l'etiqueta.

Després d'una actualització, macOS pot oblidar el permís d'Accessibilitat. Cal tornar-lo a activar.

## Enviar-la a algú

```bash
./scripts/build_app.sh --dmg es
```

Crea `build/Emojis-es.dmg`, que funciona en Macs amb xip Apple i amb Intel (macOS 14 o més nou). L'idioma (`ca`, `es` o `en`) només canvia els textos de la finestra del `.dmg`: l'app és la mateixa en tots tres. Quan s'obre, apareix la típica finestra per arrossegar Emojis a Aplicacions.

L'app no està signada per Apple. Per això, la primera vegada que l'obri, l'altra persona haurà d'anar a **Configuració del Sistema › Privacitat i seguretat** i prémer **«Obre igualment»**. Aquestes instruccions també surten al fons de la finestra del `.dmg`.
