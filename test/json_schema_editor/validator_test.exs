defmodule JSONSchemaEditor.ValidatorTest do
  use ExUnit.Case, async: true
  alias JSONSchemaEditor.Validator

  test "validate_node strings" do
    assert Validator.validate_node(%{"type" => "string", "minLength" => 5, "maxLength" => 10}) ==
             %{}

    assert Validator.validate_node(%{"type" => "string", "minLength" => 10, "maxLength" => 5}) ==
             %{"minLength" => "Must be ≤ maxLength"}
  end

  test "validate_node numbers" do
    assert Validator.validate_node(%{"type" => "number", "minimum" => 1, "maximum" => 10}) == %{}

    assert Validator.validate_node(%{"type" => "number", "minimum" => 10, "maximum" => 1}) == %{
             "minimum" => "Must be ≤ maximum"
           }

    assert Validator.validate_node(%{"type" => "number", "multipleOf" => 2}) == %{}

    assert Validator.validate_node(%{"type" => "number", "multipleOf" => 0}) == %{
             "multipleOf" => "Must be > 0"
           }

    assert Validator.validate_node(%{"type" => "number", "multipleOf" => -1}) == %{
             "multipleOf" => "Must be > 0"
           }
  end

  test "validate_node arrays" do
    assert Validator.validate_node(%{"type" => "array", "minItems" => 1, "maxItems" => 5}) == %{}

    assert Validator.validate_node(%{"type" => "array", "minItems" => 5, "maxItems" => 1}) == %{
             "minItems" => "Must be ≤ maxItems"
           }
  end

  test "validate_node objects" do
    assert Validator.validate_node(%{
             "type" => "object",
             "minProperties" => 1,
             "maxProperties" => 5
           }) == %{}

    assert Validator.validate_node(%{
             "type" => "object",
             "minProperties" => 5,
             "maxProperties" => 1
           }) == %{"minProperties" => "Must be ≤ maxProperties"}
  end

  test "validate_node unique enum" do
    assert Validator.validate_node(%{"type" => "string", "enum" => ["a", "b"]}) == %{}

    assert Validator.validate_node(%{"type" => "string", "enum" => ["a", "a"]}) == %{
             "enum" => "Values must be unique"
           }
  end

  test "validate_node format" do
    assert Validator.validate_node(%{"type" => "string", "format" => "email"}) == %{}

    assert Validator.validate_node(%{"type" => "number", "format" => "email"}) == %{
             "format" => "Only valid for strings"
           }
  end

  test "validate_schema recursion" do
    schema = %{
      "type" => "object",
      # Error at root
      "minLength" => 10,
      "maxLength" => 5,
      "properties" => %{
        "sub" => %{
          "type" => "array",
          # Error in property
          "minItems" => 10,
          "maxItems" => 5
        }
      },
      "items" => %{
        "type" => "number",
        # Error in items (if object was array)
        "minimum" => 10,
        "maximum" => 5
      }
    }

    errors = Validator.validate_schema(schema)
    assert errors["[]:minLength"]
    assert errors["[\"properties\",\"sub\"]:minItems"]
    assert errors["[\"items\"]:minimum"]
  end

  test "validate_schema logic branches" do
    schema = %{
      "oneOf" => [
        %{"type" => "string", "minLength" => 5, "maxLength" => 2}
      ]
    }

    errors = Validator.validate_schema(schema)
    assert errors["[\"oneOf\",0]:minLength"]
  end

  test "validate_schema with invalid child types (noop)" do
    # When properties or items are not maps, they should be ignored by recursion
    assert Validator.validate_schema(%{"type" => "object", "properties" => nil}) == %{}
    assert Validator.validate_schema(%{"type" => "array", "items" => "invalid"}) == %{}
  end
end
