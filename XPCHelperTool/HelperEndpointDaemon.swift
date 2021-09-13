//
//  HelperEndpointDaemon.swift
//  XPCDemo
//
//  Created by jiafeng wu on 2021/8/27.
//

import Foundation

class HelperEndpointDaemon: NSObject {
    private var daemonListener: NSXPCListener?
    private var endpointDict = [Int32: NSXPCListenerEndpoint]()
    
    override init() {
        super.init()
        self.daemonListener = NSXPCListener(machServiceName: "com.wjf.XPCHelperTool")
        self.daemonListener?.delegate = self
    }
    
    func run() {
        self.daemonListener?.resume()
        RunLoop.current.run()
    }
}

extension HelperEndpointDaemon: NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: HelperEndpointDaemonProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }
}

extension HelperEndpointDaemon: HelperEndpointDaemonProtocol {
    func upperCase(str: String, reply: (String) -> Void) {
        let result = str.uppercased()
        reply(result)
    }
    
    func checkDaemonPluse(_ reply: @escaping () -> Void) {
        reply()
    }
    
    func setEndpoint(endpoint: NSXPCListenerEndpoint, for PID: Int32) {
        endpointDict[PID] = endpoint
    }
    
    func getEndpoint(for PID: Int32, reply: @escaping (NSXPCListenerEndpoint?) -> Void) {
        reply(endpointDict[PID])
    }
}
