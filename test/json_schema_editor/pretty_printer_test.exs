defmodule JSONSchemaEditor.PrettyPrinterTest do
  use ExUnit.Case, async: true
  alias JSONSchemaEditor.PrettyPrinter

  defp unwrap(safe) do
    Phoenix.HTML.safe_to_string(safe)
  end

  defp q, do: "&quot;"

  describe "format/1" do
    test "formats primitives and empty structures" do
      scenarios = [
        {%{}, "<span class=\"jse-punctuation\">{}</span>"},
        {[], "<span class=\"jse-punctuation\">[]</span>"},
        {123, "<span class=\"jse-number\">123</span>"},
        {12.34, "<span class=\"jse-number\">12.34</span>"},
        {true, "<span class=\"jse-boolean\">true</span>"},
        {false, "<span class=\"jse-boolean\">false</span>"},
        {nil, "<span class=\"jse-null\">null</span>"},
        {:atom, "<span class=\"jse-string\">#{q()}:atom#{q()}</span>"}
      ]

      for {input, expected} <- scenarios do
        assert unwrap(PrettyPrinter.format(input)) == expected
      end
    end

    test "formats simple map" do
      data = %{"a" => 1, "b" => "two"}
      result = unwrap(PrettyPrinter.format(data))

      assert result =~ "<span class=\"jse-punctuation\">{</span>"
      assert result =~ "<span class=\"jse-key\">#{q()}a#{q()}</span>"
      assert result =~ "<span class=\"jse-punctuation\">:</span>"
      assert result =~ "<span class=\"jse-number\">1</span>"
      assert result =~ "<span class=\"jse-punctuation\">,</span>"
      assert result =~ "<span class=\"jse-key\">#{q()}b#{q()}</span>"
      assert result =~ "<span class=\"jse-string\">#{q()}two#{q()}</span>"
      assert result =~ "<span class=\"jse-punctuation\">}</span>"
    end

    test "formats list of primitives" do
      data = [1, "two", true, nil]
      result = unwrap(PrettyPrinter.format(data))

      assert result =~ "<span class=\"jse-punctuation\">[</span>"
      assert result =~ "<span class=\"jse-number\">1</span>"
      assert result =~ "<span class=\"jse-punctuation\">,</span>"
      assert result =~ "<span class=\"jse-string\">#{q()}two#{q()}</span>"
      assert result =~ "<span class=\"jse-boolean\">true</span>"
      assert result =~ "<span class=\"jse-null\">null</span>"
      assert result =~ "<span class=\"jse-punctuation\">]</span>"
    end

    test "formats nested structures" do
      data = %{
        "list" => [
          %{"nested" => true}
        ]
      }

      result = unwrap(PrettyPrinter.format(data))
      # keys
      assert result =~ "<span class=\"jse-key\">#{q()}list#{q()}</span>"
      assert result =~ "<span class=\"jse-key\">#{q()}nested#{q()}</span>"
      # values
      assert result =~ "<span class=\"jse-boolean\">true</span>"
    end

    test "handles invalid JSON string by treating it as a raw string" do
      input = "not json"
      # It enters format, fails decode, keeps "not json", then hits do_format(binary)
      # do_format(binary) wraps it in span.jse-string and encodes it
      result = unwrap(PrettyPrinter.format(input))
      expected = "<span class=\"jse-string\">#{q()}not json#{q()}</span>"
      assert result == expected
    end

    test "parses valid JSON string input" do
      input = "{\"a\": 1}"
      result = unwrap(PrettyPrinter.format(input))
      # Should format as map
      assert result =~ "<span class=\"jse-key\">#{q()}a#{q()}</span>"
      assert result =~ "<span class=\"jse-number\">1</span>"
    end
  end
end
