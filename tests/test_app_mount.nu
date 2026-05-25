// tests/test_app_mount.nu — App mount module tests

$ `nurlweb-kit/app_mount.nu`
$ `stdlib/core/string.nu`

// ── Test: prefix match exact
@ test_prefix_match_exact → i {
    : b m ( __kit_prefix_match `/api/v1` `/api/v1` )
    ? m { ^ 0 } { ^ 1 }
}

// ── Test: prefix match with sub-path
@ test_prefix_match_subpath → i {
    : b m ( __kit_prefix_match `/api/v1` `/api/v1/users` )
    ? m { ^ 0 } { ^ 1 }
}

// ── Test: prefix no match boundary
@ test_prefix_no_match_boundary → i {
    : b m ( __kit_prefix_match `/api/v1` `/api/v10/users` )
    ? ! m { ^ 0 } { ^ 1 }
}

// ── Test: prefix no match different
@ test_prefix_no_match_different → i {
    : b m ( __kit_prefix_match `/api/v1` `/api/v2/users` )
    ? ! m { ^ 0 } { ^ 1 }
}

// ── Test: prefix shorter than path
@ test_prefix_shorter → i {
    : b m ( __kit_prefix_match `/api` `/api/v1` )
    ? m { ^ 0 } { ^ 1 }
}

// ── Test: kit_mount creates sub-app
@ test_mount_creates_sub → i {
    : App parent ( app_new `127.0.0.1` 0 )
    : App sub ( kit_mount parent `/api/v1` )
    // Sub-app should have same host
    : i match ( nurl_str_eq . sub host `127.0.0.1` )
    ? != match 0 { ^ 0 } { ^ 1 }
}

@ main → i {
    : i r1 ( test_prefix_match_exact )
    : i r2 ( test_prefix_match_subpath )
    : i r3 ( test_prefix_no_match_boundary )
    : i r4 ( test_prefix_no_match_different )
    : i r5 ( test_prefix_shorter )
    : i r6 ( test_mount_creates_sub )
    : i ok1 & & == r1 0 == r2 0 == r3 0
    : i ok2 & & == r4 0 == r5 0 == r6 0
    ? & ok1 ok2 {
        ( nurl_print `all mount tests passed\n` )
        ^ 0
    } {
        ( nurl_print `some mount tests failed\n` )
        ^ 1
    }
}
