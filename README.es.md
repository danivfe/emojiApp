# Emojis 😀

[English](README.md) · [Català](README.ca.md) · **Español**

Un selector de emojis rápido para el Mac, en catalán, castellano e inglés.

## Instalación

Requiere macOS 14 (Sonoma) o posterior. Funciona en Macs con chip de Apple y con Intel.

1. Descarga `Emojis.dmg` de la [última versión](https://github.com/danivfe/emojiApp/releases/latest).
2. Abre el `.dmg` y arrastra **Emojis** a la carpeta **Applications** (Aplicaciones).
3. Abre Emojis. Como la app no está firmada por Apple, la primera vez el Mac la bloqueará:
   - Ve a **Ajustes del Sistema › Privacidad y seguridad**, baja hasta el final y pulsa **Abrir igualmente**.
4. Para que Emojis pueda pegar por ti, actívala en **Ajustes del Sistema › Privacidad y seguridad › Accesibilidad**. Sin este permiso, el emoji solo se copia y tienes que pegarlo tú con ⌘V.

Aparece un icono 🙂 en la barra de menús. Para abrir Emojis automáticamente al iniciar sesión, ve a **Ajustes › General**.

## Cómo se usa

- Pulsa **⌃⌥E** (Control + Opción + E) en cualquier app para abrir el selector. Puedes cambiar el atajo en los ajustes.
- También puedes hacer clic en el icono 🙂 de la barra de menús. Con el clic derecho encontrarás los ajustes, las actualizaciones y la opción de salir.
- Escribe para buscar, por ejemplo «corazón», «risa», «café» o «gato». Los nombres en inglés siempre funcionan, sea cual sea el idioma de la app.

| Tecla | Qué hace |
|---|---|
| ↩ | Pega el emoji en la app donde escribías |
| ⌘↩ | Solo lo copia |
| ← → ↑ ↓ | Mueve la selección |
| ⇥ / ⇧⇥ | Salta a la sección siguiente / anterior |
| ⌘D | Añade o quita de favoritos |
| ⌘, | Ajustes |
| Esc | Borra la búsqueda o cierra |

Con el clic derecho sobre un emoji puedes pegarlo con otro tono de piel o añadirle una palabra clave tuya.

## Qué incluye

- Favoritos y recientes.
- Combinaciones: grupos de emojis o frases que se pegan de una vez, como «Buenos días ☀️☕».
- Palabras clave propias: por ejemplo, que «olé» encuentre 💃 el primero.
- Caracteres útiles (€, →, ½, «», l·l…) y kaomojis ¯\\\_(ツ)\_/¯.
- Tono de piel preferido.
- Mis emojis: imágenes tuyas que se pegan como imagen en Mensajes, WhatsApp, Mail y otras apps. Puedes añadirlas en **Ajustes › Mis emojis**.

## Idiomas

Emojis usa el idioma del Mac si es catalán, castellano o inglés, y el inglés en caso contrario. Se puede cambiar en **Ajustes › General › Idioma**.

## Actualizaciones

Una vez al día, Emojis comprueba si hay una versión nueva en las [Releases de GitHub](https://github.com/danivfe/emojiApp/releases). Si la hay, pregunta si quieres instalarla, la descarga, se sustituye y se vuelve a abrir. También puedes comprobarlo a mano desde el icono de la barra de menús o en **Ajustes › General**.

Después de una actualización, el Mac puede olvidar el permiso de Accesibilidad. Si deja de pegar, vuelve a activarlo: quita Emojis de la lista de Accesibilidad y vuelve a añadirla.

## Desarrollo

Compila la app, la copia a `~/Applications` y la abre:

```bash
./scripts/build_app.sh --install
```

`./scripts/build_app.sh --dmg` crea el instalador, `build/Emojis.dmg`.

### Publicar una versión

```bash
./scripts/release.sh 1.2 "Novedades"
```

Crea la etiqueta `v1.2` con las novedades y la sube a GitHub. Entonces GitHub Actions (`.github/workflows/release.yml`) compila la app y el instalador y publica la release, lo que tarda unos minutos. El número de versión de la app sale de la etiqueta. Las apps instaladas encuentran la versión nueva en la siguiente comprobación diaria.

### Datos de los emojis

Los archivos de `Sources/Emojis/Resources/` se generan con `scripts/generate_emojis.py` a partir del `emoji-test.txt` de Unicode y de las anotaciones del CLDR de cada idioma. En la cabecera del script están los enlaces de descarga.

### Añadir un idioma

1. Añade un caso a `AppLanguage` y la traducción de cada texto en `Localization.swift`.
2. Añade los nombres en `Extras`, en `Catalog.swift`.
3. Genera `names-<código>.json` con `scripts/generate_emojis.py`.
