defmodule JSONSchemaEditor.PrettyPrinter do
  @moduledoc false

  @indent_size 2

  def format(data) do
    data =
      if is_binary(data) do
        case JSON.decode(data) do
          {:ok, decoded} -> decoded
          _ -> data
        end
      else
        data
      end

    data
    |> do_format(0)
    |> Phoenix.HTML.raw()
  end

  defp do_format(data, level) when is_map(data) do
    if Enum.empty?(data) do
      punc("{}")
    else
      indent = render_indent(level)
      inner_indent = render_indent(level + 1)

      entries =
        data
        # Sort keys for consistent output
        |> Enum.sort_by(fn {k, _v} -> k end)
        |> Enum.map(fn {k, v} ->
          key_html = ~s(<span class="jse-key">#{encode_string(k)}</span>)
          "#{inner_indent}#{key_html}#{punc(":")} #{do_format(v, level + 1)}"
        end)
        |> Enum.join("#{punc(",")}\n")

      "#{punc("{")}\n#{entries}\n#{indent}#{punc("}")}"
    end
  end

  defp do_format(data, level) when is_list(data) do
    if Enum.empty?(data) do
      punc("[]")
    else
      indent = render_indent(level)
      inner_indent = render_indent(level + 1)

      items =
        data
        |> Enum.map(fn item ->
          "#{inner_indent}#{do_format(item, level + 1)}"
        end)
        |> Enum.join("#{punc(",")}\n")

      "#{punc("[")}\n#{items}\n#{indent}#{punc("]")}"
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

  defp render_indent(level) when level > 0 do
    for _ <- 1..level, into: "" do
      ~s(<span class="jse-indent-guide">#{String.duplicate(" ", @indent_size)}</span>)
    end
  end

  defp render_indent(_), do: ""

  defp punc(text), do: ~s(<span class="jse-punctuation">#{text}</span>)

  defp encode_string(s) do
    s
    |> JSON.encode!()
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end
end
