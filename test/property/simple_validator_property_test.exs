defmodule JSONSchemaEditor.SimpleValidatorPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias JSONSchemaEditor.SimpleValidator

  property "validates basic types correctly" do
    check all(
            type <- member_of(~w(string number integer boolean null array object)),
            data <- term()
          ) do
      schema = %{"type" => type}
      errors = SimpleValidator.validate(schema, data)

      is_valid = matches_type?(type, data)

      if is_valid do
        assert errors == [], "Expected data #{inspect(data)} to match type #{type}"
      else
        assert errors != [], "Expected data #{inspect(data)} NOT to match type #{type}"
        assert hd(errors) |> elem(1) =~ "Expected #{type}"
      end
    end
  end

  property "validates string length constraints" do
    check all(
            min <- integer(0..10),
            len <- integer(min..20),
            str <- string(:printable, length: len)
          ) do
      # Adjust min to ensure it respects grapheme length
      actual_len = String.length(str)
      adjusted_min = min(min, actual_len)

      schema = %{"type" => "string", "minLength" => adjusted_min}
      assert SimpleValidator.validate(schema, str) == []
    end
  end

  property "validates string length failure" do
    check all(
            min <- integer(1..10),
            len <- integer(0..(min - 1)),
            str <- string(:printable, length: len)
          ) do
      schema = %{"type" => "string", "minLength" => min}
      assert SimpleValidator.validate(schema, str) != []
    end
  end

  property "validates integer limits" do
    check all(
            min <- integer(),
            val <- integer(min..(min + 1000))
          ) do
      schema = %{"type" => "integer", "minimum" => min}
      assert SimpleValidator.validate(schema, val) == []
    end
  end

  property "validates null type strictly" do
    check all(data <- term()) do
      schema = %{"type" => "null"}

      if is_nil(data) do
        assert SimpleValidator.validate(schema, data) == []
      else
        assert SimpleValidator.validate(schema, data) != []
      end
    end
  end

  property "validates array length constraints" do
    check all(
            min <- integer(0..10),
            len <- integer(min..20),
            list <- list_of(term(), length: len)
          ) do
      schema = %{"type" => "array", "minItems" => min}
      assert SimpleValidator.validate(schema, list) == []
    end
  end

  property "validates array length failure" do
    check all(
            min <- integer(1..10),
            len <- integer(0..(min - 1)),
            list <- list_of(term(), length: len)
          ) do
      schema = %{"type" => "array", "minItems" => min}
      assert SimpleValidator.validate(schema, list) != []
    end
  end

  property "validates object properties count" do
    check all(
            min <- integer(0..5),
            count <- integer(min..10),
            map <- map_of(string(:alphanumeric), term(), length: count)
          ) do
      schema = %{"type" => "object", "minProperties" => min}
      assert SimpleValidator.validate(schema, map) == []
    end
  end

  defp matches_type?("string", v), do: is_binary(v)
  defp matches_type?("number", v), do: is_number(v)
  defp matches_type?("integer", v), do: is_integer(v)
  defp matches_type?("boolean", v), do: is_boolean(v)
  defp matches_type?("null", v), do: is_nil(v)
  defp matches_type?("array", v), do: is_list(v)
  defp matches_type?("object", v), do: is_map(v)
end
