defmodule JSONSchemaEditor.SchemaGeneratorPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias JSONSchemaEditor.{SchemaGenerator, Validator}

  # Use the same data generator as in other tests, or a variation
  def json_data do
    tree(simple_json_data(), fn complex ->
      one_of([
        list_of(complex),
        map_of(string(:printable), complex)
      ])
    end)
  end

  def simple_json_data do
    one_of([
      string(:printable),
      integer(),
      float(),
      boolean(),
      constant(nil)
    ])
  end

  property "generated schema is always a valid JSON Schema" do
    check all(data <- json_data()) do
      schema = SchemaGenerator.generate(data)

      # The Validator.validate_schema checks for structural validity of the schema itself
      # e.g. min <= max, etc.
      errors = Validator.validate_schema(schema)

      assert errors == %{},
             "Generated schema was invalid: #{inspect(errors)}\nSchema: #{inspect(schema)}"
    end
  end
end
