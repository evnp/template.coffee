defmodule TemplateCoffeeWeb.PageController do
  use TemplateCoffeeWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
