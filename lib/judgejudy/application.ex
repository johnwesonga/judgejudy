defmodule Judgejudy.Application do
  use Application

  def start(_type, _args) do
    children = [
      # <-- add before Jido
      Judgejudy.Repo,
      {Registry, keys: :unique, name: Jido.Registry},
      Judgejudy.Jido,
      {Jido.Signal.Bus, name: :app_bus},
      {Yugo.Client,
       name: :inbox,
       server: Application.fetch_env!(:judgejudy, :imap_server),
       username: Application.fetch_env!(:judgejudy, :imap_username),
       password: Application.fetch_env!(:judgejudy, :imap_password),
       tls: true,
       mailbox: "INBOX"},
      Judgejudy.Sensors.EmailSensor
    ]

    opts = [strategy: :one_for_one, name: Judgejudy.Supervisor]

    with {:ok, sup} <- Supervisor.start_link(children, opts),
         {:ok, _pid} <-
           Judgejudy.Jido.start_agent(
             Judgejudy.Agents.EmailReActAgent,
             id: "email-agent-1"
           ) do
      {:ok, sup}
    end
  end
end
