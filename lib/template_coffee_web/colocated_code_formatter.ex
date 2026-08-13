# Reference Examples:
# phoenix-live-view.hexdocs.pm/Phoenix.LiveView.HTMLFormatter.TagFormatter.html
# github.com/phoenixframework/phoenix_live_view/blob/main/lib/prettier.ex

defmodule ColocatedCodeFormatter do
  @moduledoc false

  @behaviour Phoenix.LiveView.HTMLFormatter.TagFormatter

  require Logger

  @impl true
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

      # Note : Avoid setting :stderr_to_stdout here as shown in Phoenix docs/examples.
      #      : This leads to error output being prepended directly into the file being
      #      : formatted, which is difficult to deal with since the file syntax then
      #      : becomes invalid. Instead, simpler setup below will:
      #      : - show error output clearly when `mix format` is run manually
      #      : - won't do anything (fail gracefully) when formatting runs in-editor
      case System.cmd(prettier_executable, [tmp_file]) do
        {output, 0} -> {:ok, String.trim(output)}
        _ -> :skip
      end
    after
      File.rm(tmp_file)
    end
  end
end
