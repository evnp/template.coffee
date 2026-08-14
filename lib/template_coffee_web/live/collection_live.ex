defmodule TemplateCoffeeWeb.CollectionLive do
  use TemplateCoffeeWeb, :live_view

  def render(assigns) do
    temple do
      c &Layouts.app/1, flash: @flash do
        ~H"""
        <script :type={ColocatedJS}>
          alert("hello from colocated js");
        </script>
        """

        div class:
              ~u"bg-sky-200
              #{ColocatedScopedCSS.scope(__ENV__, ~H"""
              <style :type={ColocatedScopedCSS}>
                width: 100vw;
                height: 100vh;
                display: flex;
                justify-content: center;
                align-items: center;

                .blue {
                  color: blue;
                  width: stretch;
                  margin: 32vw;

                  &::placeholder {
                    color: green;
                  }
                }
              </style>
              """)}",
            "phx-hook": temple_phx_hook(__MODULE__, "testHook"),
            id: "hooks-need-ids"
        do
          input class: "blue",
                value: "Welcome to the blue collection.",
                placeholder: "The collection appears to be empty."

          i class: "hero-arrow-right-circle"

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
end
