# Emojis 😀

Selector d'emojis per al Mac, en català.

## Com es fa servir

- **⌃⌥E** (Control + Opció + E) obre el selector des de qualsevol app. La drecera es pot canviar a la configuració.
- També s'obre clicant la icona 🙂 de la barra de menús. Amb el clic dret hi ha el menú amb la configuració i l'opció de sortir.
- Escriu per cercar en català, per exemple «cor», «riure», «cafe» o «gat».

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
- Els meus emojis: imatges pròpies de `~/Library/Application Support/Emojis/Els meus` que s'enganxen com a imatge.

## Permís d'Accessibilitat

Per enganxar l'emoji automàticament, l'app necessita el permís a **Configuració del Sistema › Privacitat i seguretat › Accessibilitat**. Sense aquest permís, l'emoji només es copia i l'has d'enganxar tu amb ⌘V.

Cada vegada que es recompila l'app, macOS pot oblidar aquest permís. Si deixa d'enganxar, treu Emojis de la llista i torna-la a afegir.

## Compilar

```bash
./scripts/build_app.sh --install
```

Compila l'app, la copia a `~/Applications/Emojis.app` i l'obre.

## Enviar-la a algú

```bash
./scripts/build_app.sh --dmg
```

Crea `build/Emojis.dmg`, que funciona en Macs amb xip Apple i amb Intel (macOS 14 o més nou). Quan s'obre, apareix la típica finestra per arrossegar Emojis a Aplicacions.

L'app no està signada per Apple. Per això, la primera vegada que l'obri, l'altra persona haurà d'anar a **Configuració del Sistema › Privacitat i seguretat** i prémer **«Obre igualment»**. Aquestes instruccions també surten al fons de la finestra del `.dmg`.

La llista d'emojis (`Sources/Emojis/Resources/emojis.json`) es genera amb `scripts/generate_emojis.py` a partir de les dades d'Unicode (`emoji-test.txt`) i dels noms en català del CLDR.
