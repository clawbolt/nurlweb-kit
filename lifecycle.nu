// nurlweb-kit/lifecycle.nu — App Lifecycle Hooks
//
// Simple fixed-slot design: 2 hooks per phase. Avoids nurlc vec_get
// codegen limitation on closure element types. In practice, apps
// rarely need more than 1-2 lifecycle hooks per phase.
//
// Semantics:
//   before_start failure → hard stop, server doesn't start
//   after_start failure  → log warning, server continues
//   before_stop failure  → log warning, shutdown continues
//
// API:
//   ( kit_lifecycle_new )                                     → Lifecycle
//   ( kit_lifecycle_before_start Lifecycle lc hook_fn )       → v
//   ( kit_lifecycle_after_start  Lifecycle lc hook_fn )       → v
//   ( kit_lifecycle_before_stop  Lifecycle lc hook_fn )       → v
//   ( kit_lifecycle_run_before_start Lifecycle lc App a )     → !v LifecycleErr
//   ( kit_lifecycle_run_after_start  Lifecycle lc App a )     → v
//   ( kit_lifecycle_run_before_stop  Lifecycle lc App a )     → v

// ── Types ─────────────────────────────────────────────────────────────

: LifecycleErr {
    String phase
    String message
}

: Lifecycle {
    // before_start (up to 2 hooks)
    b bs0_used
    ( @ !v LifecycleErr App ) bs0_fn
    b bs1_used
    ( @ !v LifecycleErr App ) bs1_fn
    // after_start (up to 2 hooks)
    b as0_used
    ( @ !v LifecycleErr App ) as0_fn
    b as1_used
    ( @ !v LifecycleErr App ) as1_fn
    // before_stop (up to 2 hooks)
    b be0_used
    ( @ !v LifecycleErr App ) be0_fn
    b be1_used
    ( @ !v LifecycleErr App ) be1_fn
}

// ── Constructor ───────────────────────────────────────────────────────

@ __hook_noop App a → !v LifecycleErr {
    ^ @ !v LifecycleErr { T @ LifecycleErr { `` `` } }
}

@ kit_lifecycle_new → Lifecycle {
    : ( @ !v LifecycleErr App ) noop
        \ App a → !v LifecycleErr { ^ ( __hook_noop a ) }
    ^ @ Lifecycle {
        F noop F noop
        F noop F noop
        F noop F noop
    }
}

// ── Registration ──────────────────────────────────────────────────────

@ kit_lifecycle_before_start Lifecycle lc ( @ !v LifecycleErr App ) fn → v {
    ? ! . lc bs0_used {
        = . lc bs0_used T
        = . lc bs0_fn fn
    } {
        ? ! . lc bs1_used {
            = . lc bs1_used T
            = . lc bs1_fn fn
        } {
            ( nurl_print `lifecycle: before_start full (max 2)\n` )
        }
    }
}

@ kit_lifecycle_after_start Lifecycle lc ( @ !v LifecycleErr App ) fn → v {
    ? ! . lc as0_used {
        = . lc as0_used T
        = . lc as0_fn fn
    } {
        ? ! . lc as1_used {
            = . lc as1_used T
            = . lc as1_fn fn
        } {
            ( nurl_print `lifecycle: after_start full (max 2)\n` )
        }
    }
}

@ kit_lifecycle_before_stop Lifecycle lc ( @ !v LifecycleErr App ) fn → v {
    ? ! . lc be0_used {
        = . lc be0_used T
        = . lc be0_fn fn
    } {
        ? ! . lc be1_used {
            = . lc be1_used T
            = . lc be1_fn fn
        } {
            ( nurl_print `lifecycle: before_stop full (max 2)\n` )
        }
    }
}

// ── Execution ─────────────────────────────────────────────────────────

@ kit_lifecycle_run_before_start Lifecycle lc App a → !v LifecycleErr {
    ? . lc bs0_used {
        : ( @ !v LifecycleErr App ) h . lc bs0_fn
        : !v LifecycleErr result ( h a )
        ?? result {
            T err → { ^ @ !v LifecycleErr { F err } }
            F _  → {}
        }
    } {}
    ? . lc bs1_used {
        : ( @ !v LifecycleErr App ) h . lc bs1_fn
        : !v LifecycleErr result ( h a )
        ?? result {
            T err → { ^ @ !v LifecycleErr { F err } }
            F _  → {}
        }
    } {}
    ^ @ !v LifecycleErr { T @ LifecycleErr { `` `` } }
}

@ kit_lifecycle_run_after_start Lifecycle lc App a → v {
    ? . lc as0_used {
        : ( @ !v LifecycleErr App ) h . lc as0_fn
        : !v LifecycleErr result ( h a )
        ?? result { T _ → { ( nurl_print `lifecycle: after_start hook failed\n` ) } F _ → {} }
    } {}
    ? . lc as1_used {
        : ( @ !v LifecycleErr App ) h . lc as1_fn
        : !v LifecycleErr result ( h a )
        ?? result { T _ → { ( nurl_print `lifecycle: after_start hook failed\n` ) } F _ → {} }
    } {}
}

@ kit_lifecycle_run_before_stop Lifecycle lc App a → v {
    ? . lc be0_used {
        : ( @ !v LifecycleErr App ) h . lc be0_fn
        : !v LifecycleErr result ( h a )
        ?? result { T _ → { ( nurl_print `lifecycle: before_stop hook failed\n` ) } F _ → {} }
    } {}
    ? . lc be1_used {
        : ( @ !v LifecycleErr App ) h . lc be1_fn
        : !v LifecycleErr result ( h a )
        ?? result { T _ → { ( nurl_print `lifecycle: before_stop hook failed\n` ) } F _ → {} }
    } {}
}
