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

  @legacy_browser_compat true

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

  def descope(env) do
    "descope-#{hash("#{env.module}")}"
    # Notes: Descoping operates on a module basis -- no line numbers.
    #        This allows descope attrs on different lines from the parent scope attr
    #        to still connect to generated scope CSS even though line is different.
  end

  @impl true
  def transform("style", _attrs, css, meta) do
    scope_str = scope(meta)
    descope_str = descope(meta)

    # Specify attr-based and class-based selectors in upper_bound_selector:
    # (either can be used, depending on what's most convenient in the given template)
    upper_bound_selector = ~s|:is([data-scope="#{scope_str}"], .#{scope_str})|
    lower_bound_selector = ~s|:is([data-descope="#{descope_str}"], .#{descope_str})|

    css =
      if @legacy_browser_compat do
        transform_css_legacy_compat(css, upper_bound_selector, lower_bound_selector)
      else
        transform_css_modern(css, upper_bound_selector, lower_bound_selector)
      end

    {:ok, css, []}
    # We don't need to return a :tag_attribute here as you normally would, because
    # when using CSS-scoping with Temple we'll apply the scoping attr/class separately.
  end

  defp transform_css_modern(css, upper_bound_selector, lower_bound_selector) do
    "@scope (#{upper_bound_selector}) to (#{lower_bound_selector}) { #{css} }"
  end

  defp transform_css_legacy_compat(css, upper_bound_selector, lower_bound_selector) do
    # For top-level child element selectors in CSS, add :not(...) rules for descoping:
    css =
      css
      |> String.replace(
        ~r/^  ([^ ]|[^ ].*[^ ]) * {/m,
        "  \\1:not(#{lower_bound_selector}\\1):not(#{lower_bound_selector} \\1) {"
      )

    # Note: Base CSS indentation is 2-spaces, so top-level child element selectors
    #       can be identified via regex above by start-of-line followed immediately
    #       by two spaces ("^  " at start of regex). Multiline mode is needed to
    #       match against all lines in string (/m at end of regex).

    # Wrap all CSS within main scoping selector:
    "#{upper_bound_selector} { #{css} }"
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
