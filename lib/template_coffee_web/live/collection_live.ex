defmodule TemplateCoffeeWeb.CollectionLive do
  use TemplateCoffeeWeb, :live_view

  def render(assigns) do
    temple do
      div class: ~u"hello-world" do
        c &Layouts.app/1, flash: @flash do
          "Welcome to the collection!"
        end
      end
    end
  end
end
