# README(Japanese)

# 概要

Kong Gatewayの更なるセキュリティ向上のためWAFとしての機能をGatewayに追加するためのKongプラグイン。

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
| ssk-telemetry | Output Telemetry | Output telemetry to stdout or stderr. Telemetry means metrics of latency, count |

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
luarocks install release/${PLUGIN_NAME}${VERSIONS}.all.rock
```

そして`kong.conf`のpluginsに下記を追加します。

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
| config.params[i].in | string | 検知をかける項目を定義します。[”param_req_query”, “param_req_path”, “param_req_body”]の中から選択するか、”*” or nullだと全てのparamが適用されます。 | - | nil |
| config.params[i].key | string | 検知をかけるparameter keyを定義します。”*”か null だと全てのparameter keyが適用されます。 | - | nil |
| config.params[i].patterns | array of string elements | config.patternsで定義したpatternのうち、適用するパターンを定義します。 | - | nil |

### ssk-safehost

設定したhostと実際のupstreamのhostを照合する。

ここで意味するhostはhost headerのvalueに値するので、正しくはFQDN。

Enable on Service

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -d "name=ssk-safehost" \
    -d "config.host_check=https://a.com"
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.host_check | string | upstreamのhost名を設定します。デフォルトではport:80が設定されますが、upstreamのportが80以外の場合は、portも含めて設定が必要です。 | true | nil |

### ssk-cors

CORSに関する検知を行う。

modify_response_header=true の際、検知した時のresponse headerが修正される。

Enable on Service

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
		-H "Content-Type: application/json" \
    -d '{"name"= "ssk-cors", 
		"config": {"block": true, 
		"modify_response_header": true, 
		"allow_origins": ["*"],
		"allow_methods": ["OPTIONS", "GET", "PUT"],
		"allow_headers": ["*"],
		"expose_headers": ["*"],
		"allow_credentials": false,
		"max_age": 3600}
		}'
```

**Config Parameters**

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.block | boolean | 検知が行われた場合に、requestをブロックするか設定します。 | true |  |
| config.modify_response_header | boolean | 検知、ブロックが行われた場合にresponse headerを修正するか設定します。 | - | nil |
| config.allow_origins | array of string elements | 許可するoriginを定義します。”*” or null の場合は全て許可しません。modify_response_header is true の場合、Headerに Access-Control-Allow-Origin: 設定値 を追加します。 | - | nil |
| config.allow_methods | array of string elements | 許可するmethodを定義します。”*”は全て許可します。modify_response_header is true の場合、Headerに Access-Control-Allow-Headers: 設定値 を追加します。 | - | nil |
| config.allow_headers | array of string elements | 許可するheaderを定義します。”*”は全て許可します。modify_response_header is true の場合、Headerに Access-Control-Allow-Headers: 設定値 を追加します。 | - | nil |
| config.expose_headers | array of string elements | modify_response_header is true の場合、Headerに Access-Control-Expose-Headers: 設定値 を追加します。 | - | nil |
| config.allow_credentials | boolean | modify_response_header is true の場合、Headerに Access-Control-Allow-Credentials: 設定値 を追加します。 | - | nil |
| config.max_age | integer | modify_response_header is true の場合、Headerに Access-Control-Max-Age: 設定値 を追加します。 | - | nil |

### ssk-detecthandling

ssk-* Pluginで検知された場合にResponseを設定値に変更する。

Enable on Service

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -H "Content-Type: application/json"\
		-d '{"name": "ssk-detecthandling", \
			"config": {"headers": [{"key": "x-gateway", "value": "sasanka-kong-gateway"}], \
			"status": "441", \
			"body": "detected by sasanka"}}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.status | integer | 検知した際のresponse statusを設定します。 | true | nil |
| config.headers | array of table elements | 検知した際のresponse headersをkey-value形式で設定します。 | true | nil |
| config.body | string | 検知した際のresponse body を設定します。 | true | nil |

### ssk-std-logger

ssk-* Pluginで検知された場合に検知した内容を標準出力する。

Enable on Service

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -d "name=ssk-std-logger" \
    -d "config.std=out"
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.std | string | 検知ログの出力先を設定する。out or err を設定でき、標準出力または標準エラー出力で設定する。 | true | - |

### Log Rule Id

ssk-std-loggerから出力された検知ログは以下のルールIDで管理される。

| Log Id | Detected by |
| --- | --- |
| 10 | ssk-pm |
| 20 | ssk-safehost |
| 30 | ssk-cors |
| 40 | ssk-ua-filter |
| 60 | ssk-libinjection |
| 70 | ssk-saferedirect |
| 80 | ssk-strictparamater |

### ssk-ua-filter

設定した任意のUser-Agentをブロックする。また、User-Agentを持たない or 空の場合にブロックする。

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
		-H "Content-Type: application/json" \
		-d '{
				"name": "ssk-ua-filter", 
				"config": {
					"block_useragents" : ["python/", "Powershell"], 
					"block_no_useragent" : true
					}
				}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
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
				"params": [ 
					{ "in": "param_req_query" } 
					{ "in": "param_req_body",  "key": "var", "sql": true } 
					]
				} 
			}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
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
  -d "config.policy=DENY"
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.policy | string | “DENY” or “SAMEORIGIN”から選べます。 | - | DENY |

### ssk-saferedirect

リダイレクトを制限します。設定されたprefixとマッチしたhostのみリダイレクトが許可されます。

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -H "Content-Type: application/json" \
    -d '{
			"name": "ssk-saferedirect",
			"config": {
				"params": [ 
					{ "in": "param_req_body",  "key": "redirect", "prefix": "http://my-redirect/api/" } 
					]
				}
			}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
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

---

# クイックスタート

### requirements

- Kong
    - `ssk-detecthandling,ssk-safehost,ssk-pm,ssk-cors,ssk-std-logger` をkong.confに追加してから `kong restart` を行う必要があります。
- curl
- python3 (>=3.6)
### Usage
```bash
./quickstart.sh YOUR_SERVICE_NAME_OR_ID
```
### Description
このquickstartはsasankaをdefault-settingで、即座に利用するためのものです。
quickstartの設定をそのまま使い続けることは推奨されていません。誤検知が発生した場合には自身で設定を見直し、変更する必要があります。

---

# 著作者

株式会社サイバーセキュリティクラウド

[https://www.cscloud.co.jp/](https://www.cscloud.co.jp/)

---