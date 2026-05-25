// nurlweb-kit/config.nu — Environment-Aware Config
//
// Startup-time config merging. Loads config/_default.nu as base,
// then overlays config/_<env>.nu based on NURL_ENV (default: "dev").
//
// Config is stored as Vec<ConfigVar> (linear key scan, same pattern
// as template.nu's TemplateVar). Config is read once at startup,
// captured into local variables — never per-request.
//
// API:
//   ( kit_config_new )                                     → Config
//   ( kit_config_load s env )                              → Config
//   ( kit_config_get Config c s key )                      → s
//   ( kit_config_get_i Config c s key )                    → i
//   ( kit_config_get_b Config c s key )                    → b
//   ( kit_config_env )                                     → s
//   ( kit_config_expect Config c s key s expected_type )   → !v ConfigErr
//   ( kit_config_merge Config base Config override )       → Config
//   ( kit_config_free Config c )                           → v

$ `stdlib/core/string.nu`
$ `stdlib/core/vec.nu`
$ `stdlib/std/fs.nu`

// ── Types ─────────────────────────────────────────────────────────────

: ConfigVar {
    String key
    String value
    String type_hint   // "s" | "i" | "b"
}

: ConfigErr {
    String message
}

: Config {
    s env
    ( Vec ConfigVar ) vars
}

// ── Constants ─────────────────────────────────────────────────────────

@ RES_INDEX → i { ^ 1 }
@ RES_SHOW → i { ^ 2 }
@ RES_CREATE → i { ^ 4 }
@ RES_UPDATE → i { ^ 8 }
@ RES_DELETE → i { ^ 16 }
@ RES_ALL → i { ^ 31 }

// ── Constructors ──────────────────────────────────────────────────────

@ kit_config_new → Config {
    : ( Vec ConfigVar ) vars ( vec_new [ConfigVar] )
    ^ @ Config { `dev` vars }
}

@ kit_config_env → s {
    // Read NURL_ENV; default to "dev". NURL stdlib doesn't have getenv,
    // so this returns a placeholder — the actual env is passed to kit_config_load.
    ^ `dev`
}

// ── Loading ───────────────────────────────────────────────────────────

// kit_config_load creates a config from environment name.
// In a real app, this reads config/_default.nu and config/_<env>.nu
// files and merges them. For now, returns an empty config with env set.
@ kit_config_load s env → Config {
    : ( Vec ConfigVar ) vars ( vec_new [ConfigVar] )
    ^ @ Config { env vars }
}

// ── Var helpers ───────────────────────────────────────────────────────

@ __config_find Config c s key → ?ConfigVar {
    : ( Vec ConfigVar ) vs . c vars
    : i n ( vec_len [ConfigVar] vs )
    : ~ i k 0
    ~ < k n {
        : ?ConfigVar cv_opt ( vec_get [ConfigVar] vs k )
        ?? cv_opt {
            T cv → {
                : s cvkey ( string_data . cv key )
                : i match ( nurl_str_eq cvkey key )
                ? != match 0 { ^ @ ?ConfigVar { T cv } } {}
            }
            F → {}
        }
        = k + k 1
    }
    ^ @ ?ConfigVar { F }
}

// ── Getters ───────────────────────────────────────────────────────────

// Returns empty string if key missing — use kit_config_expect for validation.
@ kit_config_get Config c s key → s {
    : ?ConfigVar found ( __config_find c key )
    ?? found {
        T cv → { ^ ( string_data . cv value ) }
        F → { ^ `` }
    }
}

// Returns 0 if key missing or non-numeric — use kit_config_expect for validation.
@ kit_config_get_i Config c s key → i {
    : ?ConfigVar found ( __config_find c key )
    ?? found {
        T cv → {
            : s raw ( string_data . cv value )
            : !i ParseErr ir ( string_to_int raw )
            ?? ir {
                T n → { ^ n }
                F _ → { ^ 0 }
            }
        }
        F → { ^ 0 }
    }
}

// Returns false if key missing or not "true" — use kit_config_expect for validation.
@ kit_config_get_b Config c s key → b {
    : ?ConfigVar found ( __config_find c key )
    ?? found {
        T cv → {
            : s raw ( string_data . cv value )
            : i match ( nurl_str_eq raw `true` )
            ? != match 0 { ^ T } { ^ F }
        }
        F → { ^ F }
    }
}

// ── Set/Add ───────────────────────────────────────────────────────────

@ kit_config_set Config c s key s value s type_hint → v {
    : ( Vec ConfigVar ) vs . c vars
    : ConfigVar cv @ ConfigVar { ( string_data ( nurl_str_cat key `` ) ) ( string_data ( nurl_str_cat value `` ) ) type_hint }
    ( vec_push [ConfigVar] vs cv )
}

// ── Expect (validation) ───────────────────────────────────────────────

// kit_config_expect validates a key exists with the expected type.
// Returns error on failure — call before app_serve to fail fast.
@ kit_config_expect Config c s key s expected_type → !v ConfigErr {
    : ?ConfigVar found ( __config_find c key )
    ?? found {
        T cv → {
            // Key exists — check type if specified
            ? != 0 ( nurl_str_eq expected_type `` ) {
                // Non-empty type hint — validate
                : s actual . cv type_hint
                : i match ( nurl_str_eq actual expected_type )
                ? != match 0 {
                    ^ @ !v ConfigErr { T @ ConfigErr { ( nurl_str_cat3 `type mismatch: key ` key ` expected ` ) } }
                } {
                    ^ @ !v ConfigErr { T @ ConfigErr {} }
                }
            } {
                // Empty type hint — just check existence
                ^ @ !v ConfigErr { T @ ConfigErr {} }
            }
        }
        F → {
            : String msg ( string_with_cap 64 )
            ( string_push_str msg `config error: key "` )
            ( string_push_str msg key )
            ( string_push_str msg `" missing` )
            ^ @ !v ConfigErr { F ( string_data msg ) }
        }
    }
}

// ── Merge ─────────────────────────────────────────────────────────────

// kit_config_merge overlays override config onto base config.
// Keys in override replace keys in base; new keys are appended.
@ kit_config_merge Config base Config override → Config {
    : ( Vec ConfigVar ) base_vars . base vars
    : ( Vec ConfigVar ) over_vars . override vars
    : ( Vec ConfigVar ) result ( vec_new [ConfigVar] )

    // Copy all base vars
    : i bn ( vec_len [ConfigVar] base_vars )
    : ~ i k 0
    ~ < k bn {
        : ?ConfigVar cv_opt ( vec_get [ConfigVar] base_vars k )
        ?? cv_opt {
            T cv → {
                : String rk ( string_data ( nurl_str_cat . cv key `` ) )
                : String rv ( string_data ( nurl_str_cat . cv value `` ) )
                : ConfigVar copy @ ConfigVar { rk rv . cv type_hint }
                ( vec_push [ConfigVar] result copy )
            }
            F → {}
        }
        = k + k 1
    }

    // Apply overrides — replace existing or append
    : i on ( vec_len [ConfigVar] over_vars )
    : ~ i j 0
    ~ < j on {
        : ?ConfigVar ov_opt ( vec_get [ConfigVar] over_vars j )
        ?? ov_opt {
            T ov → {
                : s okey . ov key
                // Find and replace in result
                : i rn ( vec_len [ConfigVar] result )
                : ~ b replaced F
                : ~ i m 0
                ~ & ! replaced < m rn {
                    : ?ConfigVar r_opt ( vec_get [ConfigVar] result m )
                    ?? r_opt {
                        T rv → {
                            : i eq ( nurl_str_eq . rv key okey )
                            ? != eq 0 {
                                // Replace value
                                = . rv value ( string_data ( nurl_str_cat . ov value `` ) )
                                = . rv type_hint . ov type_hint
                                = replaced T
                            } {}
                        }
                        F → {}
                    }
                    = m + m 1
                }
                // If not found, append
                ? ! replaced {
                    : String nk ( string_data ( nurl_str_cat okey `` ) )
                    : String nv ( string_data ( nurl_str_cat . ov value `` ) )
                    : ConfigVar nv cv @ ConfigVar { nk nv . ov type_hint }
                    ( vec_push [ConfigVar] result nv cv )
                } {}
            }
            F → {}
        }
        = j + j 1
    }

    ^ @ Config { . base env result }
}

// ── Free ──────────────────────────────────────────────────────────────

@ kit_config_free Config c → v {
    : ( Vec ConfigVar ) vs . c vars
    : i n ( vec_len [ConfigVar] vs )
    : ~ i k 0
    ~ < k n {
        : ?ConfigVar cv_opt ( vec_get [ConfigVar] vs k )
        ?? cv_opt {
            T cv → {
                ( string_free . cv key )
                ( string_free . cv value )
            }
            F → {}
        }
        = k + k 1
    }
    ( vec_free [ConfigVar] vs )
}
