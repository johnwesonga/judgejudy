# lib/judgejudy/knowledge_base/embeddings.ex
defmodule Judgejudy.KnowledgeBase.Embeddings do
  # Anthropic's embedding model via req_llm
  # or "text-embedding-3-small" for OpenAI
  @default_base_url "http://localhost:1234/v1"
  @default_model "nomic-embed-text"
  @default_api_key "lm-studio"

  @doc "Embed a single string, returns {:ok, [float]} or {:error, reason}"
  def embed(text) when is_binary(text) do
    config = Application.get_env(:judgejudy, :embeddings, [])
    base_url = Keyword.get(config, :base_url, @default_base_url)
    model = Keyword.get(config, :model, @default_model)
    api_key = Keyword.get(config, :api_key, @default_api_key)
    url = "#{base_url}/embeddings"

    body =
      Jason.encode!(%{
        model: model,
        input: text
      })

    case Req.post(url,
           body: body,
           headers: [
             {"content-type", "application/json"},
             {"authorization", "Bearer #{api_key}"}
           ],
           receive_timeout: 30_000
         ) do
      {:ok, %{status: 200, body: %{"data" => [%{"embedding" => vec}]}}} ->
        {:ok, vec}

      {:ok, %{status: status, body: body}} ->
        {:error, "Embedding API error #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Embed multiple strings in one call, returns {:ok, [[float]]} or {:error, reason}"
  def embed_batch(texts) when is_list(texts) do
    config = Application.get_env(:judgejudy, :embeddings, [])
    base_url = Keyword.get(config, :base_url, @default_base_url)
    model = Keyword.get(config, :model, @default_model)
    api_key = Keyword.get(config, :api_key, @default_api_key)
    url = "#{base_url}/embeddings"

    body =
      Jason.encode!(%{
        model: model,
        input: texts
      })

    case Req.post(url,
           body: body,
           headers: [
             {"content-type", "application/json"},
             {"authorization", "Bearer #{api_key}"}
           ],
           receive_timeout: 30_000
         ) do
      {:ok, %{status: 200, body: %{"data" => data}}} ->
        vecs = data |> Enum.sort_by(& &1["index"]) |> Enum.map(& &1["embedding"])
        {:ok, vecs}

      {:ok, %{status: status, body: body}} ->
        {:error, "Embedding API error #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
