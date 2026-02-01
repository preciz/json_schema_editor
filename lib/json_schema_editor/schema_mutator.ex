defmodule JSONSchemaEditor.SchemaMutator do
  @moduledoc """
  Handles all mutations to the JSON Schema.
  """

  alias JSONSchemaEditor.SchemaUtils

  @logic_types ~w(anyOf oneOf allOf)

  def change_type(schema, path, type) do
    SchemaUtils.update_in_path(schema, path, fn node ->
      base = Map.drop(node, ~w(type properties required items anyOf oneOf allOf))

      case type do
        "object" -> Map.merge(base, %{"type" => "object", "properties" => %{}})
        "array" -> Map.merge(base, %{"type" => "array", "items" => %{"type" => "string"}})
        l when l in @logic_types -> Map.put(base, l, [%{"type" => "string"}])
        _ -> Map.put(base, "type", type)
      end
    end)
  end

  def add_property(schema, path) do
    current_node = SchemaUtils.get_in_path(schema, path)
    current_props = Map.get(current_node, "properties", %{})
    new_key = SchemaUtils.generate_unique_key(current_props, "new_field")

    new_schema =
      SchemaUtils.update_in_path(schema, path, fn node ->
        props = Map.get(node, "properties", %{})
        Map.put(node, "properties", Map.put(props, new_key, %{"type" => "string"}))
      end)

    {new_schema, new_key}
  end

  def delete_property(schema, path, key) do
    SchemaUtils.update_in_path(schema, path, fn node ->
      node
      |> Map.update("properties", %{}, &Map.delete(&1, key))
      |> Map.update("required", [], &List.delete(&1, key))
    end)
  end

  def rename_property(schema, path, old_key, new_key) do
    new_key = String.trim(new_key)

    if new_key == "" or new_key == old_key do
      :no_change
    else
      current_node = SchemaUtils.get_in_path(schema, path)
      current_props = Map.get(current_node, "properties", %{})

      if Map.has_key?(current_props, new_key) do
        :collision
      else
        new_schema =
          SchemaUtils.update_in_path(schema, path, fn node ->
            {val, props} = Map.pop(node["properties"], old_key)

            node
            |> Map.put("properties", Map.put(props, new_key, val))
            |> Map.update("required", [], fn req ->
              Enum.map(req, &if(&1 == old_key, do: new_key, else: &1))
            end)
          end)

        {:ok, new_schema}
      end
    end
  end

  def toggle_required(schema, path, key) do
    SchemaUtils.update_in_path(schema, path, fn node ->
      Map.update(
        node,
        "required",
        [key],
        &if(key in &1, do: List.delete(&1, key), else: &1 ++ [key])
      )
    end)
  end

  def update_field(schema, path, field, value) do
    SchemaUtils.update_in_path(schema, path, fn node ->
      if value in [nil, "", false],
        do: Map.delete(node, field),
        else: Map.put(node, field, value)
    end)
  end

  def update_constraint(schema, path, field, value) do
    casted_value = SchemaUtils.cast_value(field, value)
    update_field(schema, path, field, casted_value)
  end

  def update_const(schema, path, value) do
    SchemaUtils.update_in_path(schema, path, fn node ->
      if value == "" do
        Map.delete(node, "const")
      else
        casted = SchemaUtils.cast_value(node["type"] || "string", value)
        Map.put(node, "const", casted)
      end
    end)
  end

  def toggle_additional_properties(schema, path) do
    SchemaUtils.update_in_path(schema, path, fn node ->
      if node["additionalProperties"] == false,
        do: Map.delete(node, "additionalProperties"),
        else: Map.put(node, "additionalProperties", false)
    end)
  end

  def add_enum_value(schema, path) do
    SchemaUtils.update_in_path(schema, path, fn node ->
      def_val =
        case node["type"] do
          "number" -> 0.0
          "integer" -> 0
          "boolean" -> true
          "null" -> nil
          _ -> "new value"
        end

      Map.update(node, "enum", [def_val], &(&1 ++ [def_val]))
    end)
  end

  def remove_enum_value(schema, path, index_str) do
    index = String.to_integer(index_str)

    SchemaUtils.update_in_path(schema, path, fn node ->
      new_enum = List.delete_at(node["enum"] || [], index)
      if new_enum == [], do: Map.delete(node, "enum"), else: Map.put(node, "enum", new_enum)
    end)
  end

  def update_enum_value(schema, path, index_str, value) do
    index = String.to_integer(index_str)

    SchemaUtils.update_in_path(schema, path, fn node ->
      casted = SchemaUtils.cast_value(node["type"] || "string", value)

      Map.put(
        node,
        "enum",
        List.replace_at(node["enum"] || [], index, casted)
      )
    end)
  end

  def add_logic_branch(schema, path, type) do
    SchemaUtils.update_in_path(schema, path, fn node ->
      Map.update(node, type, [], &(&1 ++ [%{"type" => "string"}]))
    end)
  end

  def remove_logic_branch(schema, path, type, index_str) do
    index = String.to_integer(index_str)

    SchemaUtils.update_in_path(schema, path, fn node ->
      new_branches = List.delete_at(node[type] || [], index)

      if new_branches == [],
        do: Map.delete(node, type) |> Map.put("type", "string"),
        else: Map.put(node, type, new_branches)
    end)
  end

  def add_child(schema, path, key) do
    SchemaUtils.update_in_path(schema, path, &Map.put(&1, key, %{"type" => "string"}))
  end

  def remove_child(schema, path, key) do
    SchemaUtils.update_in_path(schema, path, &Map.delete(&1, key))
  end

  def add_extension(schema, path) do
    current_node = SchemaUtils.get_in_path(schema, path)
    new_key = SchemaUtils.generate_unique_key(current_node, "x-new-property")

    new_schema =
      SchemaUtils.update_in_path(schema, path, fn node ->
        Map.put(node, new_key, "value")
      end)

    {new_schema, new_key}
  end

  def delete_extension(schema, path, key) do
    SchemaUtils.update_in_path(schema, path, &Map.delete(&1, key))
  end

  def update_extension_key(schema, path, old_key, new_key) do
    new_key = String.trim(new_key)

    if new_key == "" or new_key == old_key or not String.starts_with?(new_key, "x-") do
      :no_change
    else
      current_node = SchemaUtils.get_in_path(schema, path)

      if Map.has_key?(current_node, new_key) do
        :collision
      else
        {:ok,
         SchemaUtils.update_in_path(schema, path, fn node ->
           {val, node} = Map.pop(node, old_key)
           Map.put(node, new_key, val)
         end)}
      end
    end
  end

  def update_extension_value(schema, path, key, value) do
    # Try to cast to number/bool if it looks like one, otherwise keep as string
    casted =
      cond do
        value == "true" ->
          true

        value == "false" ->
          false

        value == "null" ->
          nil

        Regex.match?(~r/^-?\d+(\.\d+)?$/, value) ->
          case Float.parse(value) do
            {f, ""} -> if f == trunc(f), do: trunc(f), else: f
            _ -> value
          end

        true ->
          value
      end

    SchemaUtils.update_in_path(schema, path, &Map.put(&1, key, casted))
  end
end
