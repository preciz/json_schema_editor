defmodule JSONSchemaEditor.SchemaUtils do
  @moduledoc """
  Utility functions for working with JSON Schemas.
  """

  def get_in_path(data, path) when is_binary(path), do: get_in_path(data, JSON.decode!(path))
  def get_in_path(data, []), do: data

  def get_in_path(data, [key | rest]) when is_map(data),
    do: get_in_path(Map.get(data, key), rest)

  def get_in_path(data, [key | rest]) when is_list(data) and is_integer(key),
    do: get_in_path(Enum.at(data, key), rest)

  def get_in_path(_, _), do: nil

  def put_in_path(data, path, value) do
    update_in_path(data, path, fn _ -> value end)
  end

  def update_in_path(data, path, func) when is_binary(path),
    do: update_in_path(data, JSON.decode!(path), func)

  def update_in_path(data, [], func), do: func.(data)

  def update_in_path(data, [key | rest], func)
      when is_integer(key) and (is_list(data) or is_nil(data)) do
    data = data || []
    current = Enum.at(data, key)
    new_child = update_in_path(current, rest, func)

    if key < length(data) do
      List.replace_at(data, key, new_child)
    else
      # Pad with nil if there's a gap
      padding =
        if key > length(data), do: Enum.map(length(data)..(key - 1), fn _ -> nil end), else: []

      data ++ padding ++ [new_child]
    end
  end

  def update_in_path(data, [key | rest], func) do
    data = if is_map(data), do: data, else: %{}
    Map.put(data, key, update_in_path(Map.get(data, key), rest, func))
  end

  def generate_unique_key(existing_map, base_name, counter \\ 1) do
    key = if counter == 1, do: base_name, else: "#{base_name}_#{counter}"

    if Map.has_key?(existing_map, key),
      do: generate_unique_key(existing_map, base_name, counter + 1),
      else: key
  end

  def cast_value(field, value)
      when field in ~w(integer minLength maxLength minItems maxItems minProperties maxProperties) do
    val_str = to_string(value)

    case Integer.parse(val_str) do
      {int, _} ->
        int

      :error ->
        if "min" in String.split(field, ~r/[A-Z]/) or "max" in String.split(field, ~r/[A-Z]/),
          do: nil,
          else: 0
    end
  end

  def cast_value(field, value) when field in ~w(number minimum maximum multipleOf) do
    val_str = to_string(value)

    case Float.parse(val_str) do
      {float, _} -> float
      :error -> if field == "number", do: 0.0, else: nil
    end
  end

  def cast_value(field, value) when field in ~w(boolean uniqueItems), do: value == "true"
  def cast_value("null", _value), do: nil
  def cast_value(_field, value), do: value

  def cast_type(value, "string") when is_map(value) or is_list(value), do: ""
  def cast_type(value, "string"), do: to_string(value)

  def cast_type(value, "number") when is_map(value) or is_list(value), do: 0

  def cast_type(value, "number") do
    value = to_string(value)

    case Float.parse(value) do
      {num, _} -> if String.contains?(value, "."), do: num, else: trunc(num)
      :error -> 0
    end
  end

  def cast_type(value, "integer") when is_map(value) or is_list(value), do: 0

  def cast_type(value, "integer") do
    cast_type(value, "number") |> trunc()
  end

  def cast_type(value, "boolean") when is_map(value) or is_list(value), do: false

  def cast_type(value, "boolean") do
    cond do
      is_boolean(value) -> value
      value == "true" -> true
      value == "false" -> false
      true -> false
    end
  end

  def cast_type(_value, "object"), do: %{}
  def cast_type(_value, "array"), do: []
  def cast_type(_value, "null"), do: nil
  def cast_type(value, _), do: value

  def get_type(v) when is_binary(v), do: "string"
  def get_type(v) when is_boolean(v), do: "boolean"
  def get_type(v) when is_number(v), do: "number"
  def get_type(v) when is_list(v), do: "array"
  def get_type(v) when is_map(v), do: "object"
  def get_type(nil), do: "null"
  def get_type(_), do: "string"

  @doc """
  Recursively removes a specific custom property (e.g. "x-custom") from the schema.
  """
  def clean_custom_property(schema, property_name) when is_map(schema) do
    schema
    |> Map.delete(property_name)
    |> Map.new(fn {k, v} -> {k, clean_custom_property(v, property_name)} end)
  end

  def clean_custom_property(schema, property_name) when is_list(schema) do
    Enum.map(schema, &clean_custom_property(&1, property_name))
  end

  def clean_custom_property(schema, _), do: schema

  @doc """
  Recursively removes all properties starting with "x-" from the schema.
  """
  def clean_all_custom_properties(schema) when is_map(schema) do
    schema
    |> Map.reject(fn {k, _} -> String.starts_with?(to_string(k), "x-") end)
    |> Map.new(fn {k, v} -> {k, clean_all_custom_properties(v)} end)
  end

  def clean_all_custom_properties(schema) when is_list(schema) do
    Enum.map(schema, &clean_all_custom_properties/1)
  end

  def clean_all_custom_properties(schema), do: schema
end
