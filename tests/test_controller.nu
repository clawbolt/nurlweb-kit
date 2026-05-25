// tests/test_controller.nu — Controller (kit_resources) tests

$ `nurlweb-kit/controller.nu`
$ `stdlib/ext/http_full.nu`

// Dummy handlers for testing
@ _test_index HttpRequest req Params params → HttpResponse {
    ^ ( response_text 200 `index\n` )
}

@ _test_show HttpRequest req Params params → HttpResponse {
    ^ ( response_text 200 `show\n` )
}

@ _test_create HttpRequest req Params params → HttpResponse {
    ^ ( response_text 201 `created\n` )
}

@ _test_update HttpRequest req Params params → HttpResponse {
    ^ ( response_text 200 `updated\n` )
}

@ _test_delete HttpRequest req Params params → HttpResponse {
    ^ ( response_text 204 `` )
}

// ── Test: kit_resources all 5 routes
@ test_resources_all → i {
    : App app ( app_new `127.0.0.1` 0 )
    ( kit_resources app `/api/tests`
        _test_index _test_show _test_create _test_update _test_delete )
    ^ 0
}

// ── Test: individual kit_resource_index
@ test_resource_index → i {
    : App app ( app_new `127.0.0.1` 0 )
    ( kit_resource_index app `/api/posts` _test_index )
    ^ 0
}

// ── Test: individual kit_resource_show
@ test_resource_show → i {
    : App app ( app_new `127.0.0.1` 0 )
    ( kit_resource_show app `/api/posts` _test_show )
    ^ 0
}

// ── Test: read-only API (index + show)
@ test_readonly_api → i {
    : App app ( app_new `127.0.0.1` 0 )
    ( kit_resource_index app `/api/posts` _test_index )
    ( kit_resource_show  app `/api/posts` _test_show )
    ^ 0
}

@ main → i {
    : i r1 ( test_resources_all )
    : i r2 ( test_resource_index )
    : i r3 ( test_resource_show )
    : i r4 ( test_readonly_api )
    ?? & & & == r1 0 == r2 0 == r3 0 == r4 0 {
        ( nurl_print `all controller tests passed\n` )
        ^ 0
    } {
        ( nurl_print `some controller tests failed\n` )
        ^ 1
    }
}
