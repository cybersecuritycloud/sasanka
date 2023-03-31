package = "ssk-detecthandling"
version = "0.2.0-1"
source = {
	url = "https://github.com/cybersecuritycloud/sasanka.git"
}
description = {
   summary = "Kong plugins for API security developed by CyberSecurityCloud",
   homepage = "https:///www.cscloud.co.jp/",
   license = "Apache2.0"
}
build = {
   type = "builtin",
   modules = {
      ["kong.plugins.ssk-core.common"] = "kong/plugins/ssk-core/common.lua",
      ["kong.plugins.ssk-core.core"] = "kong/plugins/ssk-core/core.lua",
      ["kong.plugins.ssk-core.lib.matcher"] = "kong/plugins/ssk-core/lib/matcher.lua",
      ["kong.plugins.ssk-core.lib.utils"] = "kong/plugins/ssk-core/lib/utils.lua",
      ["kong.plugins.ssk-core.params"] = "kong/plugins/ssk-core/params.lua",
      ["kong.plugins.ssk-core.request"] = "kong/plugins/ssk-core/request.lua",
      ["kong.plugins.ssk-core.response"] = "kong/plugins/ssk-core/response.lua",
      ["kong.plugins.ssk-detecthandling.daos"] = "kong/plugins/ssk-detecthandling/daos.lua",
      ["kong.plugins.ssk-detecthandling.handler"] = "kong/plugins/ssk-detecthandling/handler.lua",
      ["kong.plugins.ssk-detecthandling.schema"] = "kong/plugins/ssk-detecthandling/schema.lua"
   }
}
