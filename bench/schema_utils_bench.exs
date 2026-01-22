
# Usage: mix run bench/schema_utils_bench.exs

alias JSONSchemaEditor.SchemaUtils

# Deeply nested map
deep_map = Enum.reduce(1..100, "val", fn i, acc -> %{i => acc} end)
path_map = Enum.map(100..1, &(&1))

# Deeply nested list
deep_list = Enum.reduce(1..100, "val", fn _, acc -> [acc] end)
path_list = List.duplicate(0, 100)

Benchee.run(%{
  "update_deep_map" => fn -> 
    SchemaUtils.update_in_path(deep_map, path_map, fn _ -> "new_val" end) 
  end,
  "update_deep_list" => fn -> 
    SchemaUtils.update_in_path(deep_list, path_list, fn _ -> "new_val" end) 
  end
}, time: 3, memory_time: 1)
