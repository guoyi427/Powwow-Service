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

/// 登录、注册
func gameHandler(data: [String: Any]) throws -> RequestHandler {
	return {
		request, response in
        
        let paraDic = analysisRequest(para: request.params())
        
        debugPrint(paraDic)
        
        let mobileFromUser = paraDic["mobile"] ?? ""
        let passwordFormUser = paraDic["password"] ?? ""
        //  判断参数是否齐全
        if mobileFromUser.count == 0 || passwordFormUser.count == 0 {
            response.appendBody(string: "error")
            response.completed()
            return
        }
        
        var responseBodyDic: [String: String] = [:]
        
        var token: String?

        let result = mysqlManager.instance.queryUser(mobile: mobileFromUser)
        if result.success && result.userDic.count > 0 {
            //  存在这个用户手机号 生成token 保存本地 返回token
            //  更新到本地   内部验证密码正伪
            let tokenResult = mysqlManager.instance.updateToken(mobile: mobileFromUser, password: passwordFormUser)
            if tokenResult.success {
                token = tokenResult.token
            }
        } else if (result.success && result.userDic.count == 0) {
            //  不存在这个手机号， 生成token，保存token和用户信息 返回token
            
        } else {
            //  查询出错
            
        }
        
        
        if token != nil {
            responseBodyDic["code"] = "0"
            responseBodyDic["token"] = token
        } else {
            responseBodyDic["code"] = "1"
            responseBodyDic["message"] = "token 失效"
        }
        
        var responseJSON = ""
        do {
            responseJSON = try responseBodyDic.jsonEncodedString()
        } catch {
            debugPrint("\(error)")
            responseJSON = "error"
        }
        
        response.setHeader(.contentType, value: "text/html; charset=utf-8")
        response.appendBody(string: responseJSON)
        
		response.completed()
	}
}

//MARK: Instrument Methods

/// 解析参数 返回字典
func analysisRequest(para:[(String, String)]) -> [String: String] {
    var resultDic: [String: String] = [:]
    para.forEach { (element) in
        resultDic[element.0] = element.1
    }
    return resultDic
}

//MARK: Server Config

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
