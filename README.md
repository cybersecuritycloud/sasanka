![logo](img/logo_noclear.png)


# Overview

Kong plugins to add WAF functionality to the Gateway to further improve the security of Kong Gateway.

Some plugins are provided as OSS, and users can choose to add the necessary functions.

---

# Features

| Plugin Name | Function | Description |
| --- | --- | --- |
| ssk-pm | Pattern Match | Detection is performed by matching against the pattern rules that have been read. |
| ssk-safehost | Host Check | Detection is performed by matching the set Host with the actual upstream Host. |
| ssk-cors | CORS Check | Detection is performed by matching the header related CORS set config. |
| ssk-detecthandling | Detect Handling | Set the response status, header, and body when detection is performed. |
| ssk-std-logger | Output Detect Log | Logs to standard output or standard error output when detection is performed. |
| ssk-ua-filter | Filter by Any User-Agent | You can set any user-agent to block. And can block no-user-agent request. |
| ssk-libinjection | Detect Using Libinjection | Using libinjection, it can detect attack by SQL syntax not regex. |
| ssk-clickjacking | Prevent Clickjacking | Prevent clicjacking attack. |
| ssk-saferedirect | Strict Redirection | Strict host to redirect by whitelist. |
| ssk-strictparameter | Strict and Validate Parameters | Validating params like JSON Schema and it can also restrict value to prevent MassAssignment for example. |
| ssk-telemetry | Output Telemetry | Output telemetry to stdout or stderr. Telemetry means metrics of latency, count |
| ssk-allowkey | Restrict parameter containing any key | Restrict each parameter containing any key to prevent MassAssignment, one of OWASP Top 10. |

These plugins are **not compatible** with DB-less mode.

You can select these of above you need and set as plugin of Kong.

---

# Install and Get Start

## Requirements

If you need help with KONG installation, see the documentation on [Install and Run KONG](https://docs.konghq.com/gateway/2.8.x/install-and-run/).

### Related KONG

If you already have KONG installed, please skip this.

- KONG(=2.8.2, 3.0.0, 3.3.0)
- postgreSQL
- Lua ≥ 5.1, 5.3
- luarocks

### Mention

This is Kong Custom plugin so you must use Kong from source. You may not use it from docker  Kong image.

### Additional

- pcre2
    - This pcre2 is not necessary. Plugins can execute without pcre2 but we recommend install pcre2 for performance.
    
    [http://openresty.org/misc/re/bench/](http://openresty.org/misc/re/bench/)
    

To install, please refer to the following.

```bash
# install dependency
sudo apt-get install -y libpcre2-dev
sudo luarocks install lrexlib-pcre2 
```

- libinjection

## Install Plugins in Kong Gateway

Execute following.

```bash
git clone https://github.com/cybersecuritycloud/sasanka.git
cd sasanka
luarocks install release/${PLUGIN_NAME}.${VERSIONS}.all.rock
```

And add your `kong.conf` ’s plugins item you want like following example. And then you must restart Kong.

```bash
plugins = bundled,ssk-detecthandling,ssk-safehost,ssk-pm,ssk-cors,ssk-std-logger,ssk-ua-filter,ssk-optimizer,ssk-libinjection,ssk-saferedirect,ssk-clickjacking,ssk-strictparameter,ssk-response-transform,ssk-telemetry,ssk-allowkey
```

If you can’t install plugins well by above, you can copy source code to kong’s directory.

---

# Usage

Following example of enable plugin is assumed to enable on Service. 

So if you want to set plugins of the route, replace `SERVICE_NAME|SERVICE_ID`with the `ROUTE_NAME|ROUTE_ID` of the route that this plugin configuration will target.

And you should replace `SERVICE_NAME|SERVICE_ID`with the `id` or `name` of the service that this plugin configuration will target. 

Replace localhost and 8081 to your Kong AdminHost and Port each other.

Almost plugins have config.tags on config field. This tags can use to handle response when detected. You can handle detected response to any custom response or you can select that request won’t be blocked and output only logs.

If you want more information, see each plugin’s schema.lua.

### ssk-pm

Pattern matching is performed for patterns read in the settings.

Enable on Service

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -H "Content-Type: application/json" \
    -d '{"name": "ssk-pm",
		"config": { "patterns" : [ {"name": "example-pattern-key", "patterns" ["aa", "bb"] } ],
		"params": [ { "in": "param_req_query",  "key": "*", "patterns": ["example-pattern-key"] } ] } 
		}'
```

**Config Parameters**

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.patterns | array of table elements | Define the pattern to be set and its name. | - | table |
| config.patterns[i].name | string | Defines the name of the pattern to be set. | - | nil |
| config.patterns[i].patterns | array of string elements | Set pattern rules as an array. | - | nil |
| config.params | array of table elements | Defines where the configured pattern will be applied. | - | table |
| config.params[i].in | string | Defines the item to apply detection to. ["param_req_query", "param_req_path", “param_req_header”, “param_req_cookie”,  "param_req_body", “param_req_*”, “param_res_header”, “param_res_*”].Select one of them or use "*" or null to apply all params. | - | nil |
| config.params[i].key | string | Define the parameter key to apply detection.If "*" or null, all parameter keys are applied. | - | nil |
| config.params[i].patterns | array of string elements | Define the pattern to be applied among the patterns defined in config.patterns. | - | nil |

### ssk-safehost

Check the configured host against the actual upstream host.

The host in this plugin means the value of host header. So it’s same as FQDN correctly.

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -H "Content-Type: application/json" \
		-d '{
			"name": "ssk-safehost", 
			"config": {
				"tags": ["status409"], 
				"host_check": "HostName.com"
		}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.tags | array of string | You can set any tags. This tag can be used for ssk-detecthandling and so on. | - | [] |
| config.host_check | string | Set the hostname of the upstream.By default, port:80 is set, but if the port is other than 80, the port must also be included. | true |  |

### ssk-cors

Detects related CORS.

When modify_response_header=true, the response header is modified when detected.

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
		-H "Content-Type: application/json" \
    -d '{
			"name": "ssk-cors", 
			"config": {
				"tags": ["log"],
				"block": true, 
				"modify_response_header": true, 
				"allow_origins": ["*"],
				"allow_methods": ["OPTIONS", "GET", "PUT"],
				"allow_headers": ["*"],
				"expose_headers": ["*"],
				"allow_credentials": false,
				"max_age": 3600
				}
		}'
```

**Config Parameters**

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.tags | array of string | You can set any tags. This tag can be used for ssk-detecthandling and so on. | - | [] |
| config.block | boolean | enable cors block | true |  |
| config.modify_response_header | boolean | Sets whether to modify the response header when a detection or block is made. | - | nil |
| config.allow_origins | array of string elements | Defines which origins are allowed."*"is ALL ARE ALLOWED. null is ALL ARE NOT ALLOWED.If modify_response_header is true, add Access-Control-Allow-Origin: configuration value to the Header. | - | nil |
| config.allow_methods | array of string elements | Defines which methods are allowed." *" allows all.If modify_response_header is true, add the Access-Control-Allow-Headers: setting to the Header. | - | nil |
| config.allow_headers | array of string elements | Defines which headers are allowed." *" allows all.If modify_response_header is true, add Access-Control-Allow-Headers: configuration value to the Header. | - | nil |
| config.expose_headers | array of string elements | If modify_response_header is true, add Access-Control-Expose-Headers: configuration value to Header. | - | nil |
| config.allow_credentials | boolean | If modify_response_header is true, add Access-Control-Allow-Credentials: configuration value to the Header. | - | nil |
| config.max_age | integer | If modify_response_header is true, add the Access-Control-Max-Age: setting value to the Header. | - | nil |

### ssk-detecthandling

Change Response to set value when detected by ssk-* Plugin.

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -H "Content-Type: application/json"\
		-d '{
				"name": "ssk-detecthandling", 
				"config": {
					"filters" : [
						{
								"tag" : "status_401",
								"status" : 401,
						     "headers" : [ 
										{"key": "CustomHeader", "value": "CustomValue" },
				            {"key": "CustomHeader2", "value" : "CustomValue2" }
				        ],
				        "body" : "some error text"
				        "default" : true, 
						},
						{
								"tag" : "status409",
								"status" : 409,
						},
						{
								"tag" : "log"
						}
					]
				}
			}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.filters | array of object |  | true |  |
| config.filters[i].tag | string | When a Plugin is detected, the response is made in accordance with the tag of the Plugin; if the tag is not set to anything other than the tag, only logging is output and no blocking is performed. | true |  |
| config.filters[i].status | integer | Sets the response status when detected. | - |  |
| config.filters[i].headers | array of table elements | Sets the response headers in key-value format when detected. | - |  |
| config.filters[i].body | string | Sets the response body when detected. | - |  |
| config.filters[i].default | boolean | When a Plugin is detected and tag of plugin is not configured on this plugin,  default is performed. | - |  |

### ssk-std-logger

Standard output of what is detected when detected by the ssk-* Plugins.

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -d "name=ssk-std-logger" \
    -d "config.std=out" \
		-d "config.header=[ssk-detect]"
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.std | string | Select out or err for where to output detected log. | true |  |
| config.header | string | You can set to specify log header. |  | [ssk-detect] |

### Default Log Format

```yaml
[header] {[plugin_id] [argument]}
```

### Log Id

The detection logs output from ssk-std-logger are managed by the following our IDs.

| Log Id | Detected by |
| --- | --- |
| 200 | ssk-pm |
| 300 | ssk-safehost |
| 400 | ssk-cors |
| 700 | ssk-ua-filter |
| 1300 | ssk-libinjection |
| 1500 | ssk-saferedirect |
| 1800 | ssk-strictparamater |
| 2500 | ssk-allowkey |

### ssk-ua-filter

Manage User-Agent to block. And it can block the request which don’t have User-Agent’s key or not empty value.

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
		-H "Content-Type: application/json" \
		-d '{
				"name": "ssk-ua-filter", 
				"config": {
					"tags": ["status409"],
					"block_useragents" : ["python/", "Powershell"], 
					"block_no_useragent" : true
					}
				}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.tags | array of string | You can set any tags. This tag can be used for ssk-detecthandling and so on. | - | [] |
| config.block_useragents | array of string | Array of User-Agent to block.
The function searches for the first match | - |  |
| config.block_no_useragent | bool | Block if User-Agent is not set. | - | false |

### ssk-libinjection

Detect using libinjection.

What is libinjection? Libinjection is the library to detect SQLinjection. To detect SQLinjection, parsing SQL syntax and detect regular pattern instead of regular expression. Comparing with way to detect between regular expression and libinjection, libinjection can detect faster and correctly.And different from regex, generally libinjection cause miss detection less because it understand SQL syntax.

You should execute install script to install required package for libinjection.

There is the install script on ./install_libinjection.sh.

Version of libinjection we’re using is as of Mar 30, 2023.

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -H "Content-Type: application/json" \
    -d '{
			"name": "ssk-libinjection",
			"config":{ 
				"tags": ["status409"],
				"params": [ 
					{ "in": "param_req_query" },
					{ "in": "param_req_body",  "key": "var", "sql": true } 
					]
				} 
			}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.tags | array of string | You can set any tags. This tag can be used for ssk-detecthandling and so on. | - | [] |
| config.params[i].in | string | Defines the item to apply detection to. ["param_req_query", "param_req_path", “param_req_header”, “param_req_cookie”,  "param_req_body", “param_req_*”, “param_res_header”, “param_res_*”].Select one of them or use "*" or null to apply all params. | - | nil |
| config.params[i].key | string | Define the parameter key to apply detection.If "*" or null, all parameter keys are applied. | - | nil |
| config.params[i].sql | bool | Parse SQL syntax | - | true |
| config.params[i].xss | bool | Parse XSS syntax | - | true |

### ssk-clickjacking

Prevent Clickjacking.

Clickjacking is an WEB attack in which a user is tricked into fake link, fake button.

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
	-d "config.name=ssk-clickjacking" \
	-d "config.tags[]=status409" \
  -d "config.policy=DENY"
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.tags | array of string | You can set any tags. This tag can be used for ssk-detecthandling and so on. | - | [] |
| config.policy | string | Select “DENY” or “SAMEORIGIN”. DENY don’t allows all rewriting iframe. | - | DENY |

### ssk-saferedirect

Restrict redirect to host. 

If prefix configured was match, allow redirect.

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -H "Content-Type: application/json" \
    -d '{
			"name": "ssk-saferedirect",
			"config": {
				"tags": ["status409"],
				"params": [ 
					{ "in": "param_req_body",  "key": "redirect", "prefix": "http://my-redirect/api/" } 
					]
				}
			}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.tags | array of string | You can set any tags. This tag can be used for ssk-detecthandling and so on. | - | [] |
| config.params[].in | string | Defines the item to apply detection to. ["param_req_query", “param_req_body” ].Select one of them | - |  |
| config.params[].key | string | Define the parameter key to apply detection. “*” is NOT enable. |  |  |
| config.params[].prefix | string | Host to match prefix allow redirect. |  |  |

### ssk-strictparameter

Restrict specific param’s type or length or numeric value range.

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -H "Content-Type: application/json" \
    -d '{
			"name": "ssk-strictparameter",
			"config": {
				"tags": ["status409"],
				"params": [
		        { "in": "param_req_query", "key": "readonly", "type": "boolean" },
		        { "in": "param_req_query", "key": "created_at", "type": "date", "min": 10, "max": 10 },
		        { "in": "param_req_query", "key": "pagenum", "type": "int", "required": true, "max": 1000},
		        { "in": "param_req_query", "key": "session_id", "type": "uuid", "min": 36, "max": 36 },
		        { "in": "param_req_query", "key": "name", "type": "regex", "pattern" : "^user-[0-9]+$", "min": 8, "max": 12 }
				  ]
				}
			}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.tags | array of string | You can set any tags. This tag can be used for ssk-detecthandling and so on. | - | [] |
| config.params[].in | string | Defines the item to apply detection to. ["param_req_query", "param_req_path", “param_req_body”, ].Select one of them | true |  |
| config.params[].key | string | Define the parameter key to apply detection. | true |  |
| config.params[].type | string | Select one of following. boolean, integer, number, date, date-time, string, uuid, regex. | true |  |
| config.params[].required | bool | Is this key always required. | - | false |
| config.params[].pattern | string | Enable if only type is regex. Set regex pattern. | - |  |
| config.params[].min | int | If type is integer or number, numeric value minimum.Otherwise minimum length as string. | - |  |
| config.params[].max | int | If type is integer or number, numeric value maximum.Otherwise maxmum length as string. | - |  |

### ssk-telemetry

Output telemetry measured by Kong.

Mention! This plugin only execute as global plugin, so it can’t be enable on service or route.

Enable on Global Example

```bash
curl -i -X POST http://localhost:8001/plugins \
    -H "Content-Type: application/json" \
    -d '{
				"name": "ssk-telemetry",
				"config": {
					"std": "out",
					"tag": "your-tag",
					"header": "[your-header]"
				}
		}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.std | string | You can select the place to output either out or err. | true | “out” |
| config.tag | string | The tag for example if you want to divide the data in endpoint. Mention! this is not same to tags. | - |  |
| config.header | string | The header of output telemetry. For example, you can pick up telemetry using fluentd by specify this header easily. | - |  |

### ssk-allowkey

Key restriction of request parameters in the form of a white list.

If the request containing any key not containing this config, request will be detected.

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/plugins \
    -H "Content-Type: application/json" \
    -d '{
				"name": "ssk-allowkey",
				"config": {
					"tags": ["hoge"],
					"query" : [ "num", "pages"],
					"body" : ["user", "date"],
					"cookie" : ["session_id", "expired"],
					"header" : ["host", "user-agent", "cookie"]
				}
		}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.tags | array of string | You can set any tags. This tag can be used for ssk-detecthandling and so on. | - | [] |
| config.query | array of string | You can set query parameter key to allow. If this key is not configured or value is nil, all query parameter key will be allowed. If value is empty array, [], all query parameter will be denied. | - | nil |
| config.header | array of string | You can set header parameter key to allow. If this key is not configured or value is nil, all header parameter key will be allowed.If value is empty array, [], all header parameter will be denied. | - | nil |
| config.cookie | array of string | You can set cookie parameter key to allow. If this key is not configured or value is nil, all cookie parameter key will be allowed.If value is empty array, [], all cookie parameter will be denied. | - | nil |
| config.body | array of string | You can set body parameter key to allow. If this key is not configured or value is nil, all body parameter key will be allowed.If value is empty array, [], all body parameter will be denied. | - | nil |

---

# Quick Start

### requirements

- Kong
    - Need to `kong restart` after adding selected plugin to plugins in kong.conf
- curl
- python3 (>=3.6)
- ( Core-Rule-Set v3.3.4 (automated Install in quickstart.sh) )

### Execute

```bash
./quickstart.sh YOUR_SERVICE_NAME_OR_ID
```

### Description

This script is to start sasanka for default-settings quickly. The default-setting is recommended by developer. And it contains builder of OWASP Core-Rule-Set, then after building it will be set to our plugin. 

### Mention

This quickstart targets to start quickly and not target to use ever. So, if misdetection is caused by it, you have to review and modify plugin’s config. 

And it doesn’t contain to start following plugins, `ssk-safehost` , `ssk-strictparameter` , `ssk-telemetry`. Because these must be set by yourself due to important content,  complexing field or unknown it’s necessary for you. 

---

# Author

CyberSecurityCloud.Inc

[https://www.cscloud.co.jp/](https://www.cscloud.co.jp/)

---

# License

```
   Copyright 2023 CyberSecurityCloud Inc.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```
---

[日本語版README](https://github.com/cybersecuritycloud/sasanka/blob/master/README.ja.md)