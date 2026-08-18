defmodule TemplateCoffeeWeb.CollectionLive do
  use TemplateCoffeeWeb, :live_view

  def render(assigns) do
    css_scope =
      ColocatedScopedCSS.scope(__ENV__, ~H"""
      <style :type={ColocatedScopedCSS}>
        .blue {
          color: blue;
          width: 20vw;

          &::placeholder {
            color: green;
          }
        }

        .red {
          color: red;
        }
      </style>
      """)

    temple do
      c &Layouts.app/1, flash: @flash do
        ~H"""
        <script :type={ColocatedJS}>
          alert("hello from colocated js");
        </script>
        """

        div class:
              ~u"bg-sky-200 #{css_scope} #{ColocatedScopedCSS.scope(__ENV__, ~H"""
              <style :type={ColocatedScopedCSS}>
                width: 100vw;
                height: 100vh;
                display: flex;
                justify-content: center;
                align-items: center;
              </style>
              """)}",
            "phx-hook": temple_phx_hook(__MODULE__, "testHook"),
            id: "hooks-need-ids"
        do
          div do
            div class: "flex" do
              input class: "blue",
                    value: "Welcome to the blue collection.",
                    placeholder: "The collection appears to be empty."

              i class: "hero-arrow-right-circle"
            end

            div do
              div do
                p class: "red", do: "this should be red, per CSS scoping"
              end

              div "data-descope": ColocatedScopedCSS.descope(__ENV__) do
                p class: "red", do: "this should not be red, if using attr CSS scoping"
              end

              div class: ColocatedScopedCSS.descope(__ENV__) do
                p class: "red", do: "this should not be red, if using class CSS scoping"
              end

              c &sub_component/1 do
                div class: css_scope do
                  p class: "red" do
                    "slot content defined in the parent's template should be red though"
                  end
                end
              end
            end
          end

          ~H"""
          <script :type={ColocatedHook} name=".testHook">
            export default {
              mounted() {
                alert("hello from colocated hook");
              },
            };
          </script>
          """
        end
      end
    end
  end

  def sub_component(assigns) do
    temple do
      div class:
            ~u"#{ColocatedScopedCSS.scope(__ENV__, ~H"""
            <style :type={ColocatedScopedCSS}>
              background: rgba(50, 50, 50, 0.1);
            </style>
            """)}" do
        p do: "Hello, I'm a sub-component!"

        div class: "ml-8" do
          p class: "red" do
            "this should not be red, due to separate sub-component CSS scope"
          end

          div class: ColocatedScopedCSS.descope(__ENV__) do
            slot @inner_block
          end
        end

        p do: "Goodbye, from sub-component."
      end
    end
  end
end
