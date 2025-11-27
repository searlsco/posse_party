# Format String

The crosspost format string controls how posse_party composes the text sent to each platform. It is a template made of regular text with placeholders wrapped in double curly braces, such as `{{title}}`.

When a post is published, each placeholder is replaced with the corresponding value from the crosspost configuration. Unknown placeholders resolve to an empty string. After substitution, the result is normalized (Unicode NFC), repeated spaces collapse into one, spaces before line breaks are removed, and leading or trailing whitespace is trimmed.

## Available placeholders

| Placeholder | Description |
| --- | --- |
| `{{title}}` | Post title. |
| `{{subtitle}}` | Subtitle, when provided. |
| `{{summary}}` | Short summary or teaser text. |
| `{{content}}` | Full body content in plain text. |
| `{{url}}` | Canonical URL for the post. |
| `{{alternate_url}}` | Alternate URL, such as a canonical source link. |
| `{{related_url}}` | Related URL (often a video or companion link). |
| `{{short_url}}` | Short link, when generated. |
| `{{author_name}}` | Post author name. |
| `{{author_email}}` | Post author email address. |
| `{{og_title}}` | OpenGraph title override. |
| `{{og_description}}` | OpenGraph description override. |
| `{{og_image}}` | OpenGraph image URL override. |

Additional placeholders become available whenever matching fields exist on the post or account override. Use the field’s symbol name surrounded by double braces (for example, `{{append_url_label}}`).

## Examples

### Publish title only

```text
{{title}}
```

### Title with summary and canonical link

```text
{{title}}

{{summary}}

Read more: {{url}}
```

### Custom teaser for video crossposts

```text
{{title}}

{{content}}

Watch now: {{related_url}}
```

### Promote long-form article with OpenGraph helpers

```text
New on the site: {{og_title}}

{{og_description}}

{{url}}
```
