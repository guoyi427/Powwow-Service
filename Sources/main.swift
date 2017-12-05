import PerfectLib
import PerfectHTTP
import PerfectHTTPServer

func localhostHandler(data: [String: Any]) throws -> RequestHandler {
	return {
		request, response in
		response.appendBody(string: "hello world")
		response.completed()
	}
}

func gameHandler(data: [String: Any]) throws -> RequestHandler {
	return {
		request, response in
		response.appendBody(string: "yo yo pow wow")
		response.completed()
	}
}

let confData = [
	"servers":[
		[
			"name": "Powwow-Server",
			"port": 8080,
			"routes": [
				["method": "get", "uri": "/", "handler": localhostHandler],
				["method": "get", "uri": "/gameStart", "handler": gameHandler],
				["method": "get", "uri": "/**", "handler": PerfectHTTPServer.HTTPHandler.staticFiles, "documentRoot": ".", "allowResponseFilters": true]
			],
			"filters": [
				[
					"type": "response",
					"priority": "high",
					"name": PerfectHTTPServer.HTTPFilter.contentCompression
				]
			]
		]
	]
]

do {
	try HTTPServer.launch(configurationData: confData)
} catch {
	fatalError("\(error)")
}
