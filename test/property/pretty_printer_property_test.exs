defmodule JSONSchemaEditor.PrettyPrinterPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias JSONSchemaEditor.PrettyPrinter

  # Generator for JSON-compatible data
  def json_data do
    tree(simple_json_data(), fn complex ->
      one_of([
        list_of(complex, min_length: 1, max_length: 5),
        map_of(string(:alphanumeric, min_length: 1, max_length: 10), complex,
          min_length: 1,
          max_length: 5
        )
      ])
    end)
  end

  def simple_json_data do
    one_of([
      string(:alphanumeric, min_length: 1, max_length: 10),
      integer(),
      float(),
      boolean(),
      constant(nil)
    ])
  end

  property "format/1 never crashes on valid JSON data" do
    check all(data <- json_data()) do
      html = PrettyPrinter.format(data)
      assert {:safe, content} = html
      assert is_binary(content)
    end
  end

  property "format/1 output contains all leaf strings" do
    check all(
            data <-
              map_of(
                string(:alphanumeric, min_length: 1, max_length: 10),
                string(:alphanumeric, min_length: 1, max_length: 10),
                min_length: 1,
                max_length: 10
              )
          ) do
      {:safe, html_content} = PrettyPrinter.format(data)

      Enum.each(data, fn {k, v} ->
        # Since we use alphanumeric strings, they should appear as-is (or quoted)
        assert String.contains?(html_content, k), "Output should contain key #{k}"
        assert String.contains?(html_content, v), "Output should contain value #{v}"
      end)
    end
  end
end
