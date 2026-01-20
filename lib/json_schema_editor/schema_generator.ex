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
      if data == [] do
        %{"type" => "string"}
      else
        # Infer from the first item for simplicity
        generate(hd(data))
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
  # Fallback for null
  def generate(nil), do: %{"type" => "string"}
  # Fallback for unknown
  def generate(_), do: %{"type" => "string"}
end
