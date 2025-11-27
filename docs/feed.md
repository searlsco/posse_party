# Customizing Posts via Atom `<posse:post>`

POSSE Party reads per-entry syndication settings from a namespaced Atom element.

- Namespace: `xmlns:posse="https://posseparty.com/2024/Feed"`
- Element: `<posse:post>`
- Attribute: `format="json"` (default/only supported)
- Location: inside each Atom `<entry>`
- Content: CDATA-wrapped JSON object (see example and table below)

## Minimal Feed Snippet

```xml
<feed xmlns="http://www.w3.org/2005/Atom"
      xmlns:posse="https://posseparty.com/2024/Feed">
  <entry>
    <id>https://example.com/posts/123</id>
    <title>Example Post</title>
    <updated>2025-09-01T12:00:00Z</updated>
    <link rel="alternate" href="https://example.com/posts/123" />

    <posse:post format="json"><![CDATA[
      {
        "format_string": "{{title}}",
        "append_url": true,
        "append_url_spacer": " ",
        "platform_overrides": {
          "bsky": {"attach_link": true}
        }
      }
    ]]></posse:post>
  </entry>
  
</feed>
```

## Full JSON Example

```json
{
  "id": "https://example.com/posts/123",
  "published_at": "2025-09-01T11:30:00Z",
  "updated_at": "2025-09-01T12:00:00Z",
  "url": "https://example.com/posts/123",
  "alternate_url": "https://example.com/p/123",
  "related_url": "https://example.com/related/456",
  "short_url": "https://exm.pl/e/123",
  "author_name": "Ada Lovelace",
  "author_email": "ada@example.com",
  "title": "Announcing Example",
  "subtitle": "Subheading",
  "summary": "Plain-text summary of the post",
  "content": "Plain-text or HTML converted to plain text",

  "syndicate": true,
  "format_string": "{{title}}",
  "truncate": true,
  "append_url": true,
  "append_url_if_truncated": true,
  "append_url_spacer": " ",
  "append_url_label": "🔗",
  "attach_link": true,
  "og_image": "https://example.com/card.jpg",
  "og_title": "Example Card Title",
  "og_description": "One–two sentence description",

  "media": [
    {"type": "image", "url": "https://example.com/img/1.jpg"},
    {
      "type": "video",
      "url": "https://example.com/vid/clip.mp4",
      "poster_url": "https://example.com/vid/clip-poster.jpg"
    }
  ],

  "platform_overrides": {
    "bsky": {
      "format_string": "{{title}}",
      "append_url": false,
      "append_url_label": "🔗",
      "attach_link": true,
      "og_image": "https://example.com/card.jpg"
    },
    "x": {
      "truncate": true,
      "append_url": true,
      "append_url_spacer": " ",
      "format_string": "{{title}}"
    },
    "mastodon": {
      "append_url": true
    },
    "threads": {
      "attach_link": true,
      "append_url": false
    },
    "instagram": {
      "syndicate": false
    },
    "facebook": {
      "attach_link": true
    },
    "linkedin": {
      "attach_link": true
    },
    "youtube": {
      "format_string": "{{title}}",
      "append_url": false
    }
  }
}
```

## Supported Adapters

- Bluesky (`bsky`)
- X (Twitter) (`x`)
- Mastodon (`mastodon`)
- Threads (`threads`)
- Instagram (`instagram`)
- Facebook (`facebook`)
- LinkedIn (`linkedin`)
- YouTube (`youtube`)

## Properties

| Property | Type | Description |
| --- | --- | --- |
| `id` | string | Source entry identifier; stored as `remote_id`. If omitted, derived from `<id>`/URLs. |
| `published_at` | datetime (ISO 8601) | Source publish time; stored as `remote_published_at`. Defaults to `<published>`. |
| `updated_at` | datetime (ISO 8601) | Source update time; stored as `remote_updated_at`. Defaults to `<updated>`. |
| `url` | string (URL) | Canonical source URL used when appending/attaching links. Fallback: `rel=shorturl`, `rel=alternate`, then first `<link>`. |
| `alternate_url` | string (URL) | Alternate permalink. Defaults to first `rel=alternate` link. |
| `related_url` | string (URL) | Related link. Defaults to first `rel=related` link. |
| `short_url` | string (URL) | Shortened URL. Defaults to first `rel=shorturl` link. |
| `author_name` | string | Author display name. Defaults to `<author><name>`. |
| `author_email` | string | Author email. Defaults to `<author><email>`. |
| `title` | string | Title text. Defaults to `<title>` text. |
| `subtitle` | string | Subtitle text. Defaults to `<subtitle>` text. |
| `summary` | string | Summary; HTML is converted to plain text. Defaults to `<summary>`. |
| `content` | string | Main content; HTML is converted to plain text. Defaults to `<content>`. |
| `syndicate` | boolean | Whether to publish this entry to platforms. If not set, platform/account defaults apply. |
| `format_string` | string | Template for composed text, e.g., `"{{title}}"`, `"{{content}}"`. |
| `truncate` | boolean | Truncate to platform limits using platform-specific counters. |
| `append_url` | boolean | Always append `url` (or labeled link) to composed text. |
| `append_url_if_truncated` | boolean | Append only when truncation occurs and `append_url` is false. |
| `append_url_spacer` | string | Spacer inserted before appended URL/label (e.g., `" "`, `"\n\n"`). |
| `append_url_label` | string | Label used when platforms support hyperlink labels (e.g., `"🔗"`). Supported on Bluesky. |
| `attach_link` | boolean | Attach an OpenGraph/website card when supported (Bluesky, Threads, Facebook, LinkedIn). |
| `og_image` | string (URL) | Card image URL (supported on Bluesky). |
| `og_title` | string | Card title override (Bluesky). Defaults to `title` if omitted. |
| `og_description` | string | Card description override (Bluesky). Defaults to `summary` if omitted. |
| `media` | array<object> | Media attachments used by certain platforms (Instagram requires images/video; YouTube requires exactly one video). When present, `media.poster_url` is used by platforms that support custom covers/thumbnails (such as Instagram Reels and YouTube). |
| `platform_overrides` | object | Map of platform tag → object of overrides for any properties in this table. Unknown tags are ignored. |
| `channel` | string | Global destination channel. Supported values: `"feed"` (default) or `"story"` (Instagram only). |

### `media` Item

| Field | Type | Description |
| --- | --- | --- |
| `type` | string | `"image"` or `"video"`. |
| `url` | string (URL) | Direct URL to the media asset. |
| `poster_url` | string (URL) | Optional cover/thumbnail image used by platforms that support custom posters (for example Instagram Reels covers and YouTube thumbnails). |

## Precedence

- Platform defaults → Account settings → Entry properties → `platform_overrides[platform]`.

## Notes

- The `<posse:post>` element lives in the `https://posseparty.com/2024/Feed` namespace and supports `format="json"`.
- Content may be JSON or relaxed JSON (e.g., trailing commas, single quotes). Use valid JSON for maximum compatibility.
- Include the namespace declaration (`xmlns:posse`) on the `<feed>` root for validators.

## Channels

Some platforms support multiple publishing “channels.” Today:

- Global option: `channel` — defaults to `"feed"`.
- Instagram additionally supports `"story"`.
- Other platforms currently support only `"feed"`.

Behavior when `channel == "story"` (Instagram):

- Only the first media item is used (carousels are not supported for Stories).
- Captions are ignored by the Graph API for Stories; POSSE Party omits them.
- No stable permalink is available; the crosspost’s `url` remains `nil`.
- Unsupported platforms are automatically skipped for that crosspost.

### Examples

Global story (all platforms that support it; others are skipped):

```json
{
  "content": "...",
  "media": [{"type": "image", "url": "https://example.com/1.jpg"}],
  "channel": "story"
}
```

Feed elsewhere, Story only on Instagram:

```json
{
  "content": "...",
  "media": [{"type": "video", "url": "https://example.com/clip.mp4"}],
  "platform_overrides": {
    "instagram": {"channel": "story"}
  }
}
```
