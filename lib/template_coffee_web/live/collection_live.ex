defmodule TemplateCoffeeWeb.CollectionLive do
  use TemplateCoffeeWeb, :live_view

  # Ensure scoped CSS within its own function works:
  # (`assigns` must be passed as param; required for ~H"..." HEEX sigil to work)
  def container_css(assigns), do: scope_css ~H"""
    width: 100vw;
    height: 100vh;
    display: flex;
    justify-content: center;
    align-items: center;
  """

  def render(assigns) do
    container_css_scope = container_css(assigns)

    # Ensure scoped CSS defined directly within render function works:
    # (`assigns` is already in scope, which allows ~H"..." HEEX sigil to work)
    css_scope = scope_css ~H"""
      .blue {
        color: blue;
        width: 20vw;

        &::placeholder {
          color: green;
        }
      }

      @media screen {
        /* ensure that styles nested in media queries work */
        .red {
          color: red;
        }
      }

      /* ensure that ::before/::after psuedo-elements work */
      .psuedo-element-parent::before {
        display: block;
        content: "(socket ID from @assigns via CSS var in ::before psuedo-element: "
          var(--socket-id-via-css-var) ")";
      }
      .psuedo-element-parent::after {
        display: block;
        content: "(socket ID from @assigns via data attr in ::after psuedo-element: "
          attr(data-socketid) ")";
      }
    """

    temple do
      c &Layouts.app/1, flash: @flash do
        ~H"""
        <script :type={ColocatedJS}>
          alert("hello from colocated js");
        </script>
        """

        div class: ~u"bg-sky-200 #{css_scope} #{container_css_scope}",
            style: css_vars_to_style(socket_id_via_css_var: @socket.id),
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

              div "data-descope": descope_css() do
                p class: "red", do: "this should not be red, if using attr CSS scoping"
              end

              div class: descope_css() do
                p class: "red", do: "this should not be red, if using class CSS scoping"
              end

              c &sub_component/1, socket: @socket do
                p class: "red #{css_scope} psuedo-element-parent",
                  "data-socketid": @socket.id
                do
                  "slot content defined in the parent's template should be red though"
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
    # Below - Ensure scoped CSS defined inline within Temple element class works:
    # (`assigns` is already in scope, which allows ~H"..." HEEX sigil to work)
    temple do
      div class: scope_css ~H"background: rgba(50, 50, 50, 0.1);" do
        p do: "Hello, I'm a sub-component!"

        div class: "ml-8" do
          p class: "red" do
            "this should not be red, due to separate sub-component CSS scope"
          end

          div class: descope_css() do
            slot @inner_block
          end
        end

        p do: "Goodbye, from sub-component."
      end
    end
  end
end
