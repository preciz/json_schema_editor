defmodule JSONSchemaEditor.SchemaMutatorPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias JSONSchemaEditor.{SchemaMutator, SchemaUtils}

  def simple_schema do
    one_of([
      constant(%{"type" => "string"}),
      constant(%{"type" => "integer"}),
      constant(%{"type" => "boolean"}),
      constant(%{"type" => "object", "properties" => %{}}),
      constant(%{"type" => "array", "items" => %{"type" => "string"}})
    ])
  end

  property "change_type correctly resets fields for the target type" do
    check all(
            properties <- map_of(string(:alphanumeric, min_length: 1, max_length: 10), simple_schema(), min_length: 1, max_length: 10),
            path <- list_of(string(:alphanumeric, min_length: 1, max_length: 10), max_length: 3),
            type <- member_of(~w(string number integer boolean object array anyOf oneOf allOf))
          ) do
      node = %{"type" => "object", "properties" => properties, "required" => Map.keys(properties)}
      schema = SchemaUtils.put_in_path(%{}, path, node)

      updated_schema = SchemaMutator.change_type(schema, path, type)
      updated_node = SchemaUtils.get_in_path(updated_schema, path)

      case type do
        "object" ->
          assert updated_node["type"] == "object"
          assert is_map(updated_node["properties"])
          refute Map.has_key?(updated_node, "required")

        "array" ->
          assert updated_node["type"] == "array"
          assert is_map(updated_node["items"])
          refute Map.has_key?(updated_node, "properties")

        t when t in ~w(anyOf oneOf allOf) ->
          refute Map.has_key?(updated_node, "type")
          assert is_list(updated_node[t])

        _ ->
          assert updated_node["type"] == type
          refute Map.has_key?(updated_node, "properties")
          refute Map.has_key?(updated_node, "items")
      end
    end
  end

  property "toggle_required is its own inverse" do
    check all(
            properties <- map_of(string(:alphanumeric, min_length: 1, max_length: 10), simple_schema(), min_length: 1, max_length: 10),
            path <- list_of(string(:alphanumeric, min_length: 1, max_length: 10), max_length: 3),
            key <- member_of(Map.keys(properties))
          ) do
      node = %{"type" => "object", "properties" => properties}
      schema = SchemaUtils.put_in_path(%{}, path, node)

      schema_once = SchemaMutator.toggle_required(schema, path, key)
      schema_twice = SchemaMutator.toggle_required(schema_once, path, key)

      # After two toggles, it should be back to original. 
      # Note: toggle_required might initialize "required" to [key] if it didn't exist.
      # So we compare the nodes, but we might need to handle the case where "required" was missing vs empty.
      
      node_before = SchemaUtils.get_in_path(schema, path)
      node_after = SchemaUtils.get_in_path(schema_twice, path)
      
      # toggle_required implementation:
      # Map.update(node, "required", [key], &if(key in &1, do: List.delete(&1, key), else: &1 ++ [key]))
      # If "required" was missing, it becomes [key], then toggle again deletes it and leaves [].
      # So if it was missing, it becomes empty.
      
      clean_before = if Map.get(node_before, "required") == nil, do: Map.put(node_before, "required", []), else: node_before
      assert node_after == clean_before
    end
  end

  property "rename_property followed by rename_property back is identity" do
    check all(
            properties <- map_of(string(:alphanumeric, min_length: 1, max_length: 10), simple_schema(), min_length: 1, max_length: 10),
            path <- list_of(string(:alphanumeric, min_length: 1, max_length: 10), max_length: 3),
            old_key <- member_of(Map.keys(properties)),
            new_key <- string(:alphanumeric, min_length: 1, max_length: 10),
            !Map.has_key?(properties, new_key)
          ) do
      node = %{"type" => "object", "properties" => properties}
      schema = SchemaUtils.put_in_path(%{}, path, node)

      case SchemaMutator.rename_property(schema, path, old_key, new_key) do
        {:ok, schema_renamed} ->
          case SchemaMutator.rename_property(schema_renamed, path, new_key, old_key) do
            {:ok, schema_back} ->
              # Similar to toggle_required, rename_property might initialize "required" to []
              node_before = SchemaUtils.get_in_path(schema, path)
              node_after = SchemaUtils.get_in_path(schema_back, path)
              clean_before = if Map.get(node_before, "required") == nil, do: Map.put(node_before, "required", []), else: node_before
              assert node_after == clean_before
            _ ->
              assert false, "Failed to rename back"
          end
        _ ->
          assert false, "Failed to rename initially"
      end
    end
  end

  property "add_property followed by delete_property returns to original (mostly)" do
    check all(
            properties <- map_of(string(:alphanumeric, min_length: 1, max_length: 10), simple_schema(), min_length: 1, max_length: 10),
            path <- list_of(string(:alphanumeric, min_length: 1, max_length: 10), max_length: 3)
          ) do
      node = %{"type" => "object", "properties" => properties}
      schema = SchemaUtils.put_in_path(%{}, path, node)

      {new_schema, new_key} = SchemaMutator.add_property(schema, path)
      final_schema = SchemaMutator.delete_property(new_schema, path, new_key)

      node_before = SchemaUtils.get_in_path(schema, path)
      node_after = SchemaUtils.get_in_path(final_schema, path)

      # Strip 'required' if it's empty in both or missing in one and empty in other
      clean_before = if Map.get(node_before, "required") in [nil, []], do: Map.delete(node_before, "required"), else: node_before
      clean_after = if Map.get(node_after, "required") in [nil, []], do: Map.delete(node_after, "required"), else: node_after

      assert clean_after == clean_before
    end
  end
end