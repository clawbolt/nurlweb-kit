// nurlweb-kit/template_convention.nu — Template Auto-Resolve
// Stability: experimental
//
// Resolves template name to templates/{name}.html and renders using
// nurlweb's existing template_file function.
//
// API:
//   ( kit_template_auto s name ( Vec TemplateVar ) vars ) → !String IoErr

$ `nurlweb-kit/view/template.nu`
$ `stdlib/core/string.nu`

// ── Auto-resolve ──────────────────────────────────────────────────────

@ kit_template_auto s name ( Vec TemplateVar ) vars → !String IoErr {
    : String path ( string_with_cap 64 )
    ( string_push_str path `templates/` )
    ( string_push_str path name )
    ( string_push_str path `.html` )
    ^ ( template_file ( string_data path ) vars )
}
