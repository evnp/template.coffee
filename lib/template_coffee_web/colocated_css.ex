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

  @select :class
  # :class - use CSS classes for scoping
  # :attr  - use CSS attributes for scoping
  # :both  - allow use of CSS classes and attributes in tandem for scoping
  @compat :hybrid
  # :modern - use @scope in CSS for scoping
  # :legacy - use basic CSS selectors for scoping that should work in all browsers
  # :hybrid - use @scope in CSS for scoping plus fallback styles for legacy browsers

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
    descope_str(env)
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

  defp scope_class(scope_str), do: ~s|.#{scope_str}|
  defp scope_attr(scope_str), do: ~s|[data-scope="scope-css #{scope_str}"]|
  defp descope_class(descope_str), do: ~s|.#{descope_str}|
  defp descope_attr(descope_str), do: ~s|[data-descope="#{descope_str}"]|
  defp descope_class_auto(scope_str), do: ~s|.scope-css:not(.#{scope_str})|

  defp descope_attr_auto(scope_str) do
    ~s|[data-scope]:not([data-scope="scope-css #{scope_str}"])|
  end

  @impl true
  def transform("style", _attrs, css, meta) do
    scope_str = scope_str(meta)
    descope_str = descope_str(meta)

    # Specify attr-based and class-based selectors in upper_bound_selector:
    # (either can be used, depending on what's most convenient in the template)
    upper_bound_selector =
      case @select do
        :class -> scope_class(scope_str)
        :attr -> scope_attr(scope_str)
        :both -> ":is(#{scope_class(scope_str)}, #{scope_attr(scope_str)})"
        _ -> raise(RuntimeError, "@select must be :class, :attr, or :both")
      end

    # First two lines in lower_bound_selector mirror upper_bound_selector;
    # they select a descope attr or descope CSS class respectively.
    lower_bound_selector =
      case @select do
        :class ->
          ":is(#{descope_class(descope_str)}, #{descope_class_auto(scope_str)})"

        :attr ->
          ":is(#{descope_attr(descope_str)}, #{descope_attr_auto(scope_str)})"

        :both ->
          ":is(#{descope_class(descope_str)}, #{descope_class_auto(scope_str)}," <>
            " #{descope_attr(descope_str)}, #{descope_attr_auto(scope_str)})"

        _ ->
          raise(RuntimeError, "@select must be :class, :attr, or :both")
      end

    css =
      case @compat do
        :modern ->
          scope_css_modern(css, upper_bound_selector, lower_bound_selector)

        :legacy ->
          scope_css_legacy_compat(css, upper_bound_selector, lower_bound_selector)

        :hybrid ->
          scope_css_hybrid_compat(css, upper_bound_selector, lower_bound_selector)

        _ ->
          raise(RuntimeError, "@compat must be :modern, :legacy, or :hybrid")
      end

    {:ok, css, []}
    # We don't need to return a :tag_attribute here as you normally would, because
    # when using CSS-scoping w/ Temple we'll apply the scoping attr/class separately.
  end

  defp scope_css_modern(css, upper_bound_selector, lower_bound_selector) do
    "@scope (#{upper_bound_selector}) to (#{lower_bound_selector}) { #{css} }"
  end

  defp scope_css_hybrid_compat(css, upper_bound_selector, lower_bound_selector) do
    """
    #{scope_css_modern(css, upper_bound_selector, lower_bound_selector)}
    .no-css-scope-at-rule-support {
      #{scope_css_legacy_compat(css, upper_bound_selector, lower_bound_selector)}
    }
    """
  end

  defp scope_css_legacy_compat(css, upper_bound_selector, lower_bound_selector) do
    # For top-level child element selectors in CSS, add :not(...) rules for descoping:
    css =
      css
      |> String.replace(
        ~r/^  ([^ ]|[^ ].*[^ ]) * {/m,
        "  :is(\\1):not(#{lower_bound_selector}:is(\\1)):not(#{lower_bound_selector} :is(\\1)) {"
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
