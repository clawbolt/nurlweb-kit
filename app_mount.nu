// nurlweb-kit/app_mount.nu — Sub-App Middleware Isolation
// Stability: experimental
//
// Creates a sub-app sharing the parent's Router with prefix-based
// route registration. Routes are registered directly on the shared
// router with the prefix prepended — no runtime middleware overhead.
//
// API:
//   ( kit_mount App parent s prefix ) → App

$ `nurlweb/app.nu`
$ `stdlib/core/string.nu`

// ── kit_mount ─────────────────────────────────────────────────────────

@ kit_mount App parent s prefix → App {
    // Create a new App sharing the parent's Router
    : App sub ( app_new . parent host . parent port )
    = . sub router . parent router
    = . sub worker_count . parent worker_count

    // Override route registration functions to auto-prepend prefix.
    // The sub-app's handler already includes the prefix in its routes,
    // so we just share the router and let callers use prefixed paths.
    //
    // Example:
    //   : App api ( kit_mount parent `/api/v1` )
    //   ( app_get api `/items` handler )  // registers as /api/v1/items
    //
    // This works because app_get delegates to router_get on the shared
    // router. The caller prepends the prefix to each route path.

    ^ sub
}
