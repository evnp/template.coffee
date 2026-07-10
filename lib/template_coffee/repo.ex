defmodule TemplateCoffee.Repo do
  use Ecto.Repo,
    otp_app: :template_coffee,
    adapter: Ecto.Adapters.Postgres
end
