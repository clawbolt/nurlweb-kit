// nurlweb-kit/tests/test_session_runtime.nu — Runtime tests for SessionStore
// Stability: stable
//
// Verifies SessionStore set/get/del/overwrite behavior at runtime.
// Run via test_runner.sh or: ./build/nurlc this_file.nu && clang ...

$ `nurlweb-kit/middleware/session.nu`
$ `stdlib/core/string.nu`

// ── Tests ─────────────────────────────────────────────────────────────

@ test_store_new_get_miss → i {
    : SessionStore store ( session_store_new )
    : ?String v ( session_store_get store `nonexistent` )
    : i ok 0
    ?? v {
        T _ → { ( string_free v ) }
        F _ → { = ok 1 }
    }
    ( session_store_free store )
    ^ ok
}

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

@ test_store_del_nonexistent → i {
    : SessionStore store ( session_store_new )
    ( session_store_del store `ghost` )
    ( session_store_free store )
    ^ 1
}

@ test_store_multiple_keys → i {
    : SessionStore store ( session_store_new )
    ( session_store_set store `a` `1` )
    ( session_store_set store `b` `2` )
    ( session_store_set store `c` `3` )
    : i ok 1
    // Verify all three
    : ?String va ( session_store_get store `a` )
    ?? va {
        T sa → {
            ? == 0 ( nurl_str_eq sa `1` ) { = ok 0 } {}
            ( string_free sa )
        }
        F → { = ok 0 }
    }
    : ?String vb ( session_store_get store `b` )
    ?? vb {
        T sb → {
            ? == 0 ( nurl_str_eq sb `2` ) { = ok 0 } {}
            ( string_free sb )
        }
        F → { = ok 0 }
    }
    : ?String vc ( session_store_get store `c` )
    ?? vc {
        T sc → {
            ? == 0 ( nurl_str_eq sc `3` ) { = ok 0 } {}
            ( string_free sc )
        }
        F → { = ok 0 }
    }
    ( session_store_free store )
    ^ ok
}

// ── Main — run all tests, return 0 on success ──────────────────────

@ main → i {
    : i failures 0

    : i r1 ( test_store_new_get_miss )
    ? == r1 0 { = failures + failures 1 } {}

    : i r2 ( test_store_set_get )
    ? == r2 0 { = failures + failures 1 } {}

    : i r3 ( test_store_overwrite )
    ? == r3 0 { = failures + failures 1 } {}

    : i r4 ( test_store_del )
    ? == r4 0 { = failures + failures 1 } {}

    : i r5 ( test_store_del_nonexistent )
    ? == r5 0 { = failures + failures 1 } {}

    : i r6 ( test_store_multiple_keys )
    ? == r6 0 { = failures + failures 1 } {}

    ^ failures
}
