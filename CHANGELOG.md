# CHANGELOG

This file lists user-visible changes (including potentially breaking changes). The app is not versioned; entries are reverse-chronological by date.

## 2025-12-31

- Instagram Stories now requires libvips (via `ruby-vips`) to letterbox non-9:16 images into 9:16 story JPEGs with black bars. If you don’t publish to the `story` channel, you don’t need libvips installed.
