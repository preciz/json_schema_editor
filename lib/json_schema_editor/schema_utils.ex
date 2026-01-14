defmodule JSONSchemaEditor.SchemaUtils do
  @moduledoc """
  Helper functions for manipulating nested JSON Schema maps.
  """

  @doc """
  Gets the value at a given path in a nested map.
  """
  def get_in_path(data, []), do: data

  def get_in_path(data, [key | rest]) when is_map(data),
    do: get_in_path(Map.get(data, key), rest)

  def get_in_path(_, _), do: nil

  @doc """
  Puts a value at a given path in a nested map, creating intermediate maps if necessary.
  """
  def put_in_path(_data, [], value), do: value

  def put_in_path(data, [key | rest], value) when is_map(data) or is_nil(data) do
    data = data || %{}
    Map.put(data, key, put_in_path(Map.get(data, key, %{}), rest, value))
  end

  @doc """
  Updates a value at a given path in a nested map using a transformation function.
  """
  def update_in_path(data, path, func) do
    node = get_in_path(data, path)
    put_in_path(data, path, func.(node))
  end

  @doc """
  Generates a unique key in a map by appending a counter to a base name.
  """
  def generate_unique_key(existing_map, base_name, counter \\ 1) do
    key = if counter == 1, do: base_name, else: "#{base_name}_#{counter}"

    if Map.has_key?(existing_map, key) do
      generate_unique_key(existing_map, base_name, counter + 1)
    else
      key
    end
  end

  @doc """
  Casts a constraint value based on the field name.
  """
  def cast_constraint_value(field, value) do
    cond do
      field in [
        "minLength",
        "maxLength",
        "minItems",
        "maxItems",
        "minProperties",
        "maxProperties"
      ] ->
        case Integer.parse(value) do
          {int, _} -> int
          :error -> nil
        end

      field in ["minimum", "maximum", "multipleOf"] ->
        case Float.parse(value) do
          {float, _} -> float
          :error -> nil
        end

      field == "uniqueItems" ->
        value == "true"

      true ->
        value
    end
  end

  @doc """
  Casts a string value to the appropriate type based on the schema type.
  """
  def cast_value_by_type("integer", value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> 0
    end
  end

  def cast_value_by_type("number", value) do
    case Float.parse(value) do
      {float, _} -> float
      :error -> 0.0
    end
  end

  def cast_value_by_type("boolean", value) do
    value == "true"
  end

  def cast_value_by_type(_type, value), do: value
end
