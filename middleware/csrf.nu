// nurlweb-kit/middleware/csrf.nu — CSRF protection middleware
// Stability: experimental
//
// Double-submit cookie pattern. Generates tokens from a secret via
// SHA-256, validates by comparing X-CSRF-Token header against the
// csrf_token cookie. Safe methods (GET, HEAD, OPTIONS, TRACE) skip
// validation.
//
// API:
//   ( csrf_token s secret ) → s                   — generate token
//   ( csrf_protect ( @ HttpResponse HttpRequest ) h ) → ( @ HttpResponse HttpRequest )
//
// Usage (per-route):
//   ( app_post a `/submit` ( csrf_protect handler ))
//
// Setup: set csrf_token cookie on responses that serve forms, and
// include the same token in a hidden field or X-CSRF-Token header.

$ `stdlib/ext/http_auth.nu`
$ `stdlib/ext/http_full.nu`
$ `stdlib/core/string.nu`

// ── Token generation ──────────────────────────────────────────────────

@ csrf_token s secret → s {
    ^ ( nurl_sha256_hex secret )
}

// ── Safe method check ─────────────────────────────────────────────────

@ __csrf_safe_method s method → b {
    : i eq_get ( nurl_str_eq method `GET` )
    ? != eq_get 0 { ^ T } {}
    : i eq_head ( nurl_str_eq method `HEAD` )
    ? != eq_head 0 { ^ T } {}
    : i eq_opts ( nurl_str_eq method `OPTIONS` )
    ? != eq_opts 0 { ^ T } {}
    : i eq_trace ( nurl_str_eq method `TRACE` )
    ? != eq_trace 0 { ^ T } {}
    ^ F
}

// ── Middleware ─────────────────────────────────────────────────────────

@ csrf_protect ( @ HttpResponse HttpRequest ) h → ( @ HttpResponse HttpRequest ) {
    ^ \ HttpRequest req → HttpResponse {
        // Extract method from request struct (same pattern as request_logger.nu)
        : s method ( string_data . req method )
        : b is_safe ( __csrf_safe_method method )

        ? is_safe { ^ ( h req ) } {
            // Read X-CSRF-Token header
            : ?String header_opt ( header_get req `X-CSRF-Token` )
            ?? header_opt {
                T header_token → {
                    // Read csrf_token cookie
                    : ?String cookie_opt ( request_cookie req `csrf_token` )
                    ?? cookie_opt {
                        T cookie_token → {
                            // Compare header token with cookie token
                            : i match ( nurl_str_eq header_token cookie_token )
                            ( string_free cookie_token )
                            ( string_free header_token )
                            ? != match 0 {
                                ^ ( h req )
                            } {
                                : HttpResponse forbidden ( response_text 403 `CSRF token mismatch\n` )
                                ^ forbidden
                            }
                        }
                        F → {
                            ( string_free header_token )
                            : HttpResponse forbidden ( response_text 403 `CSRF cookie missing\n` )
                            ^ forbidden
                        }
                    }
                }
                F → {
                    : HttpResponse forbidden ( response_text 403 `CSRF token missing\n` )
                    ^ forbidden
                }
            }
        }
    }
}
