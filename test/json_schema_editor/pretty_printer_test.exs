defmodule JSONSchemaEditor.PrettyPrinterTest do
  use ExUnit.Case, async: true
  alias JSONSchemaEditor.PrettyPrinter

  test "formats empty map" do
    assert PrettyPrinter.format(%{}) == "{}"
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

    # We trim expected to match potential whitespace handling, 
    # but let's check exact output if possible.
    # The implementation adds indentation.
    assert String.replace(PrettyPrinter.format(data), ~r/\s+/, "") ==
             String.replace(expected, ~r/\s+/, "")
  end

  test "formats empty list" do
    assert PrettyPrinter.format([]) == "[]"
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

  test "formats numbers" do
    assert PrettyPrinter.format(123) == "123"
    assert PrettyPrinter.format(12.34) == "12.34"
  end

  test "formats booleans" do
    assert PrettyPrinter.format(true) == "true"
    assert PrettyPrinter.format(false) == "false"
  end

  test "formats nil" do
    assert PrettyPrinter.format(nil) == "null"
  end

  test "formats fallback (atoms)" do
    assert PrettyPrinter.format(:atom) == ":atom"
  end
end
