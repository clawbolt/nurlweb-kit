# nurlweb-kit — Convention Layer for NurlWeb

Egg.js-equivalent convention-over-configuration framework, built **on top of** nurlweb. Same relationship as Egg.js → Koa: nurlweb stays the thin micro-framework, kit adds conventions, structure, CLI generators, config, lifecycle, and structured logging.

## Modules

| Module | Functions | Description |
|--------|-----------|-------------|
| `config.nu` | `kit_config_load`, `kit_config_get`, `kit_config_get_i`, `kit_config_get_b`, `kit_config_expect`, `kit_config_merge`, `kit_config_free` | Environment-aware config with startup-time merging |
| `lifecycle.nu` | `kit_lifecycle_new`, `kit_lifecycle_before_start/after_start/before_stop`, `kit_lifecycle_run_*`, `kit_lifecycle_free` | App lifecycle hooks with error boundaries |
| `controller.nu` | `kit_resources` + `ResourceHandlers` struct + bitmask constants | RESTful route generation (5 routes in one call) |
| `service.nu` | Convention documentation only | Pure-function service layer |
| `logger.nu` | `kit_log_info/warn/error/debug`, `kit_log_with_fields`, `kit_with_logger` | Structured JSON logging with `kit_` prefix |
| `app_mount.nu` | `kit_mount` | Sub-app middleware isolation with prefix matching |
| `template_convention.nu` | `kit_template_auto` | Template file auto-resolve |

## Quick Start

```bash
# Scaffold a new project
nurlweb-kit/bin/nurlweb-kit new myapp
cd myapp

# Generate a CRUD scaffold
nurlweb-kit/bin/nurlweb-kit g scaffold post title:s body:s

# Build and run
sh build.sh && ./app
```

## Real Scenario

See `examples/tasker/` for a project task tracker API that exercises task CRUD, nested comments, JSON validation, and real HTTP smoke checks.

## kit_resources

Register 5 RESTful routes in one call:

```nurl
: ResourceHandlers rh @ ResourceHandlers {
    `/api/users`
    user_index user_show user_create user_update user_delete
    RES_ALL   // = 31, all 5 routes
}
( kit_resources app rh )
```

Use bitmask to select specific routes:

```nurl
// Only index + show (read-only API)
routes: + RES_INDEX RES_SHOW   // = 3
```

## Config

```nurl
: Config cfg ( kit_config_load `dev` )
( kit_config_set cfg `port` `8080` `i` )
( kit_config_expect cfg `port` `i` )   // fail fast if missing
: i port ( kit_config_get_i cfg `port` )
```

## Lifecycle

```nurl
: Lifecycle lc ( kit_lifecycle_new )
( kit_lifecycle_before_start lc \ App a → !v LifecycleErr {
    // Connect to DB, validate config, etc.
    ^ @ !v LifecycleErr { T @ LifecycleErr { `` `` } }
})
: !v LifecycleErr lc_ok ( kit_lifecycle_run_before_start lc app )
?? lc_ok {
    T _ → { ^ 1 }  // hooks failed, abort
    F _ → {}        // ok, continue
}
```

## License

MIT OR Apache-2.0
