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

defmodule ColocatedCodeFormatter do
  # Reference Examples:
  # phoenix-live-view.hexdocs.pm/Phoenix.LiveView.HTMLFormatter.TagFormatter.html
  # github.com/phoenixframework/phoenix_live_view/blob/main/lib/prettier.ex

  def render_tag({tag, attrs, content}, _opts) when tag in ["script", "style"] do
    extension =
      case tag do
        "script" -> "js"
        "style" -> "css"
      end

    suffix =
      case attrs do
        # Co-located JS/CSS script or style tag:
        %{":type" => _} -> Map.get(attrs, "manifest", "index.#{extension}")
        # Normal JS/CSS file:
        _ -> "tmp.#{extension}"
      end

    tmp_file =
      Path.join(
        System.tmp_dir!(),
        "prettier_#{System.unique_integer([:positive])}_#{suffix}"
      )

    prettier_executable = Path.expand("assets/node_modules/.bin/prettier")

    try do
      File.write!(tmp_file, content)

      # Note: Avoid setting :stderr_to_stdout here as shown in Phoenix docs/examples.
      #       This leads to error output being prepended directly into the file being
      #       formatted, which is difficult to deal with since the file syntax then
      #       becomes invalid. Instead, simpler setup below will:
      #       - show error output clearly when `mix format` is run manually
      #       - won't do anything (fail gracefully) when formatting runs in-editor
      case System.cmd(prettier_executable, [tmp_file]) do
        {output, 0} -> {:ok, String.trim(output)}
        _ -> :skip
      end
    after
      File.rm(tmp_file)
    end
  end
end

[
  import_deps: [:ecto, :ecto_sql, :phoenix, :temple],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter, ElixirFormatter, RegexFormatter],
  inputs: [
    "*.{heex,ex,exs}",
    "{config,lib,test}/**/*.{heex,ex,exs}",
    "priv/*/seeds.exs",
  ],
  tag_formatters: %{
    script: ColocatedCodeFormatter,
    style: ColocatedCodeFormatter,
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
