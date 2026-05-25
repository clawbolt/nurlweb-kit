// nurlweb-kit/service.nu — Service Layer Convention
//
// Services are pure functions in services/*.nu. No DI container,
// no registry — just import and call. Explicit parameter passing.
//
// Convention:
//   // services/user_service.nu
//   $ `nurlweb/orm.nu`
//   @ find_user OrmDB db i id → !OrmRow DbErr { ... }
//   @ create_user OrmDB db s name s email → !i DbErr { ... }
//   @ update_user OrmDB db i id s name → !i DbErr { ... }
//   @ delete_user OrmDB db i id → !i DbErr { ... }
//
// This file exists for convention discovery and future extension.
// No runtime code — services are imported directly where needed.
