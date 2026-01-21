defmodule JSONSchemaEditor.Viewer do
  @moduledoc """
  A component for displaying JSON with syntax highlighting.
  """
  use Phoenix.Component
  alias JSONSchemaEditor.PrettyPrinter

  attr :json, :any,
    required: true,
    doc: "The JSON data to display (map, list, or already encoded string)"

  attr :class, :string, default: nil, doc: "Additional CSS classes for the container"
  attr :rest, :global, doc: "Additional HTML attributes"

  def render(assigns) do
    ~H"""
    <div class={["jse-host", @class]} {@rest}>
      <div class="jse-viewer-container">
        <pre class="jse-code-block"><code>{PrettyPrinter.format(@json)}</code></pre>
      </div>
    </div>
    """
  end
end
