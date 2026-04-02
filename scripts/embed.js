#!/usr/bin/env node

// Thin wrapper: reads posts, boots the Elm Embed worker, writes embeddings
// back into index.json.

const fs = require("fs");
const path = require("path");

const POSTS_DIR = path.join(__dirname, "..", "public", "posts");
const INDEX_FILE = path.join(POSTS_DIR, "index.json");

const { Elm } = require("./embed-worker.js");

const index = JSON.parse(fs.readFileSync(INDEX_FILE, "utf8"));

const input = index.map((post) => {
  const mdPath = path.join(POSTS_DIR, post.slug + ".md");
  const markdown = fs.existsSync(mdPath) ? fs.readFileSync(mdPath, "utf8") : "";
  return {
    slug: post.slug,
    text: [post.title, post.description, post.tags.join(" "), markdown].join(" "),
  };
});

const worker = Elm.Embed.init({ flags: input });

worker.ports.embeddingsComputed.subscribe(function (results) {
  const embMap = new Map(results.map((r) => [r.slug, r.embedding]));
  for (const post of index) {
    post.embedding = embMap.get(post.slug) || [];
  }
  // Pretty-print metadata but keep embeddings on a single line
  const pretty = "[\n" + index.map((p) => {
    const { embedding, ...meta } = p;
    const lines = JSON.stringify(meta, null, 4).slice(0, -1);
    return lines + ',\n    "embedding": ' + JSON.stringify(embedding) + "\n}";
  }).join(",\n") + "\n]\n";
  fs.writeFileSync(INDEX_FILE, pretty);
  const size = Buffer.byteLength(pretty);
  console.log("Embedded " + index.length + " posts (" + size + " bytes)");
  process.exit(0);
});
