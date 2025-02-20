![logo](img/logo_noclear.png)

# 概要

Kong Gatewayの更なるセキュリティ向上のためAPI Security機能をGatewayに追加するためのKongプラグイン。

いくつかのプラグインをOSSで提供し、ユーザーの選択により必要な機能を追加することが可能。

---

# 機能

| Plugin Name | Function | Description |
| --- | --- | --- |
| ssk-pm | Pattern Match | 読み込んだパターンルールに対してのマッチを行い検知する。 |
| ssk-safehost | Host Check | セットされたHostと実際のHostを照合、検知する。 |
| ssk-cors | CORS Check | 設定に基づきCORS関連HeaderのOrigin等をチェックし、検知する。 |
| ssk-detecthandling | Detect Handling | 検知が行われた場合のresponse status,header, bodyを設定する。 |
| ssk-std-logger | Output Detect Log | 検知が行われた場合のログを標準出力or標準エラー出力する。 |
| ssk-ua-filter | Filter by Any User-Agent | 設定した任意のUAを持つリクエストをブロックします。また、UAを持たないリクエストをブロックすることもできます。 |
| ssk-libinjection | Detect Using Libinjection | Libinjectionを活用して正規表現からではなくSQL構文を解析して攻撃を検知します。 |
| ssk-clickjacking | Prevent Clickjacking | Clickjackingを防ぎます。 |
| ssk-saferedirect | Strict Redirection | 許可リスト方式でリダイレクト先を制限します。 |
| ssk-strictparameter | Strict and Validate Parameters | パラメータの型や値域を制限することができます。 |
| ssk-telemetry | Output Telemetry | 標準出力or標準エラー出力にレイテンシやリクエストカウントなどのメトリクスを出力します。 |
| ssk-allowkey | Restrict parameter containing any key | 各パラメータのkeyをホワイトリスト形式で制限します。このPluginはOWASP Top10のMassAssignmentの防止になります。 |
| ssk-magika | MIME type validation with magika | [magika](https://github.com/google/magika)を使用したファイルの MIME タイプ検証を行います|

このPlugin はDB-lessモードでは**動作しません**。

上記から必要なものを選択してKong Pluginとして活用できます。

---

# インストールと始め方

## Requirements

Kongのインストールは[こちら](https://docs.konghq.com/gateway/2.8.x/install-and-run/)を確認してください。

### Related KONG

- KONG(=3.1.0)
- postgresql
- Lua ≥ 5.1
- luarocks

### Mention

このPluginはカスタムPluginのため、Kongをソースからインストールする必要があります。

### Additional

- pcre2
    - pcre2は必須ではありませんが、パフォーマンス向上のためインストールを推奨します。
    
    [http://openresty.org/misc/re/bench/](http://openresty.org/misc/re/bench/)
    

以下を参考にインストールしてください。

```bash
# install dependency
sudo apt-get install -y libpcre2-dev
sudo luarocks install lrexlib-pcre2 
```

- libinjection

## Install Plugins in Kong Gateway

```bash
git clone https://github.com/cybersecuritycloud/sasanka.git
cd sasanka
luarocks install rocks/${PLUGIN_NAME}${VERSIONS}.all.rock
```

そして`kong.conf`のpluginsに下記を追加して、Kongを再起動します。

```bash
plugins = bundled,ssk-detecthandling,ssk-safehost,ssk-pm,ssk-cors,ssk-std-logger,ssk-ua-filter,ssk-optimizer,ssk-libinjection,ssk-saferedirect,ssk-clickjacking,ssk-strictparameter,ssk-response-transform,ssk-telemetry
```

luarocksでのインストールがうまくいかない場合は、直接kongの使用しているディレクトリ配下にコピーすることでもインストール可能です。

---

# 使用方法

`SERVICE_NAME|SERVICE_ID` は、Pluginを設定する対象のサービス名, idと置き換えてください。

Routeに設定する場合は、`SERVICE_NAME|SERVICE_ID`を`ROUTE_NAME|ROUTE_ID`に読み替えてください。

localhost, 8081はそれぞれAdminHost, AdminPortと読み替えてください。

### ssk-pm

設定で読み込んだパターンに対してパターンマッチを行う。

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
| config.patterns | array of table elements | 設定するパターンとその名前を定義します。 | - | table |
| config.patterns[i].name | string | 設定するパターンの名前を定義します。 | - | nil |
| config.patterns[i].patterns | array of string elements | パターンを配列で設定します。 | - | nil |
| config.params | array of table elements | 設定したパターンの適用場所を定義します。 | - | table |
| config.params[i].in | string | <b>非推奨</b>。検知をかける項目を定義します。[”param_req_query”, “param_req_path”, “param_req_body”]の中から選択するか、”*” or nullだと全てのparamが適用されます。 | - | nil |
| config.params[i].key | string | <b>非推奨</b>。検知をかけるparameter keyを定義します。”*”か null だと全てのparameter keyが適用されます。 | - | nil |
| config.params[i].patterns | array of string elements | config.patternsで定義したpatternのうち、適用するパターンを定義します。 | - | nil |
| config.params[i].customize | table elements | Define the pattern to be applied among the patterns defined in config.patterns. | - | nil |
| config.params[i].customize.in | array of string | 検知をかける項目を定義します。[”param_req_query”, “param_req_path”, “param_req_body”]の中から選択するか、[”*”] or nullだと全てのparamが適用されます。| - | nil |
| config.params[i].customize.key | array of string | 検知をかけるparameter keyを定義します。[”*”]か null だと全てのparameter keyが適用されます。 | - | nil |
| config.params[i].customize.tags | array of string | patternsにtagsを設定します。ここで設定したtagはssk-detecthandling等で使用されます | - | nil |


 customizeフィールドはそこに指定されたpatternsに対して、patternsごとに対象箇所やtagsを細かく調整するためのフィールドになります

### ssk-safehost

設定したhostと実際のupstreamのhostを照合する。

ここで意味するhostはhost headerのvalueに値するので、正しくはFQDN。

Enable on Service

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
| config.tags | array of string | Pluginにtagsを設定します。ここで設定したtagはssk-detecthandling等で使用されます。 | - | [] |
| config.host_check | string | upstreamのhost名を設定します。デフォルトではport:80が設定されますが、upstreamのportが80以外の場合は、portも含めて設定が必要です。 | true | nil |

### ssk-cors

CORSに関する検知を行う。

modify_response_header=true の際、検知した時のresponse headerが修正される。

Enable on Service

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
| config.tags | array of string | Pluginにtagsを設定します。ここで設定したtagはssk-detecthandling等で使用されます。 | - | [] |
| config.block | boolean | 検知が行われた場合に、requestをブロックするか設定します。 | true |  |
| config.modify_response_header | boolean | 検知、ブロックが行われた場合にresponse headerを修正するか設定します。 | - | nil |
| config.allow_origins | array of string elements | 許可するoriginを定義します。”*” or null の場合は全て許可しません。modify_response_header is true の場合、Headerに Access-Control-Allow-Origin: 設定値 を追加します。 | - | nil |
| config.allow_methods | array of string elements | 許可するmethodを定義します。”*”は全て許可します。modify_response_header is true の場合、Headerに Access-Control-Allow-Headers: 設定値 を追加します。 | - | nil |
| config.allow_headers | array of string elements | 許可するheaderを定義します。”*”は全て許可します。modify_response_header is true の場合、Headerに Access-Control-Allow-Headers: 設定値 を追加します。 | - | nil |
| config.expose_headers | array of string elements | modify_response_header is true の場合、Headerに Access-Control-Expose-Headers: 設定値 を追加します。 | - | nil |
| config.allow_credentials | boolean | modify_response_header is true の場合、Headerに Access-Control-Allow-Credentials: 設定値 を追加します。 | - | nil |
| config.max_age | integer | modify_response_header is true の場合、Headerに Access-Control-Max-Age: 設定値 を追加します。 | - | nil |

### ssk-detecthandling

ssk-* Pluginで検知された場合のレスポンスをコントロールします。例えば、カスタムレスポンスを返したり、レスポンを遅延する、あるいはログを吐き出すのみに設定することができます。

Enable on Service

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
						"body" : "some error text",
						"default" : true, 
					},
					{
						"tag" : "status409",
						"status" : 409
					},
					{
						"tag" : "log"
					},
					{
						"delay": 60,
						"tag" : "delay"
					}
				]
			}
		}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.filters | array of object |  | true |  |
| config.filters[i].tag | string | プラグインが検知した際に、このtagの挙動を行います。tag以外に設定されていない場合、responseを返さず、検知したログのみを出力します。 | true |  |
| config.filters[i].status | integer | 検知した際のresponse statusを設定します。 | - |  |
| config.filters[i].headers | array of table elements | 検知した際のresponse headersをkey-value形式で設定します。 | - |  |
| config.filters[i].body | string | 検知した際のresponse body を設定します。 | - |  |
| config.filters[i].delay | integer | 検知した際にresponseを遅延します。 | - |  |
| config.filters[i].default | boolean | 検知した際のPluginのtagがこのPlugin上に存在しない場合の動作を設定します。 | - |  |

### ssk-std-logger

ssk-* Pluginで検知された場合に検知した内容を標準出力する。
log lengthの最大は8192[Byte]です

Enable on Service

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -d "name=ssk-std-logger" \
    -d "config.std=out" \
	-d "config.header=[ssk-detect]"
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.std | string | 検知ログの出力先を設定する。out or err を設定でき、標準出力または標準エラー出力で設定する。 | true | - |
| config.header | string | parsingに利用するlog headerを設定します。 | - | [ssk-detect] |
| config.encode | string | logに対して行うencodeのtypeを指定します。 |  | none |

### Default Log Format

```yaml
[header] {[route_id] [host] [remote] [tags] [details] [detect_code] [time]}
```

#### Example
```json
[header]{"route_id": "421df401-b471-4a6b-82e4-c12ea03a1780", "host": "example.com", "remote": "20.100.47.117",  "details" : {"fingerprint" : "s&1c", "decoded" : "\' or 1 = 1 -- ", "value" : "\' or 1 = 1 -- ", "key" : "somekey"}, "detect_code" : 1301, "tags" : ["libinjection", "code_401"], "time": "2024-11-13T16:58:00"}
```

### Detect code

ssk-std-loggerから出力された検知ログは以下のルールIDで管理される。

| Detect code | Detected by |
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

設定した任意のUser-Agentをブロックする。また、User-Agentを持たない or 空の場合にブロックする。

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
| config.tags | array of string | Pluginにtagsを設定します。ここで設定したtagはssk-detecthandling等で使用されます。 | - | [] |
| config.block_useragents | array | ブロックするUAのリスト。前方一致でマッチする。 | - |  |
| config.block_no_useragent | bool | UAを持たない場合にブロックするか否か。 | - | false |

### ssk-libinjection

libinjectionを用いて検知をする。

libinjectionとは、SQL injectionを検知するためのライブラリであり正規表現ではなくSQL構文を解析して検知を行う。

libinjectionを使用するにはいくつかのパッケージをインストールする必要があります。

`./install_libinjection.sh`を実行してインストールを行なってください。

使用しているlibinjectionのversionは、2023年3月時点のものとなります。

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
| config.tags | array of string | Pluginにtagsを設定します。ここで設定したtagはssk-detecthandling等で使用されます。 | - | [] |
| config.params[i].in | string | 検知を行う場所を次のうちから決定します。 ["param_req_query", "param_req_path", “param_req_header”, “param_req_cookie”,  "param_req_body", “param_req_*”, “param_res_header”, “param_res_*”].この中から選んで指定するか、’*’で全てのparamに対して検知を行います。 | - | nil |
| config.params[i].key | string | 検知を適用するkeyを指定します。* or null では全てのkeyに対して適用されます。 | - | nil |
| config.params[i].sql | bool | SQL構文解析をします | - | true |
| config.params[i].xss | bool | XSS構文解析をします | - | true |

### ssk-clickjacking

clickjackingを防ぎます。

clickjackingはWeb攻撃の一種で、偽のリンクや偽のボタンを被せることでユーザーを偽サイトへ誘導します。

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
	-d "config.name=ssk-clickjacking" \
	-d "config.tags[]=status409" \
  -d "config.policy=DENY"
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.policy | string | “DENY” or “SAMEORIGIN”から選べます。 | - | DENY |
| config.tags | array of string | Pluginにtagsを設定します。ここで設定したtagはssk-detecthandling等で使用されます。 | - | [] |

### ssk-saferedirect

リダイレクトを制限します。設定されたprefixとマッチしたhostのみリダイレクトが許可されます。

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -H "Content-Type: application/json" \
    -d '{
			"name": "ssk-saferedirect",
			"config": {
				"tags": ["log"],
				"params": [ 
					{ "in": "param_req_body",  "key": "redirect", "prefix": "http://my-redirect/api/" } 
					]
				}
			}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.tags | array of string | Pluginにtagsを設定します。ここで設定したtagはssk-detecthandling等で使用されます。 | - | [] |
| config.params[].in | string | 検知を有効にするparamを["param_req_query", “param_req_body” ]の中から一つ選びます。 | - |  |
| config.params[].key | string | 検知を適用するkeyを選びます。* or nullは使用できません。 |  |  |
| config.params[].prefix | string | リダイレクトを許可するhostのprefixを指定します。 |  |  |

### ssk-strictparameter

指定したパラメータの型、値域を制限します。

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -H "Content-Type: application/json" \
    -d '{
			"name": "ssk-strictparameter",
			"config": {
				"tags": ["status409"]
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
| config.tags | array of string | Pluginにtagsを設定します。ここで設定したtagはssk-detecthandling等で使用されます。 | - | [] |
| config.params[].in | string | 適用する項目を["param_req_query", "param_req_path", “param_req_body”, ]のうちから選択します。 | true |  |
| config.params[].key | string | 適用するkeyを指定します。 | true |  |
| config.params[].type | string | 次のうちから選択します。boolean, integer, number, date, date-time, string, uuid, regex | true |  |
| config.params[].required | bool | このkeyが必ず必要かを指定します。 | - | false |
| config.params[].pattern | string | typeがregexの時のみ有効。regexのpatternを指定します。 | - |  |
| config.params[].min | int | typeがinteger, numberの場合、最小値を指定します。文字列の場合は、文字数をの最小値を指定します。 | - |  |
| config.params[].max | int | typeがinteger, numberの場合、最大値を指定します。文字列の場合は、文字数をの最大値を指定します。 | - |  |

### ssk-telemetry

Kongで測定したtelemetryの値を出力します。

注意! このプラグインはGlobal pluginとして動作するため、Service or Routeに対して有効化することはできません。

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
| config.std | string | 出力先を out or err から選びます。 | true | “out” |
| config.tag | string | タグをつけることができます。 | - |  |
| config.header | string | 出力にヘッダをつけることができます。例えば、fluentdなどでlogを簡単に抽出することができます。 | - |  |

### ssk-allowkey

リクエストパラメータのkeyをホワイトリスト形式で制限します。

このプラグインの設定に含まれていないパラメータkeyがRequestに含まれていた場合、リクエストは検知されます。

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
| config.tags | array of string | Pluginにtagsを設定します。ここで設定したtagはssk-detecthandling等で使用されます。 | - | [] |
| config.query | array of string | 許可するqueryパラメータのkeyを設定します。このkey(query)が設定に含まれていない、またはnilの場合、全てのqueryパラメータkeyが許可されます。空リストが設定されている場合、全てのqueryパラメータのkeyが拒否されます。 | - | nil |
| config.header | array of string | 許可するheaderパラメータのkeyを設定します。このkey(header)が設定に含まれていない、またはnilの場合、全てのheaderパラメータkeyが許可されます。空リストが設定されている場合、全てのheaderパラメータのkeyが拒否されます | - | nil |
| config.cookie | array of string | 許可するcookieパラメータのkeyを設定します。このkey(cookie)が設定に含まれていない、またはnilの場合、全てのcookieパラメータkeyが許可されます。空リストが設定されている場合、全てのcookieパラメータのkeyが拒否されます | - | nil |
| config.body | array of string | 許可するbodyパラメータのkeyを設定します。このkey(body)が設定に含まれていない、またはnilの場合、全てのbodyパラメータkeyが許可されます。空リストが設定されている場合、全てのbodyパラメータのkeyが拒否されます | - | nil |


### ssk-magika
[magika](https://github.com/google/magika)を使用したファイルの MIME タイプ検証機能を実装しました。この機能により、ファイルの拡張子のみに依存せず、実際の MIME タイプを検出することで、アップロードされたファイルが想定された形式に適合していることを確認できます。

この機能は、ファイル処理プロセスのセキュリティと堅牢性を強化し、より安全で信頼性の高い運用を実現します。
magikaのラベルは[standard_v2_1](https://github.com/google/magika/blob/main/assets/models/standard_v2_1/README.md)に設定されています。

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/plugins \
    -H "Content-Type: application/json" \
    -d '{
			"name": "ssk-magika",
			"config": {
				"tags": ["magika_detected"],
				"denys" : ["txt", "html", "javascript", "png"],
				"params" : [
					{
						"in": "param_req_body",
					}
				]
			}
		}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.tags | array of string | Pluginにtagsを設定します。ここで設定したtagはssk-detecthandling等で使用されます。 | - | [] |
| config.denys | array of string | 拒否するラベルを設定します。 | true |  |
| config.allows | array of string | 許可するラベルを定義します。許可するもの以外を検知対象とする意味。 | true |  |
| config.params[].in | string |  適用する項目を次のうちから設定します。[ “param_req_body”, "req_body"] | true |  |
| config.params[].key | string | 適用するkeyを設定します。 | true |  |


---

# クイックスタート

### requirements

- Kong
    - 全てのPluginをkong.confに追加してから `kong restart` を行う必要があります。
- curl
- python3 (>=3.6)
	- pyyaml, requests

### Usage

```bash
./quickstart.sh YOUR_SERVICE_NAME_OR_ID
```

### Description

このquickstartはsasankaをdefault-settingで、即座に利用するためのものです。

### Mention

quickstartの設定をそのまま使い続けることは推奨されていません。誤検知が発生した場合には自身で設定を見直し、変更する必要があります。

---

# 著作者

株式会社サイバーセキュリティクラウド

[https://www.cscloud.co.jp/](https://www.cscloud.co.jp/)

---

# ライセンス

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