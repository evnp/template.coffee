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

  def css_props_to_style(css_prop_keyword_list) do
    build_style_str("", false, css_prop_keyword_list)
  end

  def css_vars_to_style(css_var_keyword_list) do
    build_style_str("--", true, css_var_keyword_list)
  end

  defp build_style_str(prop_prefix, quote_values, css_rule_kw_list) do
    for {name, value} <- css_rule_kw_list, into: "" do
      hyphenated_name = name |> to_string() |> String.replace("_", "-")

      maybe_quoted_value =
        if quote_values do
          "'#{value}'"
        else
          value
        end

      " #{prop_prefix}#{hyphenated_name}: #{maybe_quoted_value};"
    end
    |> String.trim_leading()
  end
end
