// nurlweb-kit/tests/test_basic_runtime.nu — Runtime tests for nurlweb core
// Stability: stable
//
// Verifies App construction, field access, and cleanup at runtime.

$ `nurlweb/app.nu`
$ `stdlib/ext/http_full.nu`

@ test_app_new_fields → i {
    : App a ( app_new `127.0.0.1` 8080 )
    : i ok 1
    // Verify port
    ? != . a port 8080 { = ok 0 } {}
    ( app_free a )
    ^ ok
}

@ test_app_workers → i {
    : App a ( app_new `0.0.0.0` 3000 )
    : App b ( app_with_workers a 4 )
    : i ok 1
    ? != . b worker_count 4 { = ok 0 } {}
    ( app_free b )
    ^ ok
}

@ test_app_dos → i {
    : App a ( app_new `0.0.0.0` 4000 )
    : App b ( app_with_dos a 512 8 )
    : i ok 1
    ? != . b dos_max_conns 512 { = ok 0 } {}
    ? != . b dos_max_per_ip 8 { = ok 0 } {}
    ( app_free b )
    ^ ok
}

@ test_route_registration → i {
    : App a ( app_new `127.0.0.1` 9000 )
    ( app_get a `/`
        \ HttpRequest req Params params → HttpResponse {
            ^ ( response_text 200 `ok\n` )
        })
    ( app_post a `/data`
        \ HttpRequest req Params params → HttpResponse {
            ^ ( response_text 201 `created\n` )
        })
    ( app_free a )
    ^ 1
}

@ test_respond_shortcuts → i {
    // respond_text compiles and returns an HttpResponse
    : HttpResponse r1 ( respond_text 200 `hello` )
    : HttpResponse r2 ( respond_json 200 `{}` )
    : HttpResponse r3 ( respond_html 200 `<p>hi</p>` )
    : HttpResponse r4 ( respond_status 204 )
    : HttpResponse r5 ( respond_redirect 302 `/other` )
    // If we get here without crash, all shortcuts work
    ^ 1
}

@ main → i {
    : i failures 0

    : i r1 ( test_app_new_fields )
    ? == r1 0 { = failures + failures 1 } {}

    : i r2 ( test_app_workers )
    ? == r2 0 { = failures + failures 1 } {}

    : i r3 ( test_app_dos )
    ? == r3 0 { = failures + failures 1 } {}

    : i r4 ( test_route_registration )
    ? == r4 0 { = failures + failures 1 } {}

    : i r5 ( test_respond_shortcuts )
    ? == r5 0 { = failures + failures 1 } {}

    ^ failures
}
