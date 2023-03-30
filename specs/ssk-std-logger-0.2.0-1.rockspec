package = "ssk-std-logger"
version = "0.2.0-1"
source = {
	url = "https://github.com/cybersecuritycloud/sasanka-proto.git"
}
description = {
   summary = "Kong plugins for API security developed by CyberSecurityCloud",
   homepage = "https:///www.cscloud.co.jp/",
   license = "Apache2.0"
}
dependencies = {
   "lua ~> 5.3"
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
      ["kong.plugins.ssk-std-logger.daos"] = "kong/plugins/ssk-std-logger/daos.lua",
      ["kong.plugins.ssk-std-logger.handler"] = "kong/plugins/ssk-std-logger/handler.lua",
      ["kong.plugins.ssk-std-logger.schema"] = "kong/plugins/ssk-std-logger/schema.lua"
   }
}
