# lib/judgejudy/knowledge_base.ex
defmodule Judgejudy.KnowledgeBase do
  alias Judgejudy.{Repo, KnowledgeBase.Embeddings}

  # RRF constant — 60 is the standard default
  @rrf_k 60
  # candidates from full-text before reranking
  @fts_limit 20
  # candidates from vector before reranking
  @vec_limit 20

  @doc """
  Hybrid search combining BM25 full-text and pgvector semantic search,
  fused with Reciprocal Rank Fusion.

  Options:
    - limit: number of results (default 3)
    - intent: filter by intent atom (optional)
  """
  def search(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 3)
    intent = Keyword.get(opts, :intent)

    with {:ok, embedding} <- Embeddings.embed(query) do
      results = hybrid_query(query, embedding, intent, limit)
      {:ok, results}
    end
  end

  @doc "Intent-scoped lookup with hybrid search fallback"
  def lookup(intent, opts \\ []) when is_atom(intent) do
    limit = Keyword.get(opts, :limit, 3)
    query = intent_to_query(intent)

    case Embeddings.embed(query) do
      {:ok, embedding} ->
        articles = hybrid_query(query, embedding, Atom.to_string(intent), limit)
        {:ok, articles}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp hybrid_query(query_text, embedding, intent_filter, limit) do
    vec_literal = Pgvector.new(embedding)

    intent_clause =
      if intent_filter,
        do: "AND intent = '#{intent_filter}'",
        else: ""

    sql = """
    WITH fts AS (
      SELECT
        id,
        ts_rank_cd(search_vector, plainto_tsquery('english', $1)) AS score,
        ROW_NUMBER() OVER (
          ORDER BY ts_rank_cd(search_vector, plainto_tsquery('english', $1)) DESC
        ) AS rank
      FROM kb_articles
      WHERE search_vector @@ plainto_tsquery('english', $1)
      #{intent_clause}
      LIMIT #{@fts_limit}
    ),
    semantic AS (
      SELECT
        id,
        1 - (embedding <=> $2::vector) AS score,
        ROW_NUMBER() OVER (
          ORDER BY embedding <=> $2::vector
        ) AS rank
      FROM kb_articles
      WHERE embedding IS NOT NULL
      #{intent_clause}
      LIMIT #{@vec_limit}
    ),
    rrf AS (
      SELECT
        COALESCE(fts.id, semantic.id) AS id,
        COALESCE(1.0 / (#{@rrf_k} + fts.rank),     0) +
        COALESCE(1.0 / (#{@rrf_k} + semantic.rank), 0) AS rrf_score
      FROM fts
      FULL OUTER JOIN semantic ON fts.id = semantic.id
    )
    SELECT
      kb_articles.id,
      kb_articles.intent,
      kb_articles.title,
      kb_articles.body,
      kb_articles.keywords,
      rrf.rrf_score
    FROM rrf
    JOIN kb_articles ON kb_articles.id = rrf.id
    ORDER BY rrf.rrf_score DESC
    LIMIT #{limit}
    """

    case Repo.query(sql, [query_text, vec_literal]) do
      {:ok, %{rows: []}} ->
        []

      {:ok, %{rows: rows}} ->
        Enum.map(rows, fn [id, intent, title, body, keywords, score] ->
          %{
            id: id,
            intent: intent,
            title: title,
            body: body,
            keywords: keywords,
            rrf_score: score
          }
        end)

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Seed query terms for intent-based lookup
  defp intent_to_query(:billing), do: "invoice payment billing charge refund"
  defp intent_to_query(:support), do: "help support bug error troubleshoot"
  defp intent_to_query(:sales), do: "pricing plan demo trial enterprise"
  defp intent_to_query(:general), do: "general information help"
end
