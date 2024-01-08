local typedefs = require "kong.db.schema.typedefs"

local PLUGIN_NAME = "ssk-detecthandling"

local type_header = {
	type = "record",
        fields = {
		{ key = { type = "string" }},
		{ value = { type = "string" }}, 
	}
}

local type_header_array = {
        type = "array",
        elements = type_header,
}

local type_filter = {
	type = "record",
        fields = {
		{ default = { type = "boolean" }},
                { tag = { type = "string" }},  
		{ status = { type = "number" }},  
                { headers = type_header_array },
                { body = { type = "string" }},  
	}
}

local type_filter_array = {
        type = "array",
        elements = type_filter,		
}

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
		{ filters = type_filter_array },
	},
        entity_checks = {
          -- add some validation rules across fields
        },
      },
    },
  },
}

return schema
