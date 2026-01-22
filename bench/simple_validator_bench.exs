
# Usage: mix run bench/simple_validator_bench.exs

# Define a schema with a pattern constraint inside an array
schema = %{
  "type" => "array",
  "items" => %{
    "type" => "string",
    "pattern" => "^[a-z0-9]+$"
  }
}

# Generate a large dataset
data = for _ <- 1..1000, do: "teststring123"

Benchee.run(%{
  "validate_large_array" => fn -> JSONSchemaEditor.SimpleValidator.validate(schema, data) end
}, time: 3, memory_time: 1)
