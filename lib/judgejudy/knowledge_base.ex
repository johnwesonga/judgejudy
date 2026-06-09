defmodule Judgejudy.KnowledgeBase do
  alias Judgejudy.{Repo, KnowledgeBase.Embeddings}
  require Logger

  @rrf_k 60
  @fts_limit 20
  @vec_limit 20

  # Boost weights — tune these to taste
  # adds 30% to RRF score for matching intent
  @intent_boost 0.3
  # adds 50% to RRF score for matching category
  @category_boost 0.5

  def search(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 3)
    intent = Keyword.get(opts, :intent)
    category = Keyword.get(opts, :category)

    with {:ok, embedding} <- Embeddings.embed(query) do
      results = hybrid_query(query, embedding, intent, category, limit)
      {:ok, results}
    end
  end

  def lookup(intent, opts \\ []) when is_atom(intent) do
    limit = Keyword.get(opts, :limit, 3)
    category = Keyword.get(opts, :category)
    query = intent_to_query(intent, category)

    case Embeddings.embed(query) do
      {:ok, embedding} ->
        case hybrid_query(query, embedding, Atom.to_string(intent), category, limit) do
          # already wrapped
          {:ok, results} ->
            {:ok, results}

          {:error, reason} ->
            {:error, reason}

          # bare list — wrap it
          results when is_list(results) ->
            {:ok, results}
        end

      {:error, reason} ->
        Logger.error("KnowledgeBase: embedding failed: #{inspect(reason)}")
        {:error, :embedding_failed}
    end
  end

  defp hybrid_query(query_text, embedding, intent, category, limit) do
    vec_literal = Pgvector.new(embedding)

    intent_boost_sql =
      if intent,
        do: "CASE WHEN kb_articles.intent = '#{intent}' THEN #{@intent_boost} ELSE 0 END",
        else: "0"

    category_boost_sql =
      if category,
        do: "CASE WHEN kb_articles.category = '#{category}' THEN #{@category_boost} ELSE 0 END",
        else: "0"

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
      LIMIT #{@vec_limit}
    ),
    rrf AS (
      SELECT
        COALESCE(fts.id, semantic.id) AS id,
        COALESCE(1.0 / (#{@rrf_k} + fts.rank),     0) +
        COALESCE(1.5 / (#{@rrf_k} + semantic.rank), 0) AS rrf_score,
        COALESCE(fts.score,     0) AS fts_score,
        COALESCE(semantic.score, 0) AS semantic_score
      FROM fts
      FULL OUTER JOIN semantic ON fts.id = semantic.id
    )
    SELECT
      kb_articles.id,
      kb_articles.intent,
      kb_articles.category,
      kb_articles.title,
      kb_articles.body,
      kb_articles.keywords,
      rrf.rrf_score,
      rrf.fts_score,
      rrf.semantic_score,
      rrf.rrf_score + #{intent_boost_sql} + #{category_boost_sql} AS final_score
    FROM rrf
    JOIN kb_articles ON kb_articles.id = rrf.id
    ORDER BY final_score DESC
    LIMIT #{limit}
    """

    case Repo.query(sql, [query_text, vec_literal]) do
      {:ok, %{rows: []}} ->
        {:ok, []}

      {:ok, %{rows: rows}} ->
        # Normalize final_score across results into a 0-1 retrieval confidence
        raw =
          Enum.map(rows, fn [
                              id,
                              intent,
                              category,
                              title,
                              body,
                              keywords,
                              rrf_score,
                              fts_score,
                              semantic_score,
                              final_score
                            ] ->
            %{
              id: id,
              intent: intent,
              category: category,
              title: title,
              body: body,
              keywords: keywords,
              rrf_score: to_float(rrf_score),
              fts_score: to_float(fts_score),
              semantic_score: to_float(semantic_score),
              final_score: to_float(final_score)
            }
          end)

        max_score = raw |> Enum.map(& &1.final_score) |> Enum.max(fn -> 1.0 end)

        results =
          Enum.map(raw, fn article ->
            retrieval_confidence =
              if max_score > 0.0,
                do: Float.round(article.final_score / max_score, 2),
                else: 0.0

            Map.put(article, :retrieval_confidence, retrieval_confidence)
          end)

        {:ok, results}

      {:error, %Postgrex.Error{} = e} ->
        Logger.error("KnowledgeBase: query failed: #{inspect(e)}")
        {:error, :retrieval_failed}
    end
  rescue
    e ->
      Logger.error("KnowledgeBase: unexpected error: #{Exception.message(e)}")
      {:error, :retrieval_failed}
  end

  defp to_float(%Decimal{} = d), do: Decimal.to_float(d)
  defp to_float(f) when is_float(f), do: f
  defp to_float(i) when is_integer(i), do: i / 1.0
  defp to_float(nil), do: 0.0

  defp intent_to_query("billing", nil), do: "invoice payment billing charge refund"
  defp intent_to_query("billing", category), do: "billing #{category} invoice payment"
  defp intent_to_query("support", nil), do: "help support bug error troubleshoot"
  defp intent_to_query("support", category), do: "support #{category} help error"
  defp intent_to_query("sales", nil), do: "pricing plan demo trial enterprise"
  defp intent_to_query("sales", category), do: "sales #{category} pricing plan"
  defp intent_to_query("general", _), do: "general information help"
  defp intent_to_query(_, _), do: "help information"

  # Atom version for backward compat
  # defp intent_to_query(intent, category) when is_atom(intent),
  # do: intent_to_query(Atom.to_string(intent), category)
end
