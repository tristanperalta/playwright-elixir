defmodule Playwright.SDK.Channel.MessageTest do
  use ExUnit.Case, async: true
  alias Playwright.SDK.Channel.Message

  describe "new/3" do
    test "returns a Message struct" do
      assert Message.new("guid", "click") |> is_struct(Message)
    end

    test "returns a Message struct with a monotonically-incrementing ID" do
      one = Message.new("element-handle", "click")
      two = Message.new("element-handle", "click")

      assert one |> is_struct(Message)
      assert two |> is_struct(Message)

      assert two.id > one.id
    end

    test "accepts optional params" do
      is_default = Message.new("guid", "method")
      has_params = Message.new("guid", "method", %{key: "value"})

      # Default params include timeout (required as of Playwright 1.57+)
      assert is_default.params == %{"timeout" => 30_000}
      assert has_params.params == %{"key" => "value", "timeout" => 30_000}
    end
  end
end
