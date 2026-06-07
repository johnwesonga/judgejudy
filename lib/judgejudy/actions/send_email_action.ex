defmodule Judgejudy.Actions.SendEmailAction do
  use Jido.Action,
    name: "send_email",
    description: "Send the drafted reply to the original sender.",
    schema:
      Zoi.object(%{
        to: Zoi.string(),
        subject: Zoi.string(),
        body: Zoi.string()
      })

  @impl true
  def run(%{to: to, subject: subject, body: body}, _ctx) do
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.to(to)
      |> Swoosh.Email.from({"Support", "support@myapp.com"})
      |> Swoosh.Email.subject("Re: #{subject}")
      |> Swoosh.Email.text_body(body)

    case Judgejudy.Mailer.deliver(email) do
      {:ok, _} ->
        # Return a directive so the runtime emits a signal — keeps the action pure
        {:ok, %{sent: true},
         %Jido.Agent.Directive.Emit{
           signal: Jido.Signal.new!("email.replied", %{to: to}, source: "/email_agent")
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
