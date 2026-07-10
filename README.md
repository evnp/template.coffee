# TemplateCoffee

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://phoenix.hexdocs.pm/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://phoenix.hexdocs.pm/overview.html
* Docs: https://phoenix.hexdocs.pm
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix

## Notes on project setup

This project uses various libraries for code "quality-of-life" and readability:
- [Temple](https://temple.hexdocs.pm): An HTML templating DSL used for most custom template code instead of HEEx.
  - *though Temple interoperates seamlessly with HEEx; both are in use in this project.
- [ES6 Maps](https://es6-maps.hexdocs.pm): A compiler macro which reduces key/value duplication in maps.
- [Unique-Words Sigil](https://unique-words-sigil.hexdocs.pm): A convenience sigil used for ergonomics of HTML class lists.
- [Regex Formatter](https://regex-formatter.hexdocs.pm): Mix format plugin which applies custom rules to enhance readability.
  - maintain trailing commas where possible within lists, maps, and tuples
  - strip extraneous surrounding whitespace from ~u sigil values
  - compact extraneous internal whitespace within ~u sigil values
  - put "do" keyword on its own line where function/macro signatures are multi-line
    - this primarily improves readability within Temple HTML template code

### [Temple](https://temple.hexdocs.pm)

An HTML templating DSL used for most custom template code instead of HEEx.
(though Temple interoperates seamlessly with HEEx; both are in use in this project)

All Temple HTML-template code must reside within `temple do ... end` blocks.

Basic example of HTML with a built-in Phoenix/HEEx component with slot in use:

```elixir
defmodule TemplateCoffeeWeb.HelloWorldLive do
  use TemplateCoffeeWeb, :live_view

  def render(assigns) do
    temple do
      div class: ~u"hello-world" do
        c &Layouts.app/1, flash: @flash do
          "Hello world!"
        end
      end
    end
  end
end
```
The `&Layouts.app/1` component is defined in `lib/template_coffee_web/components/layouts.ex`.

Integration points:

```elixir
### mix.exs ###
  def project do
    [
      ...
      compilers: [:temple, :es6_maps, :phoenix_live_view] ++ Mix.compilers(),
      ...
    ]
  end
```

```elixir
### config/config.exs ###
# Configure Temple (templating DSL) to output data in Phoenix LiveView HEEx format:
# See https://github.com/mhanberg/temple/issues/201
# and resulting https://github.com/georgevanderson/temple_liveview/pull/1
config :temple, engine: Phoenix.LiveView.Engine
```

```elixir
### lib/template_coffee_web.exs ###
defp html_helpers do
  quote do
    ...
    # Configure Temple (templating DSL):
    # See https://github.com/mhanberg/temple/issues/201
    # and resulting https://github.com/georgevanderson/temple_liveview/pull/1
    import Temple
    import Phoenix.LiveView.TagEngine, only: [component: 3, inner_block: 2]
  end
end
```

### [ES6 Maps](https://es6-maps.hexdocs.pm)

A compiler macro which reduces key/value duplication in maps.

Integration points:

```elixir
# mix.exs
  def project do
    [
      ...
      compilers: [:temple, :es6_maps, :phoenix_live_view] ++ Mix.compilers(),
      ...
    ]
  end
```

### [Unique-Words Sigil](https://unique-words-sigil.hexdocs.pm)

A convenience sigil used for ergonomics of HTML class lists.

Integration points:

```elixir
### lib/template_coffee_web.exs ###
  defp html_helpers do
    quote do
      ...
      # ~u "unique words" sigil for HTML element classes
      import UniqueWordsSigil
      ...
    end
  end
```

### [Regex Formatter](https://regex-formatter.hexdocs.pm)

Mix format plugin which applies custom rules to enhance readability:
  - maintain trailing commas where possible within lists, maps, and tuples
  - strip extraneous surrounding whitespace from ~u sigil values
  - compact extraneous internal whitespace within ~u sigil values
  - put "do" keyword on its own line where function/macro signatures are multi-line
    - this primarily improves readability within Temple HTML template code

Integration points: `.formatter.exs`

