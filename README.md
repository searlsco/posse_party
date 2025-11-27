# POSSE Party

[![Certified Shovelware](https://justin.searls.co/img/shovelware.svg)](https://justin.searls.co/shovelware/)

POSSE Party is a web application for crossposting content from your site to a variety of social media platforms. It currently supports X, Bluesky, Mastodon, Threads, Instagram, Facebook, LinkedIn, and Youtube.

Why? To help you quit using social media in favor of a personal blog… _without_ abandoning your audience in the process. Thanks to POSSE Party, literally everything I do is posted to [justin.searls.co](https://justin.searls.co) first and then automatically syndicated to all eight supported platforms. I'm not logged into any of these apps on my phone. I don't scroll any of their feeds. I'm calmer and better-looking than I used to be. I'm also writing more meaningful stuff and reaching more people than ever.

I was originally going to charge for it as a traditionally-hosted SaaS product, but then I decided I'd rather have my time than your money. So instead, **POSSE Party is a self-hosted affair—all you need is a server that can host docker images**. Best of all, it's **free to use for non-commercial use** ([see the license](#license) for details).

## Deployment

A [Docker image for POSSE Party](https://github.com/searlsco/posse_party/pkgs/container/posse_party) is [hosted on the GitHub Container Registry](https://github.com/searlsco/posse_party/pkgs/container/posse_party). You should be able to run it on anything that can host Docker containers.

To get started quickly, SSH into your server and run:

```sh
APP_HOST=your.domain.or.ip /bin/bash -c "$(curl -fsSL https://posseparty.com/setup.sh)"
```

See [DEPLOY.md](/DEPLOY.md) for more instructions on configuring and maintaining your installation. Take a look at [docs/feed.md](/docs/feed.md) to understand how to configure how POSSE Party will crosspost your content.

## Development

If you want to roll up your sleeves and modify POSSE Party, check out [DEVELOPMENT.md](/DEVELOPMENT.md) for some probably-insufficient instructions.

## License

POSSE Party is free to use for non-commercial purposes and is distributed under the [PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/).

You can use, modify, self-host, and share POSSE Party for:

* Personal use and hobby projects
* A non‑commercial organization (charities, schools, public research, etc.)

The license does not permit you to:

* Sell POSSE Party to others
* Use POSSE Party in the course of your employment for a for‑profit company (including managing company or client social media accounts), unless your employer has a commercial license
* Bundle POSSE Party into any paid product, paid service, or paid SaaS offering
* Offer POSSE Party as a hosted or managed service, or as part of any paid plan or tier
* Provide access to an instance of POSSE Party for others to use in the course of their employment for a for‑profit company (for example, inviting your employer or clients onto your personally hosted instance to manage their social media accounts), unless that employer or client has a commercial license

Those activities would require a separate commercial license. If you'd like to use POSSE Party commercially, please reach out to [justin@searls.co](mailto:justin@searls.co).
