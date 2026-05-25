// nurlweb-kit/lifecycle.nu — App Lifecycle Hooks
//
// Lifecycle struct holds hook vectors for before_start, after_start,
// and before_stop phases. Hooks run at app startup/shutdown.
//
// Semantics:
//   before_start failure → hard stop, server doesn't start (returns LifecycleErr)
//   after_start failure  → log warning, server continues
//   before_stop failure  → log warning, shutdown continues
//
// API:
//   ( kit_lifecycle_new )                                                   → Lifecycle
//   ( kit_lifecycle_before_start Lifecycle lc ( @ !v LifecycleErr App ) fn ) → v
//   ( kit_lifecycle_after_start  Lifecycle lc ( @ !v LifecycleErr App ) fn ) → v
//   ( kit_lifecycle_before_stop  Lifecycle lc ( @ !v LifecycleErr App ) fn ) → v
//   ( kit_lifecycle_run_before_start Lifecycle lc App a )                    → !v LifecycleErr
//   ( kit_lifecycle_run_after_start  Lifecycle lc App a )                    → v
//   ( kit_lifecycle_run_before_stop  Lifecycle lc App a )                    → v
//   ( kit_lifecycle_free Lifecycle lc )                                      → v

$ `stdlib/core/vec.nu`

// ── Types ─────────────────────────────────────────────────────────────

: LifecycleErr {
    String phase
    String message
}

// Hook closure type: takes App, returns success or error
// ( @ !v LifecycleErr App )

: Lifecycle {
    ( Vec ( @ !v LifecycleErr App ) ) before_start_hooks
    ( Vec ( @ !v LifecycleErr App ) ) after_start_hooks
    ( Vec ( @ !v LifecycleErr App ) ) before_stop_hooks
}

// ── Constructor ───────────────────────────────────────────────────────

@ kit_lifecycle_new → Lifecycle {
    : ( Vec ( @ !v LifecycleErr App ) ) bs ( vec_new [( @ !v LifecycleErr App )] )
    : ( Vec ( @ !v LifecycleErr App ) ) as ( vec_new [( @ !v LifecycleErr App )] )
    : ( Vec ( @ !v LifecycleErr App ) ) be ( vec_new [( @ !v LifecycleErr App )] )
    ^ @ Lifecycle { bs as be }
}

// ── Registration ──────────────────────────────────────────────────────

@ kit_lifecycle_before_start Lifecycle lc ( @ !v LifecycleErr App ) fn → v {
    ( vec_push [( @ !v LifecycleErr App )] . lc before_start_hooks fn )
}

@ kit_lifecycle_after_start Lifecycle lc ( @ !v LifecycleErr App ) fn → v {
    ( vec_push [( @ !v LifecycleErr App )] . lc after_start_hooks fn )
}

@ kit_lifecycle_before_stop Lifecycle lc ( @ !v LifecycleErr App ) fn → v {
    ( vec_push [( @ !v LifecycleErr App )] . lc before_stop_hooks fn )
}

// ── Execution ─────────────────────────────────────────────────────────

// Run before_start hooks. First failure → stop and return error.
@ kit_lifecycle_run_before_start Lifecycle lc App a → !v LifecycleErr {
    : ( Vec ( @ !v LifecycleErr App ) ) hooks . lc before_start_hooks
    : i n ( vec_len [( @ !v LifecycleErr App )] hooks )
    : ~ i k 0
    ~ < k n {
        : ?( @ !v LifecycleErr App ) fn_opt ( vec_get [( @ !v LifecycleErr App )] hooks k )
        ?? fn_opt {
            T fn → {
                : !v LifecycleErr result ( fn a )
                ?? result {
                    T err → { ^ @ !v LifecycleErr { F err } }
                    F _  → {}
                }
            }
            F → {}
        }
        = k + k 1
    }
    // All hooks succeeded
    ^ @ !v LifecycleErr { T @ LifecycleErr { `` `` } }
}

// Run after_start hooks. Failures are logged but non-fatal.
@ kit_lifecycle_run_after_start Lifecycle lc App a → v {
    : ( Vec ( @ !v LifecycleErr App ) ) hooks . lc after_start_hooks
    : i n ( vec_len [( @ !v LifecycleErr App )] hooks )
    : ~ i k 0
    ~ < k n {
        : ?( @ !v LifecycleErr App ) fn_opt ( vec_get [( @ !v LifecycleErr App )] hooks k )
        ?? fn_opt {
            T fn → {
                : !v LifecycleErr result ( fn a )
                ?? result {
                    T _ → {
                        // Log warning but continue
                        ( nurl_print `lifecycle: after_start hook failed (warning)\n` )
                    }
                    F _ → {}
                }
            }
            F → {}
        }
        = k + k 1
    }
}

// Run before_stop hooks. Failures are logged but non-fatal.
@ kit_lifecycle_run_before_stop Lifecycle lc App a → v {
    : ( Vec ( @ !v LifecycleErr App ) ) hooks . lc before_stop_hooks
    : i n ( vec_len [( @ !v LifecycleErr App )] hooks )
    : ~ i k 0
    ~ < k n {
        : ?( @ !v LifecycleErr App ) fn_opt ( vec_get [( @ !v LifecycleErr App )] hooks k )
        ?? fn_opt {
            T fn → {
                : !v LifecycleErr result ( fn a )
                ?? result {
                    T _ → {
                        ( nurl_print `lifecycle: before_stop hook failed (warning)\n` )
                    }
                    F _ → {}
                }
            }
            F → {}
        }
        = k + k 1
    }
}

// ── Free ──────────────────────────────────────────────────────────────

@ kit_lifecycle_free Lifecycle lc → v {
    ( vec_free [( @ !v LifecycleErr App )] . lc before_start_hooks )
    ( vec_free [( @ !v LifecycleErr App )] . lc after_start_hooks )
    ( vec_free [( @ !v LifecycleErr App )] . lc before_stop_hooks )
}
