import PerfectLib
import PerfectHTTP
import PerfectHTTPServer

// User Server
let userServer = HTTPServer()
var userRoutes = Routes()
userRoutes.add(method: .get, uri: "/", handler: { request, response in
						print("hello api")
						response.appendBody(string: "hello world")
						response.completed()
						})
userServer.addRoutes(userRoutes)
userServer.serverPort = 8080
userServer.documentRoot = "./webroot/"

let chatServer = HTTPServer()
var chatRoutes = Routes()
chatRoutes.add(method: .get, uri: "/", handler: { request, response in
						print("hello chat")
						response.appendBody(string: "hello chat")
						response.completed()
						})
chatServer.addRoutes(chatRoutes)
chatServer.serverPort = 8181
chatServer.documentRoot = "./webroot/"

do {
    try userServer.start()
    try chatServer.start()
} catch {
    fatalError("\(error)")
}
