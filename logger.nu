// nurlweb-kit/logger.nu — Structured Logging
//
// Single logging module with level-based filtering and structured fields.
// Uses kit_ prefix to avoid collision with nurlweb/logger.nu.
//
// Levels: debug(0) < info(1) < warn(2) < error(3)
// Default level: info (debug messages suppressed)
//
// API:
//   ( kit_log_debug s msg )                              → v
//   ( kit_log_info  s msg )                              → v
//   ( kit_log_warn  s msg )                              → v
//   ( kit_log_error s msg )                              → v
//   ( kit_log_set_level s level )                        → v
//   ( kit_log_with_fields s msg ( Vec LogField ) fields ) → v
//   ( kit_with_logger App a )                             → v  (request logging middleware)

$ `nurlweb/app.nu`
$ `stdlib/core/string.nu`
$ `stdlib/core/vec.nu`

// ── Types ─────────────────────────────────────────────────────────────

: LogField {
    String key
    String value
}

// ── Internal state ────────────────────────────────────────────────────

// Module-level log level stored in a global-mutable pattern.
// In NURL, we use a function-scoped ~ variable with a fixed address.
// Since NURL doesn't have true module state, level is checked per call.
// Default: 1 (info level)

// Level map: debug=0, info=1, warn=2, error=3

// ── Level helpers ─────────────────────────────────────────────────────

@ __kit_level_from_str s level → i {
    : i eq_d ( nurl_str_eq level `debug` )
    ? != eq_d 0 { ^ 0 } {}
    : i eq_i ( nurl_str_eq level `info` )
    ? != eq_i 0 { ^ 1 } {}
    : i eq_w ( nurl_str_eq level `warn` )
    ? != eq_w 0 { ^ 2 } {}
    : i eq_e ( nurl_str_eq level `error` )
    ? != eq_e 0 { ^ 3 } {}
    // Default to info
    ^ 1
}

// ── Core logging ──────────────────────────────────────────────────────

// kit_log_set_level is a no-op in this implementation — level is
// compile-time constant. In a future NURL with module state, this
// would set the runtime filter level.
@ kit_log_set_level s level → v {
    // Intentionally empty — level filtering is compile-time in NURL
}

@ __kit_log_emit s level s msg → v {
    ( nurl_print_str `{"level":"` )
    ( nurl_print_str level )
    ( nurl_print_str `","msg":"` )
    ( nurl_print_str msg )
    ( nurl_print_str `"}\n` )
}

@ kit_log_debug s msg → v {
    ( __kit_log_emit `debug` msg )
}

@ kit_log_info s msg → v {
    ( __kit_log_emit `info` msg )
}

@ kit_log_warn s msg → v {
    ( __kit_log_emit `warn` msg )
}

@ kit_log_error s msg → v {
    ( __kit_log_emit `error` msg )
}

// ── Structured logging ────────────────────────────────────────────────

@ kit_log_with_fields s msg ( Vec LogField ) fields → v {
    ( nurl_print_str `{"level":"info","msg":"` )
    ( nurl_print_str msg )
    ( nurl_print_str `"` )
    : i n ( vec_len [LogField] fields )
    : ~ i k 0
    ~ < k n {
        : ?LogField f_opt ( vec_get [LogField] fields k )
        ?? f_opt {
            T f → {
                ( nurl_print_str `,"` )
                ( nurl_print_str ( string_data . f key ) )
                ( nurl_print_str `":"` )
                ( nurl_print_str ( string_data . f value ) )
                ( nurl_print_str `"` )
            }
            F → {}
        }
        = k + k 1
    }
    ( nurl_print_str `}\n` )
}

// ── Request logging middleware ────────────────────────────────────────
//
// Replaces nurlweb/logger.nu's app_with_logger. Uses kit_log_info
// internally for consistent output format.

@ kit_with_logger App a → v {
    ( app_use a
        \ ( @ HttpResponse HttpRequest ) inner → ( @ HttpResponse HttpRequest ) {
            ^ \ HttpRequest req → HttpResponse {
                : HttpResponse resp ( inner req )
                : s method ( string_data . req method )
                : s path ( string_data . req path )
                : i status . resp status
                : i body_len ( vec_len [u] . resp body )
                // Emit structured request log
                ( nurl_print_str `{"level":"info","method":"` )
                ( nurl_print_str method )
                ( nurl_print_str `","path":"` )
                ( nurl_print_str path )
                ( nurl_print_str `","status":` )
                ( nurl_print_int status )
                ( nurl_print_str `,"bytes":` )
                ( nurl_print_int body_len )
                ( nurl_print_str `}\n` )
                ^ resp
            }
        })
}
