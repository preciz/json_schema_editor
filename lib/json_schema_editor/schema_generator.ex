defmodule JSONSchemaEditor.SchemaGenerator do
  @moduledoc """
  Infers a JSON Schema (Draft 07) from a given Elixir data structure (deserialized JSON).
  """

  def generate(data) when is_map(data) do
    properties =
      Map.new(data, fn {k, v} ->
        {k, generate(v)}
      end)

    %{
      "type" => "object",
      "properties" => properties,
      "required" => Map.keys(properties) |> Enum.sort()
    }
  end

  def generate(data) when is_list(data) do
    items_schema =
      case Enum.uniq_by(data, &generate/1) do
        # Default for empty array
        [] ->
          %{"type" => "string"}

        # All items have same schema
        [single_item] ->
          generate(single_item)

        mixed_items ->
          # Mixed schemas, use anyOf to allow overlaps (e.g. integer vs number)
          schemas = Enum.map(mixed_items, &generate/1)
          %{"anyOf" => schemas}
      end

    %{
      "type" => "array",
      "items" => items_schema
    }
  end

  def generate(data) when is_binary(data), do: %{"type" => "string"}
  def generate(data) when is_integer(data), do: %{"type" => "integer"}
  def generate(data) when is_float(data), do: %{"type" => "number"}
  def generate(data) when is_boolean(data), do: %{"type" => "boolean"}
  def generate(nil), do: %{"type" => "null"}
  # Fallback for unknown
  def generate(_), do: %{"type" => "string"}
end
