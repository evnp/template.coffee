defmodule TemplateCoffeeWeb.PageController do
  use TemplateCoffeeWeb, :controller

  def static_view(conn, _params) do
    render(conn, :static_view)
  end
end
