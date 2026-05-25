// tests/test_config.nu — Config module tests

$ `nurlweb-kit/config.nu`

// ── Test: config new creates empty config
@ test_config_new → i {
    : Config c ( kit_config_new )
    : s env . c env
    : i match ( nurl_str_eq env `dev` )
    ? != match 0 { ^ 0 } { ^ 1 }
}

// ── Test: config set and get
@ test_config_set_get → i {
    : Config c ( kit_config_new )
    ( kit_config_set c `port` `3900` `i` )
    : s val ( kit_config_get c `port` )
    : i match ( nurl_str_eq val `3900` )
    ? != match 0 { ^ 0 } { ^ 1 }
}

// ── Test: config get missing key returns empty
@ test_config_get_missing → i {
    : Config c ( kit_config_new )
    : s val ( kit_config_get c `nonexistent` )
    : i match ( nurl_str_eq val `` )
    ? != match 0 { ^ 0 } { ^ 1 }
}

// ── Test: config get_i
@ test_config_get_i → i {
    : Config c ( kit_config_new )
    ( kit_config_set c `port` `8080` `i` )
    : i val ( kit_config_get_i c `port` )
    ? == val 8080 { ^ 0 } { ^ 1 }
}

// ── Test: config get_i non-numeric returns 0
@ test_config_get_i_non_numeric → i {
    : Config c ( kit_config_new )
    ( kit_config_set c `port` `notanumber` `i` )
    : i val ( kit_config_get_i c `port` )
    ? == val 0 { ^ 0 } { ^ 1 }
}

// ── Test: config get_b true
@ test_config_get_b_true → i {
    : Config c ( kit_config_new )
    ( kit_config_set c `debug` `true` `b` )
    : b val ( kit_config_get_b c `debug` )
    ? val { ^ 0 } { ^ 1 }
}

// ── Test: config get_b false
@ test_config_get_b_false → i {
    : Config c ( kit_config_new )
    ( kit_config_set c `debug` `false` `b` )
    : b val ( kit_config_get_b c `debug` )
    ? ! val { ^ 0 } { ^ 1 }
}

// ── Test: config expect missing key returns error
@ test_config_expect_missing → i {
    : Config c ( kit_config_new )
    : !v ConfigErr r ( kit_config_expect c `port` `i` )
    ?? r {
        T _ → { ^ 0 }   // error = pass
        F _ → { ^ 1 }   // no error = fail
    }
}

// ── Test: config merge overrides
@ test_config_merge → i {
    : Config base ( kit_config_new )
    ( kit_config_set base `port` `3000` `i` )
    ( kit_config_set base `host` `localhost` `s` )

    : Config over ( kit_config_new )
    ( kit_config_set over `port` `8080` `i` )

    : Config merged ( kit_config_merge base over )
    : s port ( kit_config_get merged `port` )
    : i match_port ( nurl_str_eq port `8080` )
    ? != match_port 0 { ^ 0 } { ^ 1 }
}

@ main → i {
    : i r1 ( test_config_new )
    : i r2 ( test_config_set_get )
    : i r3 ( test_config_get_missing )
    : i r4 ( test_config_get_i )
    : i r5 ( test_config_get_i_non_numeric )
    : i r6 ( test_config_get_b_true )
    : i r7 ( test_config_get_b_false )
    : i r8 ( test_config_expect_missing )
    : i r9 ( test_config_merge )
    ?? & & & & & & & & == r1 0 == r2 0 == r3 0 == r4 0 == r5 0 == r6 0 == r7 0 == r8 0 == r9 0 {
        ( nurl_print `all config tests passed\n` )
        ^ 0
    } {
        ( nurl_print `some config tests failed\n` )
        ^ 1
    }
}
