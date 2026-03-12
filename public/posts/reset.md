I haven't touched my blog in years, and I always wanted to make a simple static version. It's really
easy and fast to write code nowadays, so I didn't really have an excuse not to do it ^_^'

## How it works

Since I spend a lot of time on GitHub for work & co, it made sense to use GitHub Pages to host it.

I also wanted to have something simple but still enjoyable to build. I end up going with the following:

- [Elm](https://elm-lang.org) - writing the engine in Elm keeps things fun and functional
- [Pico CSS](https://picocss.com) - lightweight, minimal styling with zero classes

I considered using [ReScript](https://rescript-lang.org/) or [Gleam](https://gleam.run/), maybe next time.

Blog posts are plain Markdown files fetched at runtime and rendered by Elm using `dillonkearns/elm-markdown`. The post index is a simple JSON file.

```json
{
  "slug": "reset",
  "title": "Reset",
  "date": "2026-03-11",
  "description": "First post on the new blog."
}
```

### Theme

For the color scheme, I use the one I have on my workstation. It's an old one I generated with [pywal](https://github.com/dylanaraps/pywal) from the Webb’s NIRCam picture of the [Carina Nebula](https://esawebb.org/images/carinanebula3/).

I end up using [IBM Plex](https://www.ibm.com/plex) fonts to change things a bit and feel modern.

![Carina Nebula](https://cdn.esawebb.org/archives/images/screen/carinanebula3.jpg)

### Build

Well, there is not much here really. I added a makefile for convenience. There is a watch mode with elm-watch and [servor](https://www.npmjs.com/package/servor) to help with development. I picked `servor` since it's dependency-free 🎉.

Elm generate pretty good ~dead code free~ javascript and works well with uglifyjs to further reduce the footprint.

The [blog](https://github.com/barjo/blog) repo is public on GitHub.
