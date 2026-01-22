defmodule JSONSchemaEditor.SchemaUtils do
  @moduledoc false

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
end
