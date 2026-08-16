defmodule TemplateCoffeeWeb.ColocatedGlobalCSS do
  use Phoenix.LiveView.ColocatedCSS

  @impl true
  def transform("style", _attrs, css, _meta) do
    {:ok, css, []}
  end
end

# Scoped-Colocated-CSS implementation that works with Temple, adapted from:
# phoenix-live-view.hexdocs.pm/Phoenix.LiveView.ColocatedCSS.html#module-scoped-css
defmodule TemplateCoffeeWeb.ColocatedScopedCSS do
  use Phoenix.LiveView.ColocatedCSS

  @legacy_browser_compat true

  def scope(env, _style_heex \\ "") do
    "scope-css #{scope_str(env)}"
    # Note: Extra scope-css prefix is added when scoping for two reasons -
    #       - It adds clarity in resulting HTML when a CSS scope occurs.
    #       - It makes it easy and _performant_ to select any scope-starting element.
    #       This second aspect is important for automatic-descoping of sub-components,
    #       where it becomes necessary to use any scoping attr/class that does NOT
    #       match the parent scope as a marker to automatically de-scope.
    # Note: Unused _style_heex param allows specifying <style> HEEx template
    #       on the same line as the CSS data-scope or class is set, eg.
    #         data-scope={ColocatedScopedCSS.scope(__ENV__, ~H"""...""")}
    #         OR
    #         class="my-elm #{ColocatedScopedCSS.scope(__ENV__, ~H"""...""")}"
    #       This helps ensure that __ENV__.line (from scoped element) and meta.line
    #       (from colocated-CSS system) will match when scope hash is computed above.
  end

  def descope(env) do
    "descope-css #{descope_str(env)}"
    # Note: Extra descope-css prefix is added when scoping for two reasons -
    #       - It adds clarity in resulting HTML when a CSS descope occurs.
    #       - It keeps code and HTML consistent between scoping and descoping.
    #       We don't currently need to select directly on descope-css, like we do
    #       on scope-css (for automatic sub-component descoping).
  end

  defp scope_str(env) do
    "scope-#{hash("#{env.module}-#{env.line}")}"
    # Note: "scope-" prefix is needed because hash will sometimes start with 0..9
    #       instead of A-Z, won't work as CSS class string (can't start with number).
  end

  defp descope_str(env) do
    "descope-#{hash("#{env.module}")}"
    # Note: Descoping operates on a module basis -- no line numbers.
    #       This allows descope attrs on different lines from the parent scope attr
    #       to still connect to generated scope CSS even though line is different.
  end

  @impl true
  def transform("style", _attrs, css, meta) do
    scope_str = scope_str(meta)
    descope_str = descope_str(meta)

    # Specify attr-based and class-based selectors in upper_bound_selector:
    # (either can be used, depending on what's most convenient in the template)
    upper_bound_selector =
      ":is(" <>
        ([
           ~s|[data-scope="scope-css #{scope_str}"]|,
           ~s|.#{scope_str}|,
         ]
         |> Enum.join(", ")) <> ")"

    # First two lines in lower_bound_selector mirror upper_bound_selector;
    # they select a descope attr or descope CSS class respectively.
    lower_bound_selector =
      ":is(" <>
        ([
           # Specify attr-based and class-based selectors in lower_bound_selector:
           # (either can be used, depending on what's most convenient in the template)
           ~s|[data-descope="descope-css #{descope_str}"]|,
           ~s|.#{descope_str}|,
           # Remaining two lines are here to provide *automatic descoping*, when a
           # sub-component opens a new CSS scope within a parent's CSS scope. Styles
           # scoped to the parent should not be applied within the sub-component, so
           # these two selectors match elements WITH scope that is NOT the parent's:
           ~s|[data-scope]:not([data-scope="scope-css #{scope_str}"])|,
           ~s|.scope-css:not(.#{scope_str})|,
         ]
         |> Enum.join(", ")) <> ")"

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
