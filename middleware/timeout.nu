// nurlweb-kit/timeout.nu — Request Timeout (v3 placeholder)
// Stability: placeholder — no timeout is enforced; this is a pass-through stub
//
// True request-scoped deadlines require async/cancel support (planned
// nurl v3). Until then, use server_new_with_timeout when creating the
// server directly (bypassing app_serve) to set idle timeouts.
//
// API (placeholder):
//   ( with_timeout i ms ( @ HttpResponse HttpRequest ) h ) → ( @ HttpResponse HttpRequest )
//
// This is a pass-through — no timeout enforcement. See http_server.nu
// for server-level idle_timeout_ms configuration.

@ with_timeout i ms ( @ HttpResponse HttpRequest ) h → ( @ HttpResponse HttpRequest ) {
    ^ h
}
