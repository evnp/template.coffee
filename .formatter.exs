[
  import_deps: [:ecto, :ecto_sql, :phoenix, :temple],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter, RegexFormatter],
  inputs: [
    "*.{heex,ex,exs}",
    "{config,lib,test}/**/*.{heex,ex,exs}",
    "priv/*/seeds.exs",
  ],
  regex_formatter: [
    [
      extensions: [
        ".ex",
        ".exs",
      ],
      replacements: [
        # Add trailing commas where possible:
        {~r/(,\n[^}{]*[^,])(\n\s*\})/, ~S'\1,\2'},
        {~r/(,\n[^][]*[^,])(\n\s*\])/, ~S'\1,\2'},
        # Note: The first clause ,\n[^...]* is needed due to complexities avoiding
        #       _incorrectly_ adding trailing commas within sigils. Since sigils may
        #       use [...] or {...} surrounding chars, we can only add trailing commas
        #       where entry above already has comma IMMEDIATELY followed by newline.
      ],
      preset_trim_sigil_whitespace: [:u],
      preset_collapse_sigil_whitespace: [:u],
      preset_do_on_separate_line_after_multiline_keyword_args: true,
    ],
  ],
]
