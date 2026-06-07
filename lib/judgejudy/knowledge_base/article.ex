# lib/judgejudy/knowledge_base/article.ex
defmodule Judgejudy.KnowledgeBase.Article do
  use Ecto.Schema
  import Ecto.Changeset

  schema "kb_articles" do
    field(:intent, :string)
    field(:category, :string, default: "general")
    field(:title, :string)
    field(:body, :string)
    field(:keywords, {:array, :string}, default: [])
    field(:confidence, :float, default: 1.0)
    field(:embedding, Pgvector.Ecto.Vector)
    timestamps()
  end

  def changeset(article, attrs) do
    article
    |> cast(attrs, [:intent, :category, :title, :body, :keywords, :confidence, :embedding])
    |> validate_required([:intent, :title, :body])
    |> validate_inclusion(:intent, ~w(billing support sales general))
  end
end
