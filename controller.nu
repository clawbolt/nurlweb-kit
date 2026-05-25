// nurlweb-kit/controller.nu — Resource Routing with Bitmask Selection
//
// kit_resources registers RESTful routes in one call. Uses ResourceHandlers
// struct to group 5 handler closures + a bitmask for route selection.
//
// Bitmask constants (defined in config.nu for central access):
//   RES_INDEX  = 1  → GET    /prefix        → index_fn
//   RES_SHOW   = 2  → GET    /prefix/:id     → show_fn
//   RES_CREATE = 4  → POST   /prefix         → create_fn
//   RES_UPDATE = 8  → PUT    /prefix/:id     → update_fn
//   RES_DELETE = 16 → DELETE /prefix/:id     → delete_fn
//   RES_ALL    = 31 → all routes
//
// API:
//   ( kit_resources App a ResourceHandlers rh ) → v

$ `nurlweb/app.nu`

// ── ResourceHandlers struct ────────────────────────────────────────────

: ResourceHandlers {
    s prefix
    ( @ HttpResponse HttpRequest Params ) index_fn
    ( @ HttpResponse HttpRequest Params ) show_fn
    ( @ HttpResponse HttpRequest Params ) create_fn
    ( @ HttpResponse HttpRequest Params ) update_fn
    ( @ HttpResponse HttpRequest Params ) delete_fn
    i routes   // bitmask
}

// ── Bitmask constants ─────────────────────────────────────────────────

@ RES_INDEX → i { ^ 1 }
@ RES_SHOW → i { ^ 2 }
@ RES_CREATE → i { ^ 4 }
@ RES_UPDATE → i { ^ 8 }
@ RES_DELETE → i { ^ 16 }
@ RES_ALL → i { ^ 31 }

// ── kit_resources ─────────────────────────────────────────────────────

// Registers RESTful routes based on bitmask. Each bit enables one route.
@ kit_resources App a ResourceHandlers rh → v {
    : s prefix . rh prefix
    : i mask . rh routes

    // RES_INDEX: GET /prefix
    ? & > 0 mask 0 {
        : i bit ( & mask 1 )
        ? != bit 0 {
            ( app_get a prefix . rh index_fn )
        } {}
    } {}

    // RES_SHOW: GET /prefix/:id
    ? >= mask 2 {
        : i bit ( & mask 2 )
        ? != bit 0 {
            : s show_route ( nurl_str_cat prefix `/:id` )
            ( app_get a show_route . rh show_fn )
        } {}
    } {}

    // RES_CREATE: POST /prefix
    ? >= mask 4 {
        : i bit ( & mask 4 )
        ? != bit 0 {
            ( app_post a prefix . rh create_fn )
        } {}
    } {}

    // RES_UPDATE: PUT /prefix/:id
    ? >= mask 8 {
        : i bit ( & mask 8 )
        ? != bit 0 {
            : s update_route ( nurl_str_cat prefix `/:id` )
            ( app_put a update_route . rh update_fn )
        } {}
    } {}

    // RES_DELETE: DELETE /prefix/:id
    ? >= mask 16 {
        : i bit ( & mask mask 16 )
        ? != bit 0 {
            : s delete_route ( nurl_str_cat prefix `/:id` )
            ( app_delete a delete_route . rh delete_fn )
        } {}
    } {}
}
