local typedefs = require "kong.db.schema.typedefs"

local PLUGIN_NAME = "ssk-safehost"

local type_string = { type = "string" }

local schema = {
  name = PLUGIN_NAME,
  fields = {
    -- the 'fields' array is the top-level entry with fields defined by Kong
    { consumer = typedefs.no_consumer },  -- this plugin cannot be configured on a consumer (typical for auth plugins)
    { protocols = typedefs.protocols_http },
    { config = {
        -- The 'config' record is the custom part of the plugin schema
        type = "record",
        fields = {
		{ host_check = type_string },
	},
        entity_checks = {
          -- add some validation rules across fields
        },
      },
    },
  },
}

return schema
