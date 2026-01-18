defmodule Playwright.SDK.Helpers.ErrorHandling do
  @moduledoc false
  alias Playwright.SDK.Channel.Error

  def with_timeout(options, action) when is_map(options) and is_function(action) do
    timeout = options |> Map.get(:timeout, 30_000) |> to_integer()

    try do
      # In most cases (as of 20240802), the timeout value provided here is also
      # used as a timeout option passed to the Playwright server. As such, there
      # is/was a race condition in which the `action` provided here would often
      # time out before a response from the server indicated it's own timeout.
      # To mitigate this, we add an additional 100ms to the timeout value to give
      # the browser server a chance to timeout before the awaiting process times out.
      action.(timeout + 100)
    catch
      :exit, {:timeout, _} = _reason ->
        {:error, Error.new(%{error: %{message: "Timeout #{inspect(timeout)}ms exceeded."}}, nil)}
    end
  end

  defp to_integer(value) when is_float(value), do: trunc(value)
  defp to_integer(value) when is_integer(value), do: value
end
