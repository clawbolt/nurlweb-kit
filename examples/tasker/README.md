# Tasker API Example

Tasker is a small but real business scenario for exercising nurlweb with nurlweb-kit in a project-shaped workspace.

It models a project task tracker with:

- task CRUD: `title`, `status` (`todo`, `doing`, `done`)
- nested task comments
- JSON request and response bodies
- validation errors for missing or invalid fields
- 404 responses for missing resources
- status-code coverage across `200`, `201`, `204`, `400`, and `404`

## Build

Create the expected workspace links next to the example:

```bash
ln -s /path/to/nurlweb nurlweb
ln -s /path/to/nurlweb-kit nurlweb-kit
ln -s /path/to/nurl-lang/stdlib stdlib
```

Then compile and link:

```bash
NURLC=/path/to/nurl-lang/build/nurlc
RUNTIME=/path/to/nurl-lang/stdlib/runtime.o

"$NURLC" nurlweb-kit/examples/tasker/main.nu > /tmp/tasker.ll
clang -O2 /tmp/tasker.ll "$RUNTIME" -lm -lpthread \
  $(pkg-config --libs libcurl 2>/dev/null || echo "-lcurl") \
  $(pkg-config --libs openssl 2>/dev/null || echo "-lssl -lcrypto") \
  $(pkg-config --libs sqlite3 2>/dev/null || echo "-lsqlite3") \
  $(pkg-config --libs zlib 2>/dev/null || echo "-lz") \
  $(pkg-config --libs libzstd 2>/dev/null || echo "-lzstd") \
  -o /tmp/tasker
```

Run:

```bash
/tmp/tasker
```

The server listens on `http://127.0.0.1:3960`.

## Smoke Coverage

This example has been exercised with real HTTP requests for:

- `GET /health`
- `GET /tasks`
- `POST /tasks`
- `GET /tasks/:id`
- `PUT /tasks/:id`
- `DELETE /tasks/:id`
- `POST /tasks/:id/comments`
- `GET /tasks/:id/comments`
- validation and missing-resource error paths

