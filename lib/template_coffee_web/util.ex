defmodule TemplateCoffeeWeb.Util do
  @doc """
  Useful for connectiong JS hooks to Temple elements, eg.
  div id: "hooks-need-ids", "phx-hook": temple_hook(__MODULE__, "myHook") do ...
  LiveView HEEx auto-prefixes phx-hook so ".myHook" becomes "MyApp.MyLiveView.myHook"
  behind the scenes, but this won't happen on Temple elements (yet).
  See: https://github.com/mhanberg/temple/issues/287#issuecomment-4972055158
  """
  def temple_phx_hook(module, hook) do
    "#{String.replace_prefix("#{module}", "Elixir.", "")}.#{hook}"
  end
end
