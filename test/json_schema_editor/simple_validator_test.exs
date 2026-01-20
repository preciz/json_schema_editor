defmodule JSONSchemaEditor.SimpleValidatorTest do
  use ExUnit.Case, async: true
  alias JSONSchemaEditor.SimpleValidator

  test "validates types" do
    assert SimpleValidator.validate(%{"type" => "string"}, "foo") == []
    assert SimpleValidator.validate(%{"type" => "number"}, 1.5) == []
    assert SimpleValidator.validate(%{"type" => "integer"}, 42) == []
    assert SimpleValidator.validate(%{"type" => "boolean"}, true) == []
    assert SimpleValidator.validate(%{"type" => "object"}, %{}) == []
    assert SimpleValidator.validate(%{"type" => "array"}, []) == []

    assert SimpleValidator.validate(%{"type" => "string"}, 123) != []
    assert SimpleValidator.validate(%{"type" => "integer"}, 1.5) != []
  end

  test "validates const" do
    schema = %{"const" => "foo"}
    assert SimpleValidator.validate(schema, "foo") == []
    assert SimpleValidator.validate(schema, "bar") != []
  end

  test "validates enum" do
    schema = %{"enum" => ["a", "b"]}
    assert SimpleValidator.validate(schema, "a") == []
    assert SimpleValidator.validate(schema, "c") != []
  end

  test "validates string constraints" do
    schema = %{"minLength" => 2, "maxLength" => 4, "pattern" => "^a.*"}
    assert SimpleValidator.validate(schema, "abc") == []
    # Too short
    assert SimpleValidator.validate(schema, "a") != []
    # Too long
    assert SimpleValidator.validate(schema, "abcde") != []
    # Wrong pattern
    assert SimpleValidator.validate(schema, "bcd") != []
  end

  test "validates number constraints" do
    schema = %{"minimum" => 10, "maximum" => 20, "multipleOf" => 2}
    assert SimpleValidator.validate(schema, 12) == []
    assert SimpleValidator.validate(schema, 9) != []
    assert SimpleValidator.validate(schema, 21) != []
    assert SimpleValidator.validate(schema, 13) != []

    # Float multipleOf
    float_schema = %{"multipleOf" => 0.5}
    assert SimpleValidator.validate(float_schema, 1.5) == []
    assert SimpleValidator.validate(float_schema, 1.2) != []

    # Integer multipleOf
    int_schema = %{"multipleOf" => 3}
    assert SimpleValidator.validate(int_schema, 9) == []
    assert SimpleValidator.validate(int_schema, 10) != []
  end

  test "validates array constraints" do
    schema = %{
      "minItems" => 1,
      "maxItems" => 3,
      "uniqueItems" => true,
      "items" => %{"type" => "string"}
    }

    assert SimpleValidator.validate(schema, ["a", "b"]) == []
    # minItems
    assert SimpleValidator.validate(schema, []) != []
    # maxItems
    assert SimpleValidator.validate(schema, ["a", "b", "c", "d"]) != []
    # uniqueItems
    assert SimpleValidator.validate(schema, ["a", "a"]) != []
    # items type
    assert SimpleValidator.validate(schema, [1]) != []
  end

  test "validates array contains" do
    schema = %{"contains" => %{"type" => "number"}}
    assert SimpleValidator.validate(schema, ["a", 1]) == []
    assert SimpleValidator.validate(schema, ["a", "b"]) != []
  end

  test "validates object constraints" do
    schema = %{
      "minProperties" => 1,
      "maxProperties" => 2,
      "required" => ["a"],
      "properties" => %{"a" => %{"type" => "string"}},
      "additionalProperties" => false
    }

    assert SimpleValidator.validate(schema, %{"a" => "foo"}) == []
    # minProps / required
    assert SimpleValidator.validate(schema, %{}) != []
    # maxProps
    assert SimpleValidator.validate(schema, %{"a" => "foo", "b" => 1, "c" => 2}) != []
    # additionalProperties (b not allowed)
    assert SimpleValidator.validate(schema, %{"a" => "foo", "b" => 1}) != []

    # Test additionalProperties: true (default)
    schema_open = %{"properties" => %{"a" => %{"type" => "string"}}}
    assert SimpleValidator.validate(schema_open, %{"a" => "foo", "unknown" => 123}) == []
  end

  test "validates array constraints in depth" do
    schema = %{"uniqueItems" => true, "minItems" => 2}
    assert SimpleValidator.validate(schema, [1, 2]) == []
    # uniqueItems
    assert SimpleValidator.validate(schema, [1, 1]) != []
    # minItems
    assert SimpleValidator.validate(schema, [1]) != []

    schema_max = %{"maxItems" => 1}
    assert SimpleValidator.validate(schema_max, [1, 2]) != []
  end

  test "validates logic composition" do
    # anyOf
    any_schema = %{"anyOf" => [%{"type" => "string"}, %{"type" => "number"}]}
    assert SimpleValidator.validate(any_schema, "a") == []
    assert SimpleValidator.validate(any_schema, 1) == []
    # Fails both
    assert SimpleValidator.validate(any_schema, true) != []

    # allOf
    all_schema = %{"allOf" => [%{"minimum" => 5}, %{"maximum" => 10}]}
    assert SimpleValidator.validate(all_schema, 7) == []
    assert SimpleValidator.validate(all_schema, 2) != []
    assert SimpleValidator.validate(all_schema, 12) != []
    # "not-a-number" is ignored by numeric constraints if type is not enforced, so it passes empty list.
    
    # Actually allOf fails if any branch fails.
    # If branches are {%{"type" => "string"}, %{"minLength" => 10}}
    # "a" fails branch 2.
    all_schema_2 = %{"allOf" => [%{"type" => "string"}, %{"minLength" => 5}]}
    assert SimpleValidator.validate(all_schema_2, "abc") != []
  end

  test "validates complex nested structures" do
    schema = %{
      "type" => "object",
      "properties" => %{
        "users" => %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "required" => ["id", "name"],
            "properties" => %{
              "id" => %{"type" => "integer"},
              "name" => %{"type" => "string"}
            }
          }
        }
      }
    }

    valid_data = %{"users" => [%{"id" => 1, "name" => "A"}, %{"id" => 2, "name" => "B"}]}
    assert SimpleValidator.validate(schema, valid_data) == []

    invalid_data = %{"users" => [%{"id" => "1", "name" => "A"}]}
    errors = SimpleValidator.validate(schema, invalid_data)
    assert length(errors) == 1
    assert hd(errors) |> elem(0) == "users[0].id"
  end

  test "handles invalid regex pattern gracefully" do
    # Invalid regex
    schema = %{"type" => "string", "pattern" => "("}
    assert SimpleValidator.validate(schema, "anything") == []
  end

  test "validates with nil type (allows any type)" do
    assert SimpleValidator.validate(%{}, "foo") == []
    assert SimpleValidator.validate(%{}, 123) == []
  end

  test "identifies unknown types in error messages" do
    schema = %{"type" => "string"}
    # Use a PID as unknown type for SimpleValidator
    errors = SimpleValidator.validate(schema, self())
    assert hd(errors) |> elem(1) =~ "got unknown"
  end
end
