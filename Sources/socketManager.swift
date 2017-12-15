//
//  socketManager.swift
//  Powwow-ServicePackageDescription
//
//  Created by kokozu on 15/12/2017.
//

import PerfectWebSockets
import PerfectHTTP
import PerfectLib

func socketHandler(data: [String: Any]) throws -> RequestHandler {
    return {
        request, response in
        WebSocketHandler(handlerProducer: { (socketReq: HTTPRequest, protocols: [String]) -> WebSocketSessionHandler? in
            debugPrint("in socket handler")
            return SocketManager()
        }).handleRequest(request: request, response: response)
    }
}

class SocketManager: WebSocketSessionHandler {
    let socketProtocol: String? = "powwow"
    
    func handleSession(request req: HTTPRequest, socket: WebSocket) {
        socket.readStringMessage {
            // This callback is provided:
            //    the received data
            //    the message's op-code
            //    a boolean indicating if the message is complete (as opposed to fragmented)
            (string, opcodeType, fin) in
            guard let string = string else {
                socket.close()
                debugPrint("socket read string is empty")
                return
            }
            debugPrint("str = \(string)")
            socket.sendStringMessage(string: string, final: true, completion: {
                self.handleSession(request: req, socket: socket)
            })
        }
    }
}
