defmodule JSONSchemaEditor.ValidatorPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias JSONSchemaEditor.Validator

  property "validates min/max constraints ordering" do
    pairs = [
      {"minLength", "maxLength"},
      {"minimum", "maximum"},
      {"minItems", "maxItems"},
      {"minContains", "maxContains"},
      {"minProperties", "maxProperties"}
    ]

    check all(
            {min_key, max_key} <- member_of(pairs),
            max_val <- integer(),
            diff <- positive_integer()
          ) do
      min_val = max_val + diff

      schema = %{
        min_key => min_val,
        max_key => max_val
      }

      errors = Validator.validate_schema(schema)

      assert Map.has_key?(errors, "#{format_path_root(min_key)}"),
             "Expected error for #{min_key} > #{max_key} with values #{min_val}, #{max_val}"

      assert errors["#{format_path_root(min_key)}"] == "Must be ≤ #{max_key}"
    end
  end

  property "validates multipleOf must be positive" do
    check all(
            val <- one_of([integer(), float()]),
            val <= 0
          ) do
      schema = %{"multipleOf" => val}
      errors = Validator.validate_schema(schema)

      assert errors["#{format_path_root("multipleOf")}"] == "Must be > 0"
    end
  end

  property "validates enum uniqueness" do
    check all(
            list <- list_of(term(), min_length: 1),
            duplicate <- member_of(list)
          ) do
      schema = %{"enum" => list ++ [duplicate]}
      errors = Validator.validate_schema(schema)

      assert errors["#{format_path_root("enum")}"] == "Values must be unique"
    end
  end

  # Helper to match how Validator keys errors.
  # The validator outputs keys like "[]:minLength" (root path).
  # `validate_schema` uses `path_json = JSON.encode!(path)` which for empty list is "[]".
  # Wait, standard JSON encode of [] is "[]".
  defp format_path_root(field) do
    "[]:#{field}"
  end
end
