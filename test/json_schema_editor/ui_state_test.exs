defmodule JSONSchemaEditor.UIStateTest do
  use ExUnit.Case, async: true
  alias JSONSchemaEditor.UIState

  describe "get_ordered_keys/3" do
    test "returns alphabetically sorted keys when no order is stored" do
      ui_state = %{}
      path = ["root"]
      properties = %{"b" => 1, "a" => 2, "c" => 3}

      assert UIState.get_ordered_keys(ui_state, path, properties) == ["a", "b", "c"]
    end

    test "respects stored order" do
      path = ["root"]
      path_str = JSON.encode!(path)
      ui_state = %{"property_order:#{path_str}" => ["b", "c", "a"]}
      properties = %{"b" => 1, "a" => 2, "c" => 3}

      assert UIState.get_ordered_keys(ui_state, path, properties) == ["b", "c", "a"]
    end

    test "filters out stored keys that no longer exist in properties" do
      path = ["root"]
      path_str = JSON.encode!(path)
      # "d" is in order but not in properties
      ui_state = %{"property_order:#{path_str}" => ["b", "d", "a"]}
      properties = %{"b" => 1, "a" => 2}

      assert UIState.get_ordered_keys(ui_state, path, properties) == ["b", "a"]
    end

    test "appends new keys not in stored order (sorted alphabetically)" do
      path = ["root"]
      path_str = JSON.encode!(path)
      ui_state = %{"property_order:#{path_str}" => ["c", "a"]}
      # "b" and "d" are new
      properties = %{"a" => 1, "b" => 2, "c" => 3, "d" => 4}

      # Expected: stored keys ["c", "a"] + sorted new keys ["b", "d"]
      assert UIState.get_ordered_keys(ui_state, path, properties) == ["c", "a", "b", "d"]
    end
  end

  describe "add_property/4" do
    test "initializes order if missing and appends new key" do
      ui_state = %{}
      path = ["root"]
      path_str = JSON.encode!(path)
      # existing properties before add
      properties = %{"a" => 1, "c" => 3}
      new_key = "b"

      new_state = UIState.add_property(ui_state, path, properties, new_key)

      # Should initialize with sorted existing keys ["a", "c"] then append "b" -> ["a", "c", "b"]
      expected_order = ["a", "c", "b"]
      assert new_state["property_order:#{path_str}"] == expected_order
    end

    test "appends to existing order" do
      path = ["root"]
      path_str = JSON.encode!(path)
      ui_state = %{"property_order:#{path_str}" => ["c", "a"]}
      properties = %{"a" => 1, "c" => 3}
      new_key = "b"

      new_state = UIState.add_property(ui_state, path, properties, new_key)

      assert new_state["property_order:#{path_str}"] == ["c", "a", "b"]
    end

    test "handles path as string (pre-encoded)" do
      path_str = "[\"root\"]"
      ui_state = %{}
      properties = %{"a" => 1}
      new_key = "b"

      new_state = UIState.add_property(ui_state, path_str, properties, new_key)

      assert new_state["property_order:#{path_str}"] == ["a", "b"]
    end
  end

  describe "remove_property/3" do
    test "removes key from existing order" do
      path = ["root"]
      path_str = JSON.encode!(path)
      ui_state = %{"property_order:#{path_str}" => ["a", "b", "c"]}

      new_state = UIState.remove_property(ui_state, path, "b")

      assert new_state["property_order:#{path_str}"] == ["a", "c"]
    end

    test "does nothing if order does not exist" do
      path = ["root"]
      ui_state = %{}

      new_state = UIState.remove_property(ui_state, path, "b")

      assert new_state == %{}
    end
  end

  describe "rename_property/5" do
    test "renames key in place in existing order" do
      path = ["root"]
      path_str = JSON.encode!(path)
      ui_state = %{"property_order:#{path_str}" => ["a", "b", "c"]}
      properties = %{"a" => 1, "b" => 2, "c" => 3}

      new_state = UIState.rename_property(ui_state, path, properties, "b", "new_b")

      assert new_state["property_order:#{path_str}"] == ["a", "new_b", "c"]
    end

    test "initializes order if missing and performs rename" do
      path = ["root"]
      path_str = JSON.encode!(path)
      ui_state = %{}
      # Existing properties including the old key
      properties = %{"a" => 1, "b" => 2, "c" => 3}

      new_state = UIState.rename_property(ui_state, path, properties, "b", "new_b")

      # Initial order would be ["a", "b", "c"], then rename "b" -> "new_b"
      assert new_state["property_order:#{path_str}"] == ["a", "new_b", "c"]
    end
  end
end
