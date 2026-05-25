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

// ── Test: RES_ALL bitmask value
@ test_res_all → i {
    : i all RES_ALL
    ? == all 31 { ^ 0 } { ^ 1 }
}

// ── Test: bitmask constants
@ test_bitmask_constants → i {
    ? & & & == RES_INDEX 1 == RES_SHOW 2 == RES_CREATE 4 {
        ? & == RES_UPDATE 8 == RES_DELETE 16 { ^ 0 } { ^ 1 }
    } { ^ 1 }
}

// ── Test: kit_resources with RES_ALL
@ test_resources_all → i {
    : App app ( app_new `127.0.0.1` 0 )
    : ResourceHandlers rh @ ResourceHandlers {
        `/api/tests`
        _test_index
        _test_show
        _test_create
        _test_update
        _test_delete
        RES_ALL
    }
    ( kit_resources app rh )
    ^ 0
}

// ── Test: kit_resources with RES_INDEX only
@ test_resources_index_only → i {
    : App app ( app_new `127.0.0.1` 0 )
    : ResourceHandlers rh @ ResourceHandlers {
        `/api/tests`
        _test_index
        _test_show
        _test_create
        _test_update
        _test_delete
        RES_INDEX
    }
    ( kit_resources app rh )
    ^ 0
}

// ── Test: kit_resources with RES_INDEX + RES_SHOW
@ test_resources_index_show → i {
    : App app ( app_new `127.0.0.1` 0 )
    : ResourceHandlers rh @ ResourceHandlers {
        `/api/tests`
        _test_index
        _test_show
        _test_create
        _test_update
        _test_delete
        + RES_INDEX RES_SHOW
    }
    ( kit_resources app rh )
    ^ 0
}

@ main → i {
    : i r1 ( test_res_all )
    : i r2 ( test_bitmask_constants )
    : i r3 ( test_resources_all )
    : i r4 ( test_resources_index_only )
    : i r5 ( test_resources_index_show )
    ?? & & & == r1 0 == r2 0 & == r3 0 == r4 0 == r5 0 {
        ( nurl_print `all controller tests passed\n` )
        ^ 0
    } {
        ( nurl_print `some controller tests failed\n` )
        ^ 1
    }
}
