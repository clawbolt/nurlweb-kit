// tests/test_logger.nu — Logger module tests

$ `nurlweb-kit/logger.nu`

// ── Test: kit_log_info outputs JSON line
@ test_log_info → i {
    // kit_log_info prints to stdout — compile test only
    ( kit_log_info `test message` )
    ^ 0
}

// ── Test: kit_log_error outputs
@ test_log_error → i {
    ( kit_log_error `error message` )
    ^ 0
}

// ── Test: kit_log_warn outputs
@ test_log_warn → i {
    ( kit_log_warn `warning message` )
    ^ 0
}

// ── Test: kit_log_debug outputs
@ test_log_debug → i {
    ( kit_log_debug `debug message` )
    ^ 0
}

// ── Test: kit_log_with_fields outputs structured JSON
@ test_log_with_fields → i {
    : ( Vec LogField ) fields ( vec_new [LogField] )
    : LogField f1 @ LogField { `key1` `value1` }
    ( vec_push [LogField] fields f1 )
    ( kit_log_with_fields `structured message` fields )
    ^ 0
}

// ── Test: kit_log_set_level is callable
@ test_log_set_level → i {
    ( kit_log_set_level `warn` )
    ^ 0
}

@ main → i {
    : i r1 ( test_log_info )
    : i r2 ( test_log_error )
    : i r3 ( test_log_warn )
    : i r4 ( test_log_debug )
    : i r5 ( test_log_with_fields )
    : i r6 ( test_log_set_level )
    : i ok1 & & == r1 0 == r2 0 == r3 0
    : i ok2 & & == r4 0 == r5 0 == r6 0
    ? & ok1 ok2 {
        ( nurl_print `all logger tests passed\n` )
        ^ 0
    } {
        ( nurl_print `some logger tests failed\n` )
        ^ 1
    }
}
