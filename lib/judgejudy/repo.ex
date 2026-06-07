defmodule Judgejudy.Repo do
  use Ecto.Repo,
    otp_app: :judgejudy,
    adapter: Ecto.Adapters.Postgres
end
