# CHANGELOG

This file lists user-visible changes (including potentially breaking changes). The app is not versioned; entries are reverse-chronological by date.

## 2026-10-23

- Attaching media to Mastodon needs the access token's `write:media` scope, which earlier setup instructions didn't ask for. Mastodon accounts set up before this change must add `write:media` to their application (Mastodon's **Development** settings), regenerate the access token, and paste it into the account in POSSE Party. Until then, crossposts with media fail right away with a message saying so, instead of retrying.

## 2026-10-22

- Bluesky, X, Mastodon, Threads, and LinkedIn now attach a post's `media` (photos and videos, configured the same way as for Instagram), including alt text from a new optional `alt` field on each media item. See [Media](docs/feed.md#media) for each platform's limits.
- New `media_fallback` setting (account, post, or platform override) decides what happens when a platform can't attach all of a post's media: `"link"` (default) posts without media but links back to the source, `"best_effort"` attaches whatever fits, and `"fail"` fails the crosspost. This adds a `media_fallback` column to accounts and posts (run migrations).
- Attached media replaces the website card on Bluesky, Threads, and LinkedIn, so when `attach_link` is on, those posts now append the post's URL instead. Posts with media that previously showed a card on these platforms will show the media and a link.
- The "Compose Manually" card offers to copy each photo to the clipboard for pasting into X's composer (and links each video to save and drag in), and `GET /api/crossposts/pending` includes each crosspost's `media`.

## 2026-08-20

- Platforms can now offer a "Compose Manually" link on a crosspost, which opens that platform's own composer with the crosspost's content already filled in. X is the first platform to support it. This pairs with the existing "Manually publish crossposts" account setting for anyone who would rather not pay X's per-post API charges. After posting, paste the resulting URL into the same card (or `PATCH /api/crossposts/:id`) to record the crosspost as published.
- New `GET /api/crossposts/pending` returns crossposts awaiting manual publication, including the composed content and a ready-to-open compose URL.

## 2025-12-31

- Instagram Stories now requires libvips (via `ruby-vips`) to letterbox non-9:16 images into 9:16 story JPEGs with black bars. If you don’t publish to the `story` channel, you don’t need libvips installed.
