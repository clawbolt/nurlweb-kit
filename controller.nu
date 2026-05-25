// nurlweb-kit/controller.nu — RESTful Resource Routing
//
// kit_resources registers all 5 RESTful routes in one call.
// Individual kit_resource_* functions for partial registration.
//
// API:
//   ( kit_resources App a s prefix h_index h_show h_create h_update h_delete ) → v
//   ( kit_resource_index  App a s prefix handler ) → v
//   ( kit_resource_show   App a s prefix handler ) → v
//   ( kit_resource_create App a s prefix handler ) → v
//   ( kit_resource_update App a s prefix handler ) → v
//   ( kit_resource_delete App a s prefix handler ) → v
//
// Usage:
//   // All 5 routes at once
//   ( kit_resources app '/api/users'
//       user_index user_show user_create user_update user_delete )
//
//   // Read-only API (just index + show)
//   ( kit_resource_index app '/api/posts' post_index )
//   ( kit_resource_show  app '/api/posts' post_show )
//
// Handler signature: ( @ HttpResponse HttpRequest Params )
// — same as nurlweb app_get/post/put/patch/delete.

$ `nurlweb/app.nu`
$ `stdlib/core/string.nu`

// ── Individual resource actions ───────────────────────────────────────

@ kit_resource_index App a s prefix ( @ HttpResponse HttpRequest Params ) handler → v {
    ( app_get a prefix handler )
}

@ kit_resource_show App a s prefix ( @ HttpResponse HttpRequest Params ) handler → v {
    : s route ( nurl_str_cat prefix `/:id` )
    ( app_get a route handler )
}

@ kit_resource_create App a s prefix ( @ HttpResponse HttpRequest Params ) handler → v {
    ( app_post a prefix handler )
}

@ kit_resource_update App a s prefix ( @ HttpResponse HttpRequest Params ) handler → v {
    : s route ( nurl_str_cat prefix `/:id` )
    ( app_put a route handler )
}

@ kit_resource_delete App a s prefix ( @ HttpResponse HttpRequest Params ) handler → v {
    : s route ( nurl_str_cat prefix `/:id` )
    ( app_delete a route handler )
}

// ── kit_resources — all 5 routes in one call ──────────────────────────

@ kit_resources App a s prefix
    ( @ HttpResponse HttpRequest Params ) h_index
    ( @ HttpResponse HttpRequest Params ) h_show
    ( @ HttpResponse HttpRequest Params ) h_create
    ( @ HttpResponse HttpRequest Params ) h_update
    ( @ HttpResponse HttpRequest Params ) h_delete → v {
    ( kit_resource_index  a prefix h_index )
    ( kit_resource_show   a prefix h_show )
    ( kit_resource_create a prefix h_create )
    ( kit_resource_update a prefix h_update )
    ( kit_resource_delete a prefix h_delete )
}
