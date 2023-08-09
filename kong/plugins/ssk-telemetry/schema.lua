local typedefs = require "kong.db.schema.typedefs"

local PLUGIN_NAME = "ssk-telemetry"

local schema = {
  name = PLUGIN_NAME,
  fields = {
    -- global plugin only
    { consumer = typedefs.no_consumer },
    { service = typedefs.no_service },
    { route = typedefs.no_route },
    { protocols = typedefs.protocols_http },
    { config = {
        -- The 'config' record is the custom part of the plugin schema
        type = "record",
        fields = {
		{ std = { type = "string", one_of = { "out", "err" },  default = "out" }},
		{ tag = { type = "string" }},
		{ header = { type = "string" }},
	},
        entity_checks = {
          -- add some validation rules across fields
        },
      },
    },
  },
}

return schema
