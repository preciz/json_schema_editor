defmodule JSONSchemaEditor.ValidatorPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias JSONSchemaEditor.Validator

  property "validate_schema never crashes on arbitrary map input" do
    check all(
            data <-
              map_of(
                string(:printable, min_length: 1, max_length: 10),
                one_of([integer(), boolean(), string(:printable, min_length: 1, max_length: 10)]),
                min_length: 1,
                max_length: 10
              )
          ) do
      # Should not crash
      _ = Validator.validate_schema(data)
      assert true
    end
  end

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
            max_val <- integer(0..1000),
            diff <- integer(1..100)
          ) do
      min_val = max_val + diff

      schema = %{
        min_key => min_val,
        max_key => max_val
      }

      errors = Validator.validate_schema(schema)

      error_key = {[], min_key}

      assert Map.has_key?(errors, error_key),
             "Expected error for #{min_key} > #{max_key} with values #{min_val}, #{max_val}"

      assert errors[error_key] == "Must be ≤ #{max_key}"
    end
  end

  property "validates multipleOf must be positive" do
    check all(val <- one_of([integer(-100..0), float(min: -100.0, max: 0.0)])) do
      schema = %{"multipleOf" => val}
      errors = Validator.validate_schema(schema)

      assert errors[{[], "multipleOf"}] == "Must be > 0"
    end
  end

  property "validates enum uniqueness" do
    check all(
            list <-
              list_of(one_of([integer(), boolean(), string(:alphanumeric, max_length: 10)]),
                min_length: 1,
                max_length: 20
              ),
            duplicate <- member_of(list)
          ) do
      schema = %{"enum" => list ++ [duplicate]}
      errors = Validator.validate_schema(schema)

      assert errors[{[], "enum"}] == "Values must be unique"
    end
  end
end
