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
        
        let result = mysqlManager.instance.queryUser(mobile: "13800138000")
        if result.success && result.userDic.count > 0 {
            //  存在这个用户手机号 生成token 保存本地 返回token
            var token = ""
            if let mobile = result.userDic["mobile"] {
                debugPrint("mobile=\(mobile)")
                if let enc = mobile.digest(.md5)?.encode(.hex) {
                    token = String(validatingUTF8: enc) ?? ""
                }
            }
            debugPrint(token)
        } else if (result.success && result.userDic.count == 0) {
            //  不存在这个手机号， 生成token，保存token和用户信息 返回token
            
        } else {
            //  查询出错
            
        }
        
        
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
