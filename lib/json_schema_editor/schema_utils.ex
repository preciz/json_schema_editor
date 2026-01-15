defmodule JSONSchemaEditor.SchemaUtils do
  @moduledoc false

  def get_in_path(data, []), do: data

  def get_in_path(data, [key | rest]) when is_map(data),
    do: get_in_path(Map.get(data, key), rest)

  def get_in_path(_, _), do: nil

  def put_in_path(_data, [], value), do: value

  def put_in_path(data, [key | rest], value) when is_map(data) or is_nil(data) do
    data = data || %{}
    Map.put(data, key, put_in_path(Map.get(data, key, %{}), rest, value))
  end

  def update_in_path(data, path, func) do
    node = get_in_path(data, path)
    put_in_path(data, path, func.(node))
  end

  def generate_unique_key(existing_map, base_name, counter \\ 1) do
    key = if counter == 1, do: base_name, else: "#{base_name}_#{counter}"

    if Map.has_key?(existing_map, key) do
      generate_unique_key(existing_map, base_name, counter + 1)
    else
      key
    end
  end

  def cast_value(type_or_field, value) do
    cond do
      type_or_field in [
        "integer",
        "minLength",
        "maxLength",
        "minItems",
        "maxItems",
        "minProperties",
        "maxProperties"
      ] ->
        case Integer.parse(value) do
          {int, _} ->
            int

          :error ->
            if String.contains?(type_or_field, "min") or String.contains?(type_or_field, "max"),
              do: nil,
              else: 0
        end

      type_or_field in ["number", "minimum", "maximum", "multipleOf"] ->
        case Float.parse(value) do
          {float, _} -> float
          :error -> if type_or_field == "number", do: 0.0, else: nil
        end

      type_or_field in ["boolean", "uniqueItems"] ->
        value == "true"

      true ->
        value
    end
  end
end
