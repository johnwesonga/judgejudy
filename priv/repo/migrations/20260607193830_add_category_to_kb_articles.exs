defmodule Judgejudy.Repo.Migrations.AddCategoryToKbArticles do
  use Ecto.Migration

  def change do
    alter table(:kb_articles) do
      add :category, :string, default: "general"
    end

    create index(:kb_articles, [:intent, :category])
  end
end
