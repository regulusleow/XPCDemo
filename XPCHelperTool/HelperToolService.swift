//
//  HelperToolService.swift
//  XPCDemo
//
//  Created by jiafeng wu on 2021/8/27.
//

import Cocoa

class HelperToolService: NSObject {
    private var listener: NSXPCListener?
    private var mainAppEndpoint: NSXPCListenerEndpoint?
    private var helperAppEndpoint: NSXPCListenerEndpoint?
    
    override init() {
        super.init()
        self.listener = NSXPCListener(machServiceName: "com.wjf.XPCHelperTool")
        self.listener?.delegate = self
    }
    
    func run() {
        self.listener?.resume()
        RunLoop.current.run()
    }
}

extension HelperToolService: NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: HelperToolProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }
}

extension HelperToolService: HelperToolProtocol {
    func checkDaemonPluse(_ reply: @escaping () -> Void) {
        reply()
    }
    
    func setMainAppEndpoint(_ endpoint: NSXPCListenerEndpoint?) {
        mainAppEndpoint = endpoint
    }
    
    func getMainAppEndpoint(_ reply: @escaping (NSXPCListenerEndpoint?) -> Void) {
        reply(mainAppEndpoint)
    }
    
    func setHelperAppEndpoint(_ endpoint: NSXPCListenerEndpoint?) {
        helperAppEndpoint = endpoint
    }
    
    func getHelperAppEndpoint(_ reply: @escaping (NSXPCListenerEndpoint?) -> Void) {
        reply(helperAppEndpoint)
    }
}
