defmodule Judgejudy.KnowledgeBase.Fallbacks do
  @fallbacks %{
    "billing" => """
    For billing questions, please visit your account's billing portal at
    Settings → Billing, or contact billing@myapp.com directly.
    Our billing team is available Monday–Friday, 9am–5pm EST.
    """,
    "support" => """
    For technical support, please visit our documentation at docs.myapp.com
    or email support@myapp.com. For urgent issues, use the priority support
    form at myapp.com/support/urgent.
    """,
    "sales" => """
    For pricing and plan information, visit myapp.com/pricing.
    To speak with our sales team, book a call at myapp.com/demo.
    """,
    "general" => """
    Thank you for reaching out. For general inquiries, visit our help
    centre at help.myapp.com or email hello@myapp.com.
    """
  }

  def get(intent) when is_binary(intent) do
    Map.get(@fallbacks, intent, Map.get(@fallbacks, "general"))
  end

  def get(intent) when is_atom(intent), do: get(Atom.to_string(intent))
end
