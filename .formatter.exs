# Plugin/Custom formatter modules are placed directly in .formatters.exs so we
# can avoid the constant recompilation that would be needed otherwise.
# This helps avoid the need for constant Phoenix devserver restarts.
# Always run `mix format` with `--no-compile` flag.
# Editor-integrated formatting should do this automatically so it doesn't need to be
# added/remembered manually.

defmodule ElixirFormatter do
  # This plugin replaces standard Elixir formatting when used alongside another
  # plugin that targets .ex/.exs files. Normally, these plugins would fully disable
  # standard Elixir formatting; adding this to the plugins list restores it.
  # For more context, see: https://github.com/elixir-lang/elixir/pull/15742

  @behaviour Mix.Tasks.Format

  def features(_opts) do
    [sigils: [], extensions: [".ex", ".exs"]]
  end

  def format(contents, opts) do
    formatted = Code.format_string!(contents, opts)
    IO.iodata_to_binary([formatted, ?\n])
  end
end

[
  import_deps: [:ecto, :ecto_sql, :phoenix, :temple],
  subdirectories: ["priv/*/migrations"],
  plugins: [
    ElixirFormatter,
    Coloco.Format.PreHTMLFormatterPlugin,
    Phoenix.LiveView.HTMLFormatter,
    Coloco.Format.PostHTMLFormatterPlugin,
    RegexFormatter,
  ],
  inputs: [
    "*.{heex,ex,exs}",
    "{config,lib,test}/**/*.{heex,ex,exs}",
    "priv/*/seeds.exs",
  ],
  tag_formatters: %{
    script: Coloco.Format.PrettierTagFormatter,
    style: Coloco.Format.PrettierTagFormatter,
  },
  regex_formatter: [
    [
      extensions: [
        ".ex",
        ".exs",
      ],
      replacements: [
        # Add trailing commas where possible:
        {~r/(,\n[^}{]*[^,])(\n\s*\})/, ~S'\1,\2'},
        {~r/(,\n[^][]*[^,])(\n\s*\])/, ~S'\1,\2'}
        # Note: The first clause ,\n[^...]* is needed due to complexities avoiding
        #       _incorrectly_ adding trailing commas within sigils. Since sigils may
        #       use [...] or {...} surrounding chars, we can only add trailing commas
        #       where entry above already has comma IMMEDIATELY followed by newline.
      ],
      preset_trim_sigil_whitespace: [:u],
      preset_collapse_sigil_whitespace: [:u],
      preset_do_on_separate_line_after_multiline_keyword_args: true
    ],
  ]
]
