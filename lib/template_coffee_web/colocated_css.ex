defmodule TemplateCoffeeWeb.ColocatedGlobalCSS do
  use Phoenix.LiveView.ColocatedCSS

  @impl true
  def transform("style", _attrs, css, _meta) do
    {:ok, css, []}
  end
end

# Simplified scoped-colocated-CSS implementation that works with Temple, adapted from:
# phoenix-live-view.hexdocs.pm/Phoenix.LiveView.ColocatedCSS.html#module-scoped-css
defmodule TemplateCoffeeWeb.ColocatedScopedCSS do
  use Phoenix.LiveView.ColocatedCSS

  def scope(env, _style_heex \\ "") do
    "scope-#{hash("#{env.module}-#{env.line}")}"
    # Notes: "scope-" prefix is needed because hash will sometimes start with 0..9
    #        instead of A-Z, won't work as CSS class string (can't start with number).
    #        Unused _style_heex param allows specifying <style> HEEx template
    #        on the same line as the CSS data-scope or class is set, eg.
    #
    #        data-scope={ColocatedScopedCSS.scope(__ENV__, ~H"""...""")}
    #        OR
    #        class="my-elm #{ColocatedScopedCSS.scope(__ENV__, ~H"""...""")}"
    #
    #        This helps ensure that __ENV__.line (from scoped element) and meta.line
    #        (from colocated-CSS system) will match when scope hash is computed above.
  end

  @impl true
  def transform("style", _attrs, css, meta) do
    scope_str = scope(meta)
    # Specify attr-based and class-based selectors in upper_bound_selector:
    # (either can be used, depending on what's most convenient in the given template)
    upper_bound_selector = ~s|[data-scope="#{scope_str}"], .#{scope_str}|
    lower_bound_selector = ~s|[data-unscope]|
    css = "@scope (#{upper_bound_selector}) to (#{lower_bound_selector}) { #{css} }"
    {:ok, css, []}
  end

  defp hash(string) do
    # It is important that we do not pad
    # the Base32 encoded value as we use it in
    # an HTML attribute name and = (the padding character)
    # is not valid.
    string
    |> then(&:crypto.hash(:md5, &1))
    |> Base.encode32(case: :lower, padding: false)
  end
end
