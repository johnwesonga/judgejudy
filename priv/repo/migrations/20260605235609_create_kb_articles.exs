# priv/repo/migrations/TIMESTAMP_create_kb_articles.exs
defmodule Judgejudy.Repo.Migrations.CreateKbArticles do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS vector"
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm"  # for fuzzy text matching

    create table(:kb_articles) do
      add :intent,     :string,  null: false
      add :title,      :string,  null: false
      add :body,       :text,    null: false
      add :keywords,   {:array, :string}, default: []
      add :confidence, :float,   default: 1.0
      add :embedding,  :vector,  size: 1536  # OpenAI/Anthropic embedding size
      timestamps()
    end

    # Full-text search index — generated column from title + body
    execute """
    ALTER TABLE kb_articles
    ADD COLUMN search_vector tsvector
    GENERATED ALWAYS AS (
      setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
      setweight(to_tsvector('english', coalesce(body, '')), 'B')
    ) STORED
    """

    execute "CREATE INDEX kb_articles_search_idx ON kb_articles USING GIN(search_vector)"

    # pgvector index for ANN (approximate nearest neighbour)
    execute """
    CREATE INDEX kb_articles_embedding_idx ON kb_articles
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64)
    """

    create index(:kb_articles, [:intent])
  end

  def down do
    drop table(:kb_articles)
  end
end
