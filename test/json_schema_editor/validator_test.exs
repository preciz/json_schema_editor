defmodule JSONSchemaEditor.ValidatorTest do
  use ExUnit.Case, async: true
  alias JSONSchemaEditor.Validator

  describe "validate_schema/1" do
    test "validates constraints for different types" do
      scenarios = [
        # String
        {%{"type" => "string", "minLength" => 5, "maxLength" => 10}, %{}},
        {%{"type" => "string", "minLength" => 10, "maxLength" => 5},
         %{{[], "minLength"} => "Must be ≤ maxLength"}},
        # Number
        {%{"type" => "number", "minimum" => 1, "maximum" => 10}, %{}},
        {%{"type" => "number", "minimum" => 10, "maximum" => 1},
         %{{[], "minimum"} => "Must be ≤ maximum"}},
        {%{"type" => "number", "multipleOf" => 2}, %{}},
        {%{"type" => "number", "multipleOf" => 0}, %{{[], "multipleOf"} => "Must be > 0"}},
        {%{"type" => "number", "multipleOf" => -1}, %{{[], "multipleOf"} => "Must be > 0"}},
        # Array
        {%{"type" => "array", "minItems" => 1, "maxItems" => 5}, %{}},
        {%{"type" => "array", "minItems" => 5, "maxItems" => 1},
         %{{[], "minItems"} => "Must be ≤ maxItems"}},
        # Object
        {%{"type" => "object", "minProperties" => 1, "maxProperties" => 5}, %{}},
        {%{"type" => "object", "minProperties" => 5, "maxProperties" => 1},
         %{{[], "minProperties"} => "Must be ≤ maxProperties"}},
        # Enum
        {%{"type" => "string", "enum" => ["a", "b"]}, %{}},
        {%{"type" => "string", "enum" => ["a", "a"]}, %{{[], "enum"} => "Values must be unique"}},
        # Format
        {%{"type" => "string", "format" => "email"}, %{}},
        {%{"type" => "number", "format" => "email"},
         %{{[], "format"} => "Only valid for strings"}},
        # Invalid child types (noop)
        {%{"type" => "object", "properties" => nil}, %{}},
        {%{"type" => "array", "items" => "invalid"}, %{}}
      ]

      for {schema, expected} <- scenarios do
        assert Validator.validate_schema(schema) == expected
      end
    end

    test "validates recursively" do
      schema = %{
        "type" => "object",
        "minLength" => 10,
        "maxLength" => 5,
        "properties" => %{
          "sub" => %{
            "type" => "array",
            "minItems" => 10,
            "maxItems" => 5
          }
        },
        "items" => %{
          "type" => "number",
          "minimum" => 10,
          "maximum" => 5
        }
      }

      errors = Validator.validate_schema(schema)
      assert errors[{[], "minLength"}]
      assert errors[{["properties", "sub"], "minItems"}]
      assert errors[{["items"], "minimum"}]
    end

    test "validates logic branches" do
      schema = %{"oneOf" => [%{"type" => "string", "minLength" => 5, "maxLength" => 2}]}
      errors = Validator.validate_schema(schema)
      assert errors[{["oneOf", 0], "minLength"}]
    end
  end
end
