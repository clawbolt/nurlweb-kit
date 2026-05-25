// nurlweb-kit/service.nu — Service Layer Convention
//
// Services are pure-function modules in services/*.nu. No DI container,
// no registry — just import and call. Explicit parameter passing keeps
// types visible at the call site.
//
// Convention:
//   // services/user_service.nu
//   $ `nurlweb-kit/orm/orm.nu`
//
//   @ find_user OrmDB db i id → !OrmRow DbErr { ... }
//   @ create_user OrmDB db s name s email → !i DbErr { ... }
//   @ update_user OrmDB db i id s name → !i DbErr { ... }
//   @ delete_user OrmDB db i id → !i DbErr { ... }
//
// Usage:
//   $ `services/user_service.nu`
//   : !OrmRow DbErr ur ( find_user db 42 )
//
// kit_service_exists is a compile-time sentinel — callers can reference
// it to verify the convention layer is present. Returns the number of
// service modules currently importable (always 0 — NURL is compile-time).
@ kit_service_exists → i { ^ 0 }
