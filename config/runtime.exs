import Config

config :req_llm,
  anthropic_api_key: System.get_env("ANTHROPIC_API_KEY"),
  openai_api_key: System.get_env("OPENAI_API_KEY")

config :judgejudy,
  # "imap.gmail.com"
  imap_server: System.fetch_env!("IMAP_SERVER"),
  # "you@gmail.com"
  imap_username: System.fetch_env!("IMAP_USERNAME"),
  # Google App Password
  imap_password: System.fetch_env!("IMAP_PASSWORD")

config :judgejudy, Judgejudy.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: "smtp.gmail.com",
  port: 587,
  username: System.fetch_env!("SMTP_USERNAME"),
  password: System.fetch_env!("SMTP_PASSWORD"),
  tls: :if_available,
  auth: :always,
  ssl: false,
  tls_options: [
    # start here; tighten to :verify_peer in prod
    verify: :verify_none,
    versions: [:"tlsv1.2", :"tlsv1.3"]
  ]

config :jido_ai, :react_token_secret, System.fetch_env!("REACT_TOKEN_SECRET")

config :judgejudy, Judgejudy.Repo,
  url: System.fetch_env!("DATABASE_URL"),
  pool_size: 10,
  types: Judgejudy.PostgresTypes

config :judgejudy, :embeddings,
  base_url: System.get_env("EMBEDDINGS_BASE_URL", "http://localhost:8000/v1"),
  api_key: System.get_env("EMBEDDINGS_API_KEY", "omlx"),
  model: System.get_env("EMBEDDINGS_MODEL", "bge-m3-mlx-4bit")
