defmodule JSONSchemaEditor.SchemaMutatorTest do
  use ExUnit.Case, async: true
  alias JSONSchemaEditor.SchemaMutator

  describe "change_type/3" do
    test "changes type to simple type" do
      schema = %{"type" => "string"}
      new_schema = SchemaMutator.change_type(schema, "[]", "number")
      assert new_schema == %{"type" => "number"}
    end

    test "changes type to object" do
      schema = %{"type" => "string"}
      new_schema = SchemaMutator.change_type(schema, "[]", "object")
      assert new_schema == %{"type" => "object", "properties" => %{}}
    end

    test "changes type to array" do
      schema = %{"type" => "string"}
      new_schema = SchemaMutator.change_type(schema, "[]", "array")
      assert new_schema == %{"type" => "array", "items" => %{"type" => "string"}}
    end

    test "changes type to logic type (anyOf)" do
      schema = %{"type" => "string"}
      new_schema = SchemaMutator.change_type(schema, "[]", "anyOf")
      assert new_schema == %{"anyOf" => [%{"type" => "string"}]}
      refute Map.has_key?(new_schema, "type")
    end

    test "preserves other properties" do
      schema = %{"type" => "string", "title" => "My Title"}
      new_schema = SchemaMutator.change_type(schema, "[]", "number")
      assert new_schema["type"] == "number"
      assert new_schema["title"] == "My Title"
    end
  end

  describe "add_property/2" do
    test "adds a new property" do
      schema = %{"type" => "object", "properties" => %{}}
      {new_schema, key} = SchemaMutator.add_property(schema, "[]")
      assert key == "new_field"
      assert new_schema["properties"]["new_field"] == %{"type" => "string"}
    end

    test "handles collisions" do
      schema = %{"type" => "object", "properties" => %{"new_field" => %{}}}
      {new_schema, key} = SchemaMutator.add_property(schema, "[]")
      assert key == "new_field_2"
      assert new_schema["properties"]["new_field_2"] == %{"type" => "string"}
    end
  end

  describe "delete_property/3" do
    test "deletes a property and removes from required" do
      schema = %{
        "type" => "object",
        "properties" => %{"a" => %{}},
        "required" => ["a", "b"]
      }

      new_schema = SchemaMutator.delete_property(schema, "[]", "a")
      refute Map.has_key?(new_schema["properties"], "a")
      assert new_schema["required"] == ["b"]
    end
  end

  describe "rename_property/4" do
    test "renames property and updates required" do
      schema = %{
        "type" => "object",
        "properties" => %{"old" => %{"type" => "string"}},
        "required" => ["old", "other"]
      }

      {:ok, new_schema} = SchemaMutator.rename_property(schema, "[]", "old", "new")
      assert Map.has_key?(new_schema["properties"], "new")
      refute Map.has_key?(new_schema["properties"], "old")
      assert new_schema["properties"]["new"] == %{"type" => "string"}
      assert "new" in new_schema["required"]
      assert "other" in new_schema["required"]
    end

    test "returns :no_change if new name is empty or same" do
      schema = %{"type" => "object"}
      assert SchemaMutator.rename_property(schema, "[]", "old", "") == :no_change
      assert SchemaMutator.rename_property(schema, "[]", "old", "old") == :no_change
    end

    test "returns :collision if new name exists" do
      schema = %{"type" => "object", "properties" => %{"a" => %{}, "b" => %{}}}
      assert SchemaMutator.rename_property(schema, "[]", "a", "b") == :collision
    end
  end

  describe "toggle_required/3" do
    test "toggles required status" do
      schema = %{"type" => "object", "properties" => %{"a" => %{}}}

      # Add
      new_schema = SchemaMutator.toggle_required(schema, "[]", "a")
      assert "a" in new_schema["required"]

      # Remove
      new_schema_2 = SchemaMutator.toggle_required(new_schema, "[]", "a")
      refute "a" in new_schema_2["required"]
    end
  end

  describe "update_field/4" do
    test "updates field" do
      schema = %{}
      new_schema = SchemaMutator.update_field(schema, "[]", "title", "My Title")
      assert new_schema["title"] == "My Title"
    end

    test "removes field if value is empty/nil/false" do
      schema = %{"title" => "Old"}
      assert SchemaMutator.update_field(schema, "[]", "title", "") == %{}
      assert SchemaMutator.update_field(schema, "[]", "title", nil) == %{}
    end
  end

  describe "update_constraint/4" do
    test "casts values" do
      schema = %{"type" => "number"}
      new_schema = SchemaMutator.update_constraint(schema, "[]", "minimum", "10.5")
      assert new_schema["minimum"] == 10.5
    end
  end

  describe "update_const/3" do
    test "updates const value" do
      schema = %{"type" => "string"}
      new_schema = SchemaMutator.update_const(schema, "[]", "fixed")
      assert new_schema["const"] == "fixed"
    end

    test "removes const if empty" do
      schema = %{"const" => "fixed"}
      new_schema = SchemaMutator.update_const(schema, "[]", "")
      refute Map.has_key?(new_schema, "const")
    end
  end

  describe "toggle_additional_properties/2" do
    test "toggles false/nil" do
      schema = %{"type" => "object"}
      # Set to false
      new_schema = SchemaMutator.toggle_additional_properties(schema, "[]")
      assert new_schema["additionalProperties"] == false
      # Unset
      new_schema_2 = SchemaMutator.toggle_additional_properties(new_schema, "[]")
      refute Map.has_key?(new_schema_2, "additionalProperties")
    end
  end

  describe "enum operations" do
    test "add_enum_value" do
      schema = %{"type" => "string"}
      new_schema = SchemaMutator.add_enum_value(schema, "[]")
      assert new_schema["enum"] == ["new value"]
    end

    test "remove_enum_value" do
      schema = %{"type" => "string", "enum" => ["a", "b"]}
      new_schema = SchemaMutator.remove_enum_value(schema, "[]", "0")
      assert new_schema["enum"] == ["b"]
    end

    test "update_enum_value" do
      schema = %{"type" => "string", "enum" => ["a"]}
      new_schema = SchemaMutator.update_enum_value(schema, "[]", "0", "b")
      assert new_schema["enum"] == ["b"]
    end
  end

  describe "logic branches" do
    test "add_logic_branch" do
      schema = %{"oneOf" => []}
      new_schema = SchemaMutator.add_logic_branch(schema, "[]", "oneOf")
      assert length(new_schema["oneOf"]) == 1
    end

    test "remove_logic_branch" do
      schema = %{"oneOf" => [%{}, %{}]}
      new_schema = SchemaMutator.remove_logic_branch(schema, "[]", "oneOf", "0")
      assert length(new_schema["oneOf"]) == 1
    end

    test "remove_logic_branch reverts to type string if empty" do
      schema = %{"oneOf" => [%{}]}
      new_schema = SchemaMutator.remove_logic_branch(schema, "[]", "oneOf", "0")
      refute Map.has_key?(new_schema, "oneOf")
      assert new_schema["type"] == "string"
    end
  end

  describe "child operations" do
    test "add_child" do
      schema = %{"type" => "array"}
      new_schema = SchemaMutator.add_child(schema, "[]", "contains")
      assert new_schema["contains"] == %{"type" => "string"}
    end

    test "remove_child" do
      schema = %{"type" => "array", "contains" => %{}}
      new_schema = SchemaMutator.remove_child(schema, "[]", "contains")
      refute Map.has_key?(new_schema, "contains")
    end
  end
end
