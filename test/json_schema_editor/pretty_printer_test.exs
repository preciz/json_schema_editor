defmodule JSONSchemaEditor.PrettyPrinterTest do
  use ExUnit.Case, async: true
  alias JSONSchemaEditor.PrettyPrinter

  describe "format/1" do
    test "formats primitives and empty structures" do
      scenarios = [
        {%{}, "{}"},
        {[], "[]"},
        {123, "123"},
        {12.34, "12.34"},
        {true, "true"},
        {false, "false"},
        {nil, "null"},
        {:atom, ":atom"}
      ]

      for {input, expected} <- scenarios do
        assert PrettyPrinter.format(input) == expected
      end
    end

    test "formats simple map" do
      data = %{"a" => 1, "b" => "two"}

      expected =
        """
        {
          "a": 1,
          "b": "two"
        }
        """
        |> String.trim()

      assert String.replace(PrettyPrinter.format(data), ~r/\s+/, "") ==
               String.replace(expected, ~r/\s+/, "")
    end

    test "formats list of primitives" do
      data = [1, "two", true, nil]
      result = PrettyPrinter.format(data)
      assert result =~ "["
      assert result =~ "1"
      assert result =~ "\"two\""
      assert result =~ "true"
      assert result =~ "null"
      assert result =~ "]"
    end

    test "formats nested structures" do
      data = %{
        "list" => [
          %{"nested" => true}
        ]
      }

      result = PrettyPrinter.format(data)
      assert result =~ "\"list\": ["
      assert result =~ "\"nested\": true"
    end
  end
end
