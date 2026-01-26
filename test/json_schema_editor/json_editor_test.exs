defmodule JSONSchemaEditor.JSONEditorTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  @endpoint JSONSchemaEditor.TestEndpoint

  defmodule TestLive do
    use Phoenix.LiveView

    def mount(_params, session, socket) do
      socket =
        assign(socket, json: %{"key" => "value"}, schema: nil, test_pid: session["test_pid"])

      {:ok, socket}
    end

    def handle_event("update_data", %{"json" => json}, socket) do
      {:noreply, assign(socket, json: json)}
    end

    def handle_event("update_schema", %{"schema" => schema}, socket) do
      {:noreply, assign(socket, schema: schema)}
    end

    def render(assigns) do
      ~H"""
      <.live_component
        module={JSONSchemaEditor.JSONEditor}
        id="json-editor"
        json={@json}
        schema={@schema}
        on_save={fn val -> if @test_pid, do: send(@test_pid, {:save, val}) end}
      />
      """
    end
  end

  test "renders json editor with initial data" do
    {:ok, view, _html} = live_isolated(build_conn(), TestLive)

    assert has_element?(view, "input[value='key']")
    assert has_element?(view, "input[value='value']")
  end

  test "switches tabs" do
    {:ok, view, _html} = live_isolated(build_conn(), TestLive)

    assert has_element?(view, ".jse-tab-btn.active", "Editor")

    # Click Preview
    view
    |> element("button", "Preview")
    |> render_click()

    assert has_element?(view, ".jse-tab-btn.active", "Preview")
    # Viewer rendered
    assert has_element?(view, ".jse-preview-content")

    # Click Editor back
    view
    |> element("button", "Editor")
    |> render_click()

    assert has_element?(view, ".jse-tab-btn.active", "Editor")
  end

  test "schema tab appears when schema is present" do
    {:ok, view, _html} = live_isolated(build_conn(), TestLive)

    refute has_element?(view, "button", "Schema")

    # Update with schema
    view
    |> render_hook("update_schema", %{"schema" => %{"type" => "object"}})

    assert has_element?(view, "button", "Schema")

    view
    |> element("button", "Schema")
    |> render_click()

    assert has_element?(view, ".jse-tab-btn.active", "Schema")
  end

  test "updates string value" do
    {:ok, view, _html} = live_isolated(build_conn(), TestLive)

    view
    |> element("input[value='value']")
    |> render_blur(%{"value" => "new_value"})

    assert has_element?(view, "input[value='new_value']")
  end

  test "updates number value" do
    {:ok, view, _html} = live_isolated(build_conn(), TestLive)

    view |> render_hook("update_data", %{"json" => %{"num" => 123}})

    assert has_element?(view, "input[value='123']")

    view
    |> element("input[value='123']")
    |> render_blur(%{"value" => "456"})

    assert has_element?(view, "input[value='456']")
  end

  test "updates boolean value" do
    {:ok, view, _html} = live_isolated(build_conn(), TestLive)

    view |> render_hook("update_data", %{"json" => %{"bool" => true}})

    assert has_element?(view, "option[selected]", "true")

    # Manually pass hidden params as they might not be picked up from select in test
    params = %{"value" => "false", "path" => "[\"bool\"]", "type" => "boolean"}

    view
    |> element("select.jse-value-input")
    |> render_change(params)

    assert has_element?(view, "option[selected]", "false")
  end

  test "updates key" do
    {:ok, view, _html} = live_isolated(build_conn(), TestLive)

    view
    |> element(".jse-key-input[value='key']")
    |> render_blur(%{"value" => "new_key"})

    assert has_element?(view, "input[value='new_key']")
    # Value should persist
    assert has_element?(view, "input[value='value']")
  end

  test "adds property to object" do
    {:ok, view, _html} = live_isolated(build_conn(), TestLive)

    view
    |> element("button[title='Add Property']")
    |> render_click()

    assert has_element?(view, "input[value='newKey']")
  end

  test "deletes property from object" do
    {:ok, view, _html} = live_isolated(build_conn(), TestLive)

    view
    |> element("button[title='Delete']")
    |> render_click()

    refute has_element?(view, "input[value='value']")
  end

  test "adds item to array" do
    {:ok, view, _html} = live_isolated(build_conn(), TestLive)
    view |> render_hook("update_data", %{"json" => ["item1"]})

    assert has_element?(view, "input[value='item1']")

    view
    |> element("button[title='Add Item']")
    |> render_click()

    # Should have a new empty (null) item, rendered as span "null"
    assert has_element?(view, ".jse-val-null", "null")
  end

  test "deletes item from array" do
    {:ok, view, _html} = live_isolated(build_conn(), TestLive)
    view |> render_hook("update_data", %{"json" => ["item1", "item2"]})

    assert has_element?(view, "input[value='item1']")
    assert has_element?(view, "input[value='item2']")

    # Delete first item
    view
    # First one
    |> element("button[title='Delete'][phx-value-index='0']")
    |> render_click()

    refute has_element?(view, "input[value='item1']")
    assert has_element?(view, "input[value='item2']")
  end

  test "changes value type (string -> number -> boolean -> null -> object -> array)" do
    {:ok, view, _html} = live_isolated(build_conn(), TestLive)

    # String to Number (casting)
    view |> render_hook("update_data", %{"json" => "123"})

    # Path is [] for root
    view
    |> form("form[phx-change='change_value_type']", %{"value" => "number", "path" => "[]"})
    |> render_change()

    assert has_element?(view, "input[type='number'][value='123']")

    # Number to Boolean
    view
    |> form("form[phx-change='change_value_type']", %{"value" => "boolean", "path" => "[]"})
    |> render_change()

    # Boolean is a select
    assert has_element?(view, "select")

    # Boolean to Null
    view
    |> form("form[phx-change='change_value_type']", %{"value" => "null", "path" => "[]"})
    |> render_change()

    assert has_element?(view, ".jse-val-null", "null")

    # Null to Object
    view
    |> form("form[phx-change='change_value_type']", %{"value" => "object", "path" => "[]"})
    |> render_change()

    # {}
    assert has_element?(view, ".jse-meta", "0 items")

    # Object to Array
    view
    |> form("form[phx-change='change_value_type']", %{"value" => "array", "path" => "[]"})
    |> render_change()

    # []
    assert has_element?(view, ".jse-meta", "0 items")
  end

  test "toggles collapse" do
    {:ok, view, _html} = live_isolated(build_conn(), TestLive)
    view |> render_hook("update_data", %{"json" => %{"nested" => %{"a" => 1}}})

    assert has_element?(view, "input[value='nested']")
    assert has_element?(view, "input[value='a']")

    # Toggle collapse on 'nested'
    view
    |> element("button.jse-tree-toggle[phx-value-path*='nested']")
    |> render_click()

    # Should be collapsed now, so "a" should not be visible
    refute has_element?(view, "input[value='a']")

    # Toggle back
    view
    |> element("button.jse-tree-toggle[phx-value-path*='nested']")
    |> render_click()

    assert has_element?(view, "input[value='a']")
  end

  test "multiline editor" do
    {:ok, view, _html} = live_isolated(build_conn(), TestLive)
    multiline_text = "Line1\nLine2"
    view |> render_hook("update_data", %{"json" => multiline_text})

    assert has_element?(view, ".jse-multiline-preview")

    # Open editor
    view
    |> element("button[title='Edit (Multiline)']")
    |> render_click()

    assert has_element?(view, ".jse-modal-title", "Edit Value")
    # Assert presence first
    assert has_element?(view, "textarea")
    # Check value via HTML (more robust against whitespace normalization quirks in has_element?)
    assert render(view) =~ "Line1\nLine2"

    # Save change
    view
    |> form("form[phx-submit='save_expanded_value']", %{"value" => "Updated\nText"})
    |> render_submit()

    # Modal closed
    refute has_element?(view, ".jse-modal-title")
    # Preview might show spaces
    assert render(view) =~ "Updated Text"
  end

  test "multiline editor close" do
    {:ok, view, _html} = live_isolated(build_conn(), TestLive)
    view |> render_hook("update_data", %{"json" => "Line1\nLine2"})

    view |> element("button[title='Edit (Multiline)']") |> render_click()
    assert has_element?(view, ".jse-modal-title")

    view |> element("button", "Cancel") |> render_click()
    refute has_element?(view, ".jse-modal-title")
  end

  test "triggers on_save" do
    {:ok, view, _html} = live_isolated(build_conn(), TestLive, session: %{"test_pid" => self()})

    view
    |> element("button", "Save")
    |> render_click()

    assert_receive {:save, %{"key" => "value"}}
  end

  test "shows validation errors" do
    {:ok, view, _html} = live_isolated(build_conn(), TestLive)

    schema = %{
      "type" => "object",
      "properties" => %{
        "age" => %{"type" => "integer", "minimum" => 0}
      }
    }

    data = %{"age" => -5}

    view |> render_hook("update_schema", %{"schema" => schema})
    view |> render_hook("update_data", %{"json" => data})

    assert has_element?(view, ".jse-badge-error", "Invalid")
    assert has_element?(view, ".jse-validation-msg", "Must be >= 0")
  end
end
