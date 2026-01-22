defmodule JSONSchemaEditor.SchemaUtils do
  @moduledoc false

  def get_in_path(data, []), do: data

  def get_in_path(data, [key | rest]) when is_map(data),
    do: get_in_path(Map.get(data, key), rest)

  def get_in_path(data, [key | rest]) when is_list(data) and is_integer(key),
    do: get_in_path(Enum.at(data, key), rest)

  def get_in_path(_, _), do: nil

  def put_in_path(_data, [], value), do: value

  def put_in_path(data, [key | rest], value)
      when is_integer(key) and (is_list(data) or is_nil(data)) do
    data = data || []
    current = Enum.at(data, key)
    new_child = put_in_path(current, rest, value)

    if key < length(data) do
      List.replace_at(data, key, new_child)
    else
      data ++ [new_child]
    end
  end

  def put_in_path(data, [key | rest], value) do
    data = if is_map(data), do: data, else: %{}
    Map.put(data, key, put_in_path(Map.get(data, key), rest, value))
  end

  def update_in_path(data, path, func) do
    node = get_in_path(data, path)
    put_in_path(data, path, func.(node))
  end

  def generate_unique_key(existing_map, base_name, counter \\ 1) do
    key = if counter == 1, do: base_name, else: "#{base_name}_#{counter}"

    if Map.has_key?(existing_map, key),
      do: generate_unique_key(existing_map, base_name, counter + 1),
      else: key
  end

  def cast_value(field, value)
      when field in ~w(integer minLength maxLength minItems maxItems minProperties maxProperties) do
    case Integer.parse(value) do
      {int, _} ->
        int

      :error ->
        if "min" in String.split(field, ~r/[A-Z]/) or "max" in String.split(field, ~r/[A-Z]/),
          do: nil,
          else: 0
    end
  end

  def cast_value(field, value) when field in ~w(number minimum maximum multipleOf) do
    case Float.parse(value) do
      {float, _} -> float
      :error -> if field == "number", do: 0.0, else: nil
    end
  end

  def cast_value(field, value) when field in ~w(boolean uniqueItems), do: value == "true"
  def cast_value("null", _value), do: nil
  def cast_value(_field, value), do: value
end
