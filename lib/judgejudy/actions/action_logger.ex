defmodule Judgejudy.Actions.ActionLogger do
  require Logger

  defmacro log_run(action_name, params, do: block) do
    quote do
      Logger.info("#{unquote(action_name)}: starting with params=#{inspect(unquote(params))}")

      result =
        try do
          unquote(block)
        rescue
          e ->
            Logger.error("""
            #{unquote(action_name)}: EXCEPTION
              message=#{Exception.message(e)}
              stacktrace=#{Exception.format_stacktrace(__STACKTRACE__)}
            """)

            {:error, Exception.message(e)}
        end

      case result do
        {:ok, val} ->
          Logger.info("#{unquote(action_name)}: success result=#{inspect(val)}")

        {:error, reason} ->
          Logger.error("#{unquote(action_name)}: FAILED reason=#{inspect(reason)}")
      end

      result
    end
  end
end
