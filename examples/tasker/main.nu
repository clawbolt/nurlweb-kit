// tasker/main.nu — Real-world task management API
//
// Business scenario: project task tracker with:
//   - CRUD for tasks (title, status: todo/doing/done)
//   - CRUD for comments on tasks
//   - Input validation (required fields, valid status)
//   - JSON request/response
//   - Proper HTTP status codes
//   - Graceful 404 for missing resources
//
// Port: 3960

$ `nurlweb/app.nu`
$ `stdlib/ext/http_full.nu`
$ `stdlib/ext/json.nu`
$ `stdlib/core/vec.nu`
$ `stdlib/core/string.nu`

// ── Data models ──────────────────────────────────────────────────────

: Task {
    i id
    String title
    String status
}

: Comment {
    i id
    i task_id
    String body
    String author
}

// ── Data stores ──────────────────────────────────────────────────────

@ task_new i id s title s status → Task {
    : String t ( string_new )
    ( string_push_str t title )
    : String s ( string_new )
    ( string_push_str s status )
    ^ @ Task { id t s }
}

@ comment_new i id i task_id s body s author → Comment {
    : String b ( string_new )
    ( string_push_str b body )
    : String a ( string_new )
    ( string_push_str a author )
    ^ @ Comment { id task_id b a }
}

// ── JSON helpers ─────────────────────────────────────────────────────

@ parse_body HttpRequest req → !Json ParseErr {
    : i n ( vec_len [u] . req body )
    ? > n 0 {
        : *u data ( vec_data [u] . req body )
        : String bs ( string_from_bytes data n )
        : s raw ( string_data bs )
        : !Json ParseErr jr ( json_parse raw )
        ( string_free bs )
        ^ jr
    } { ^ @ !Json ParseErr { F @ ParseErr { Empty } } }
}

@ str_to_id s raw → i {
    : i v ( nurl_str_to_int raw )
    ? != v 0 { ^ v } {
        ? == ( nurl_str_get raw 0 ) 48 { ^ 0 } { ^ -1 }
    }
}

@ is_valid_status s status → b {
    : i eq_todo ( nurl_str_eq status `todo` )
    ? != eq_todo 0 { ^ T } {}
    : i eq_doing ( nurl_str_eq status `doing` )
    ? != eq_doing 0 { ^ T } {}
    : i eq_done ( nurl_str_eq status `done` )
    ? != eq_done 0 { ^ T } {}
    ^ F
}

// ── Task handlers ────────────────────────────────────────────────────

@ handle_list_tasks ( Vec Task ) tasks HttpRequest req Params params → HttpResponse {
    : String out ( string_with_cap 512 )
    ( string_push_str out `[\n` )
    : i n ( vec_len [Task] tasks )
    : ~ i k 0
    ~ < k n {
        : ?Task t_opt ( vec_get [Task] tasks k )
        ?? t_opt {
            T t → {
                ( string_push_str out `  {"id":` )
                ( string_push_int out . t id )
                ( string_push_str out `,"title":"` )
                ( string_push_str out ( string_data . t title ) )
                ( string_push_str out `","status":"` )
                ( string_push_str out ( string_data . t status ) )
                ( string_push_str out `"}` )
                ? < + k 1 n { ( string_push_str out `,\n` ) } { ( string_push_str out `\n` ) }
            }
            F → {}
        }
        = k + k 1
    }
    ( string_push_str out `]\n` )
    : HttpResponse r ( response_text 200 ( string_data out ) )
    ( response_set_header r `Content-Type` `application/json` )
    ( string_free out )
    ^ r
}

@ handle_create_task ( Vec Task ) tasks HttpRequest req Params params → HttpResponse {
    : !Json ParseErr jr ( parse_body req )
    ?? jr {
        T j → {
            // Validate title (required)
            : ?Json title_opt ( json_obj_get j `title` )
            ?? title_opt {
                T title_json → {
                    ? ! ( json_is_str title_json ) {
                        ^ ( response_text 400 `title must be a string\n` )
                    } {}
                    : s title_str ( json_str_data title_json )
                    // Validate status (optional, defaults to "todo")
                    : s status_val `todo`
                    : ?Json status_opt ( json_obj_get j `status` )
                    ?? status_opt {
                        T status_json → {
                            ? ( json_is_str status_json ) {
                                : s sv ( json_str_data status_json )
                                : b valid ( is_valid_status sv )
                                ? valid {
                                    : String sc ( string_new )
                                    ( string_push_str sc sv )
                                    = status_val ( string_data sc )
                                } {
                                    ^ ( response_text 400 `status must be one of: todo, doing, done\n` )
                                }
                            } {}
                        }
                        F → {}
                    }
                    : i n ( vec_len [Task] tasks )
                    : Task t ( task_new n title_str status_val )
                    ( vec_push [Task] tasks t )
                    // Return created task
                    : String out ( string_with_cap 128 )
                    ( string_push_str out `{"id":` )
                    ( string_push_int out n )
                    ( string_push_str out `,"title":"` )
                    ( string_push_str out title_str )
                    ( string_push_str out `","status":"` )
                    ( string_push_str out status_val )
                    ( string_push_str out `"}\n` )
                    : HttpResponse r ( response_text 201 ( string_data out ) )
                    ( response_set_header r `Content-Type` `application/json` )
                    ( string_free out )
                    ^ r
                }
                F → { ^ ( response_text 400 `missing title field\n` ) }
            }
        }
        F _ → { ^ ( response_text 400 `invalid json body\n` ) }
    }
}

@ handle_update_task ( Vec Task ) tasks HttpRequest req Params params → HttpResponse {
    : ?String id_opt ( params_get params `id` )
    ?? id_opt {
        T sid → {
            : i id ( str_to_id ( string_data sid ) )
            ? < id 0 { ^ ( response_text 400 `invalid id\n` ) } {}
            : i n ( vec_len [Task] tasks )
            : ~ i k 0
            ~ < k n {
                : ?Task t_opt ( vec_get [Task] tasks k )
                ?? t_opt {
                    T t → {
                        ? == . t id id {
                            : !Json ParseErr jr ( parse_body req )
                            ?? jr {
                                T j → {
                                    : ?Json title_opt ( json_obj_get j `title` )
                                    ?? title_opt {
                                        T title_json → {
                                            ? ( json_is_str title_json ) {
                                                : s ns ( json_str_data title_json )
                                                ( string_free . t title )
                                                : String nm ( string_new )
                                                ( string_push_str nm ns )
                                                = . t title nm
                                            } {}
                                        }
                                        F → {}
                                    }
                                    // Update status if provided
                                    : ?Json status_opt ( json_obj_get j `status` )
                                    ?? status_opt {
                                        T status_json → {
                                            ? ( json_is_str status_json ) {
                                                : s sv ( json_str_data status_json )
                                                : b valid ( is_valid_status sv )
                                                ? valid {
                                                    ( string_free . t status )
                                                    : String sc ( string_new )
                                                    ( string_push_str sc sv )
                                                    = . t status sc
                                                } {
                                                    ^ ( response_text 400 `status must be one of: todo, doing, done\n` )
                                                }
                                            } {}
                                        }
                                        F → {}
                                    }
                                    // Return updated task
                                    : String out ( string_with_cap 128 )
                                    ( string_push_str out `{"id":` )
                                    ( string_push_int out . t id )
                                    ( string_push_str out `,"title":"` )
                                    ( string_push_str out ( string_data . t title ) )
                                    ( string_push_str out `","status":"` )
                                    ( string_push_str out ( string_data . t status ) )
                                    ( string_push_str out `"}\n` )
                                    : HttpResponse r ( response_text 200 ( string_data out ) )
                                    ( response_set_header r `Content-Type` `application/json` )
                                    ( string_free out )
                                    ^ r
                                }
                                F _ → { ^ ( response_text 400 `invalid json body\n` ) }
                            }
                        } {}
                    }
                    F → {}
                }
                = k + k 1
            }
            ^ ( response_text 404 `task not found\n` )
        }
        F → { ^ ( response_text 400 `missing id\n` ) }
    }
}

@ handle_delete_task ( Vec Task ) tasks HttpRequest req Params params → HttpResponse {
    : ?String id_opt ( params_get params `id` )
    ?? id_opt {
        T sid → {
            : i id ( str_to_id ( string_data sid ) )
            ? < id 0 { ^ ( response_text 400 `invalid id\n` ) } {}
            : i n ( vec_len [Task] tasks )
            : ~ i k 0
            ~ < k n {
                : ?Task t_opt ( vec_get [Task] tasks k )
                ?? t_opt {
                    T t → {
                        ? == . t id id {
                            ( string_free . t title )
                            ( string_free . t status )
                            ( vec_remove [Task] tasks k )
                            ^ ( response_text 204 `` )
                        } {}
                    }
                    F → {}
                }
                = k + k 1
            }
            ^ ( response_text 404 `task not found\n` )
        }
        F → { ^ ( response_text 400 `missing id\n` ) }
    }
}

// ── Comment handlers (scoped to a task) ──────────────────────────────

@ handle_list_comments ( Vec Comment ) comments HttpRequest req Params params → HttpResponse {
    : ?String tid_opt ( params_get params `task_id` )
    ?? tid_opt {
        T stid → {
            : i task_id ( str_to_id ( string_data stid ) )
            : String out ( string_with_cap 512 )
            ( string_push_str out `[\n` )
            : i n ( vec_len [Comment] comments )
            : i first 1
            : ~ i k 0
            ~ < k n {
                : ?Comment c_opt ( vec_get [Comment] comments k )
                ?? c_opt {
                    T c → {
                        ? == . c task_id task_id {
                            ? == first 0 { ( string_push_str out `,\n` ) } { = first 0 }
                            ( string_push_str out `  {"id":` )
                            ( string_push_int out . c id )
                            ( string_push_str out `,"task_id":` )
                            ( string_push_int out . c task_id )
                            ( string_push_str out `,"body":"` )
                            ( string_push_str out ( string_data . c body ) )
                            ( string_push_str out `","author":"` )
                            ( string_push_str out ( string_data . c author ) )
                            ( string_push_str out `"}` )
                        } {}
                    }
                    F → {}
                }
                = k + k 1
            }
            ( string_push_str out `\n]\n` )
            : HttpResponse r ( response_text 200 ( string_data out ) )
            ( response_set_header r `Content-Type` `application/json` )
            ( string_free out )
            ^ r
        }
        F → { ^ ( response_text 400 `missing task_id\n` ) }
    }
}

@ handle_create_comment ( Vec Comment ) comments HttpRequest req Params params → HttpResponse {
    : ?String tid_opt ( params_get params `task_id` )
    ?? tid_opt {
        T stid → {
            : i task_id ( str_to_id ( string_data stid ) )
            : !Json ParseErr jr ( parse_body req )
            ?? jr {
                T j → {
                    : ?Json body_opt ( json_obj_get j `body` )
                    ?? body_opt {
                        T body_json → {
                            ? ! ( json_is_str body_json ) {
                                ^ ( response_text 400 `body must be a string\n` )
                            } {}
                            : s body_str ( json_str_data body_json )
                            // author defaults to "anonymous" if not provided
                            : s author_str `anonymous`
                            : ?Json author_opt ( json_obj_get j `author` )
                            ?? author_opt {
                                T author_json → {
                                    ? ( json_is_str author_json ) {
                                        = author_str ( json_str_data author_json )
                                    } {}
                                }
                                F → {}
                            }
                            : i n ( vec_len [Comment] comments )
                            : Comment c ( comment_new n task_id body_str author_str )
                            ( vec_push [Comment] comments c )
                            : String out ( string_with_cap 128 )
                            ( string_push_str out `{"id":` )
                            ( string_push_int out n )
                            ( string_push_str out `,"task_id":` )
                            ( string_push_int out task_id )
                            ( string_push_str out `,"body":"` )
                            ( string_push_str out body_str )
                            ( string_push_str out `","author":"` )
                            ( string_push_str out author_str )
                            ( string_push_str out `"}\n` )
                            : HttpResponse r ( response_text 201 ( string_data out ) )
                            ( response_set_header r `Content-Type` `application/json` )
                            ( string_free out )
                            ^ r
                        }
                        F → { ^ ( response_text 400 `missing body field\n` ) }
                    }
                }
                F _ → { ^ ( response_text 400 `invalid json body\n` ) }
            }
        }
        F → { ^ ( response_text 400 `missing task_id\n` ) }
    }
}

// ── Main ──────────────────────────────────────────────────────────────

@ main → i {
    : App app ( app_new `127.0.0.1` 3960 )

    : ( Vec Task ) tasks ( vec_new [Task] )
    : ( Vec Comment ) comments ( vec_new [Comment] )

    // ── Task routes ───────────────────────────────────────────────
    ( app_get app `/api/tasks`
        \ HttpRequest req Params params → HttpResponse {
            ^ ( handle_list_tasks tasks req params )
        })

    ( app_post app `/api/tasks`
        \ HttpRequest req Params params → HttpResponse {
            ^ ( handle_create_task tasks req params )
        })

    ( app_put app `/api/tasks/:id`
        \ HttpRequest req Params params → HttpResponse {
            ^ ( handle_update_task tasks req params )
        })

    ( app_delete app `/api/tasks/:id`
        \ HttpRequest req Params params → HttpResponse {
            ^ ( handle_delete_task tasks req params )
        })

    // ── Comment routes (nested under task) ────────────────────────
    ( app_get app `/api/tasks/:task_id/comments`
        \ HttpRequest req Params params → HttpResponse {
            ^ ( handle_list_comments comments req params )
        })

    ( app_post app `/api/tasks/:task_id/comments`
        \ HttpRequest req Params params → HttpResponse {
            ^ ( handle_create_comment comments req params )
        })

    // ── Health check ──────────────────────────────────────────────
    ( app_get app `/health`
        \ HttpRequest req Params params → HttpResponse {
            ^ ( response_text 200 `{"status":"ok"}\n` )
        })

    ( nurl_print `tasker API on http://127.0.0.1:3960\n` )
    ( nurl_print `  Tasks:    GET/POST /api/tasks\n` )
    ( nurl_print `  Comments: GET/POST /api/tasks/:id/comments\n` )

    : !v NetErr rr ( app_serve app )
    ( app_free app )
    ?? rr { T _ → { ^ 0 } F _ → { ^ 1 } }
}
