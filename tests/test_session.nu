// nurlweb/test_session.nu — Compile-time unit tests for session.nu
//
// Verifies that cookie helpers + SessionStore compile correctly.
// Run: ./build/nurlc nurlweb/test_session.nu
// Expected: exit 0

$ `nurlweb-kit/context/ctx.nu`
$ `nurlweb-kit/middleware/session.nu`
$ `stdlib/ext/http_full.nu`
$ `stdlib/ext/http_auth.nu`
$ `stdlib/core/string.nu`
$ `stdlib/core/vec.nu`

// ── Test: session_get compiles ────────────────────────────────────────

@ test_session_get Ctx ctx → ?String {
    ^ ( session_get ctx `session_id` )
}

// ── Test: session_set compiles ────────────────────────────────────────

@ test_session_set Ctx ctx HttpResponse r → v {
    ( session_set ctx r `token` `abc123xyz` )
}

// ── Test: session_del compiles ────────────────────────────────────────

@ test_session_del Ctx ctx HttpResponse r → v {
    ( session_del ctx r `token` )
}

// ── Test: full session flow in a handler ──────────────────────────────

@ test_session_handler HttpRequest req Params params → HttpResponse {
    : Ctx ctx ( ctx_new req params )
    : HttpResponse r ( response_text 200 `ok\n` )
    : ?String session_val ( session_get ctx `sid` )
    ?? session_val {
        T sv → {
            ( string_free sv )
        }
        F _ → {}
    }
    ( session_set ctx r `sid` `new_session_val` )
    ^ r
}

// ── Test: SessionStore — new + get (miss) ─────────────────────────────

@ test_store_new_get_miss → i {
    : SessionStore store ( session_store_new )
    : ?String v ( session_store_get store `nonexistent` )
    : i ok 0
    ?? v {
        T _ → { ( string_free v ) = ok 1 }
        F _ → {}
    }
    ( session_store_free store )
    ^ ok
}

// ── Test: SessionStore — set + get ────────────────────────────────────

@ test_store_set_get → i {
    : SessionStore store ( session_store_new )
    ( session_store_set store `user` `alice` )
    : ?String v ( session_store_get store `user` )
    : i ok 0
    ?? v {
        T s → {
            ? != 0 ( nurl_str_eq s `alice` ) { = ok 1 } {}
            ( string_free s )
        }
        F _ → {}
    }
    ( session_store_free store )
    ^ ok
}

// ── Test: SessionStore — overwrite ────────────────────────────────────

@ test_store_overwrite → i {
    : SessionStore store ( session_store_new )
    ( session_store_set store `key` `first` )
    ( session_store_set store `key` `second` )
    : ?String v ( session_store_get store `key` )
    : i ok 0
    ?? v {
        T s → {
            ? != 0 ( nurl_str_eq s `second` ) { = ok 1 } {}
            ( string_free s )
        }
        F _ → {}
    }
    ( session_store_free store )
    ^ ok
}

// ── Test: SessionStore — del ──────────────────────────────────────────

@ test_store_del → i {
    : SessionStore store ( session_store_new )
    ( session_store_set store `temp` `value` )
    ( session_store_del store `temp` )
    : ?String v ( session_store_get store `temp` )
    : i ok 0
    ?? v {
        T _ → { ( string_free v ) }
        F _ → { = ok 1 }
    }
    ( session_store_free store )
    ^ ok
}

// ── Test: SessionStore — del nonexistent is no-op ─────────────────────

@ test_store_del_nonexistent → v {
    : SessionStore store ( session_store_new )
    ( session_store_del store `ghost` )
    ( session_store_free store )
}

// ── Main ──────────────────────────────────────────────────────────────

@ main → i { ^ 0 }
