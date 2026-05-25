// tests/test_lifecycle.nu — Lifecycle module tests

$ `nurlweb-kit/lifecycle.nu`
$ `nurlweb/app.nu`

// ── Test: lifecycle new
@ test_lifecycle_new → i {
    : Lifecycle lc ( kit_lifecycle_new )
    ^ 0
}

// ── Test: before_start hook runs and succeeds
@ test_before_start_ok → i {
    : Lifecycle lc ( kit_lifecycle_new )
    ( kit_lifecycle_before_start lc \ App a → !v LifecycleErr {
        ^ @ !v LifecycleErr { T @ LifecycleErr { `` `` } }
    })
    : !v LifecycleErr result ( kit_lifecycle_run_before_start lc ( app_new `127.0.0.1` 0 ) )
    ?? result {
        T _ → { ^ 0 }   // success
        F _ → { ^ 1 }   // error = fail
    }
}

// ── Test: before_start hook failure returns error
@ test_before_start_fail → i {
    : Lifecycle lc ( kit_lifecycle_new )
    ( kit_lifecycle_before_start lc \ App a → !v LifecycleErr {
        ^ @ !v LifecycleErr { F @ LifecycleErr { `before_start` `db connection failed` } }
    })
    : !v LifecycleErr result ( kit_lifecycle_run_before_start lc ( app_new `127.0.0.1` 0 ) )
    ?? result {
        T _ → { ^ 1 }   // success = fail (expected error)
        F _ → { ^ 0 }   // error = pass
    }
}

// ── Test: after_start hook runs (failures non-fatal)
@ test_after_start_runs → i {
    : Lifecycle lc ( kit_lifecycle_new )
    ( kit_lifecycle_after_start lc \ App a → !v LifecycleErr {
        ^ @ !v LifecycleErr { F @ LifecycleErr { `` `` } }
    })
    // Should not crash — failures are logged
    ( kit_lifecycle_run_after_start lc ( app_new `127.0.0.1` 0 ) )
    ^ 0
}

// ── Test: before_stop hook runs (failures non-fatal)
@ test_before_stop_runs → i {
    : Lifecycle lc ( kit_lifecycle_new )
    ( kit_lifecycle_before_stop lc \ App a → !v LifecycleErr {
        ^ @ !v LifecycleErr { F @ LifecycleErr { `` `` } }
    })
    ( kit_lifecycle_run_before_stop lc ( app_new `127.0.0.1` 0 ) )
    ^ 0
}

@ main → i {
    : i r1 ( test_lifecycle_new )
    : i r2 ( test_before_start_ok )
    : i r3 ( test_before_start_fail )
    : i r4 ( test_after_start_runs )
    : i r5 ( test_before_stop_runs )
    : i ok1 & & == r1 0 == r2 0 == r3 0
    : i ok2 & == r4 0 == r5 0
    ? & ok1 ok2 {
        ( nurl_print `all lifecycle tests passed\n` )
        ^ 0
    } {
        ( nurl_print `some lifecycle tests failed\n` )
        ^ 1
    }
}
