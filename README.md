# Confession of a Barjo

> A blog built with Elm and Pico CSS

No backend — Elm renders markdown posts with syntax highlighting,
deployed as a static SPA on GitHub Pages.

## Stack

- [Elm 0.19](https://elm-lang.org/) — routing, rendering, the whole thing
- [Pico CSS](https://picocss.com/) — classless CSS framework
- [IBM Plex](https://www.ibm.com/plex/) — Sans + Mono
- [elm-markdown](https://package.elm-lang.org/packages/dillonkearns/elm-markdown/latest/) + [elm-syntax-highlight](https://package.elm-lang.org/packages/pablohirafuji/elm-syntax-highlight/latest/) — markdown and code blocks

## Getting started

```
npm install
make watch
```

Requires Node.js 22+ (see `.tool-versions`) and `jq` for `make post`.

## Commands

```
make help       # list all targets
make build      # compile, minify → build/
make watch      # dev server with live reload
make format     # elm-format on src/
make clean      # remove build artifacts
make post       # create a new post
```

## Project structure

```
src/
  Main.elm      # entry point, routing, update loop
  Post.elm      # post type, decoder, HTTP
  Route.elm     # URL parsing, page types
  View.elm      # all views and components
  Render.elm    # markdown renderer with syntax highlighting
  Icon.elm      # inline SVG icons
public/
  index.html    # shell, theme detection + toggle
  style.css     # Carina Nebula theme, Pico overrides
  favicon.svg
  posts/
    index.json  # post metadata
    *.md        # post content
```

## Adding a post

`make post` prompts for a title, generates a slug, creates the markdown file
and adds the entry to `posts/index.json`.

## Deployment

Push to `main` triggers a GitHub Action that builds and deploys to GitHub Pages.
See `.github/workflows/deploy.yml`.

## Scaling note

All post metadata lives in a single `index.json` (~150 bytes per entry).
Past ~300 posts, consider splitting by year (`posts/2025/index.json`, etc.)
and loading on demand.
