Application.put_env(:json_schema_editor, JSONSchemaEditor.TestEndpoint,
  url: [host: "localhost"],
  secret_key_base: "Hu4qKL12Yy1+M9vcueksEda2Yy1+M9vcueksEda2Yy1+M9vcueksEda2",
  live_view: [signing_salt: "Hu4qKL12Yy1+M9vcueksEda2Yy1+M9vcueksEda2Yy1+M9vcueksEda2"],
  check_origin: false
)

defmodule JSONSchemaEditor.TestEndpoint do
  use Phoenix.Endpoint, otp_app: :json_schema_editor

  socket "/live", Phoenix.LiveView.Socket
end

JSONSchemaEditor.TestEndpoint.start_link()
ExUnit.start()
