# lib/judgejudy/postgres_types.ex
Postgrex.Types.define(
  Judgejudy.PostgresTypes,
  [Pgvector.Extensions.Vector],
  []
)
