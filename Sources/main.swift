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
		let path = request.documentRoot + "/game"
		debugPrint("game path = \(path)")
		StaticFileHandler(documentRoot: path).handleRequest(request: request, response: response)
	}
}

let confData = [
	"servers":[
		[
			"name": "Powwow-Server",
			"port": 8080,
			"routes": [
				["method": "get", "uri": "/", "handler": localhostHandler],
				["method": "get", "uri": "/game", "handler": gameHandler],
				["method": "get", "uri": "/**", "handler": PerfectHTTPServer.HTTPHandler.staticFiles, "documentRoot": "./webroot", "allowResponseFilters": true]
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