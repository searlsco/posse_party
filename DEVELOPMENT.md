# Development

Prerequisites: Ruby, Node.js, PostgreSQL, Yarn, and libidn.

## Setup

```bash
./script/setup
```

## Server

Run the Rails server:

```
./script/server
```

Run the Solid Queue worker:

```
./script/worker
```

Run Tailwind asset compilation:

```
./bin/rails tailwindcss:watch
```

Or, run all in a single [foreman](https://github.com/theforeman/foreman) process:

```
./bin/dev
```

## Tests

```bash
./script/test
```
