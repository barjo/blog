def esc: tostring | gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;");
def rfc822: strptime("%Y-%m-%d") | strftime("%a, %d %b %Y 00:00:00 +0000");
def site: "https://barjo.org";

def item:
  "<item>",
  "  <title>\(.title|esc)</title>",
  "  <link>\(site)/#post/\(.slug)</link>",
  "  <guid isPermaLink=\"false\">\(.slug)</guid>",
  "  <pubDate>\(.date|rfc822)</pubDate>",
  "  <description>\(.description|esc)</description>",
  "</item>";

"<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
"<rss version=\"2.0\">",
"<channel>",
"  <title>Confession of a Barjo</title>",
"  <link>\(site)/</link>",
"  <description>A software engineer's notebook</description>",
"  <lastBuildDate>\(max_by(.date).date|rfc822)</lastBuildDate>",
(.[] | item),
"</channel>",
"</rss>"
