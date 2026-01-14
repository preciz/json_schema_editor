defmodule JSONSchemaEditor.PrettyPrinter do
  @moduledoc """
  A simple, custom JSON pretty printer for the JSON Schema Editor.
  Handles maps, lists, and primitive types with configurable indentation.
  """

  @indent_size 2

  @doc """
  Formats a map or list as a pretty-printed JSON string.
  """
  def format(data) do
    do_format(data, 0)
  end

  defp do_format(data, level) when is_map(data) do
    if Enum.empty?(data) do
      "{}"
    else
      indent = String.duplicate(" ", level * @indent_size)
      inner_indent = String.duplicate(" ", (level + 1) * @indent_size)

      entries =
        data
        # Sort keys for consistent output
        |> Enum.sort_by(fn {k, _v} -> k end)
        |> Enum.map(fn {k, v} ->
          "#{inner_indent}\"#{k}\": #{do_format(v, level + 1)}"
        end)
        |> Enum.join(",\n")

      "{\n#{entries}\n#{indent}}"
    end
  end

  defp do_format(data, level) when is_list(data) do
    if Enum.empty?(data) do
      "[]"
    else
      indent = String.duplicate(" ", level * @indent_size)
      inner_indent = String.duplicate(" ", (level + 1) * @indent_size)

      items =
        data
        |> Enum.map(fn item ->
          "#{inner_indent}#{do_format(item, level + 1)}"
        end)
        |> Enum.join(",\n")

      "[\n#{items}\n#{indent}]"
    end
  end

  defp do_format(data, _level) when is_binary(data) do
    "\"#{data}\""
  end

  defp do_format(data, _level) when is_boolean(data) do
    to_string(data)
  end

  defp do_format(nil, _level), do: "null"

  defp do_format(data, _level) when is_number(data) do
    to_string(data)
  end

  defp do_format(data, _level) do
    # Fallback for other types, inspect generally produces valid representations for atoms etc.
    inspect(data)
  end
end
