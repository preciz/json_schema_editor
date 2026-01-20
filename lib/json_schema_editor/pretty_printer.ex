defmodule JSONSchemaEditor.PrettyPrinter do
  @moduledoc false

  @indent_size 2

  def format(data) do
    data
    |> do_format(0)
    |> Phoenix.HTML.raw()
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
          key_html = ~s(<span class="jse-key">#{encode_string(k)}</span>)
          "#{inner_indent}#{key_html}: #{do_format(v, level + 1)}"
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
    ~s(<span class="jse-string">#{encode_string(data)}</span>)
  end

  defp do_format(data, _level) when is_boolean(data) do
    ~s(<span class="jse-boolean">#{to_string(data)}</span>)
  end

  defp do_format(nil, _level) do
    ~s(<span class="jse-null">null</span>)
  end

  defp do_format(data, _level) when is_number(data) do
    ~s(<span class="jse-number">#{to_string(data)}</span>)
  end

  defp do_format(data, _level) do
    # Fallback
    ~s(<span class="jse-string">#{encode_string(inspect(data))}</span>)
  end

  defp encode_string(s) do
    s
    |> JSON.encode!()
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end
end
