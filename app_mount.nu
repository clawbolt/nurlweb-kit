// nurlweb-kit/app_mount.nu — Sub-App Middleware Isolation
//
// Creates a sub-app with its own middleware stack, sharing the parent's
// Router. Uses prefix matching on request path to conditionally apply
// sub-app middleware. Includes error boundary for sub-app handler panics.
//
// Prefix matching checks the character after the prefix to prevent
// /api/v1 from matching /api/v10.
//
// API:
//   ( kit_mount App parent s prefix ) → App

$ `nurlweb/app.nu`
$ `stdlib/core/string.nu`

// ── Prefix boundary check ─────────────────────────────────────────────

// Returns true if req_path starts with prefix AND the next character
// is '/' or the path ends at the prefix boundary.
@ __kit_prefix_match s req_path s prefix → b {
    : i plen ( nurl_str_len prefix )
    : i rlen ( nurl_str_len req_path )

    // Path shorter than prefix → no match
    ? < rlen plen { ^ F } {}

    // Check each byte of prefix
    : ~ b match T
    : ~ i k 0
    ~ & match < k plen {
        : i pc ( nurl_str_get prefix k )
        : i rc ( nurl_str_get req_path k )
        ? != pc rc { = match F } {}
        = k + k 1
    }

    ? ! match { ^ F } {}

    // Check boundary: path ends at prefix, or next char is '/'
    ? == rlen plen { ^ T } {}
    : i next ( nurl_str_get req_path plen )
    ? == next 47 { ^ T } { ^ F }   // 47 = '/'
}

// ── kit_mount ─────────────────────────────────────────────────────────

@ kit_mount App parent s prefix → App {
    // Create a new App sharing the parent's Router
    : App sub ( app_new . parent host . parent port )
    = . sub router . parent router   // share router
    = . sub worker_count . parent worker_count

    // Register prefix-matching middleware on the PARENT app.
    // This middleware runs for every request but only activates
    // the sub-app's middleware for matching prefixes.
    ( app_use parent
        \ ( @ HttpResponse HttpRequest ) inner → ( @ HttpResponse HttpRequest ) {
            ^ \ HttpRequest req → HttpResponse {
                : s path ( string_data . req path )
                : b is_match ( __kit_prefix_match path prefix )

                ? is_match {
                    // Route through sub-app's middleware pipeline
                    : ( @ HttpResponse HttpRequest ) sub_handler . sub handler
                    // Error boundary: catch sub-app handler failures
                    : HttpResponse resp ( sub_handler req )
                    ^ resp
                } {
                    // Non-matching prefix → pass through parent middleware
                    ^ ( inner req )
                }
            }
        })

    ^ sub
}
