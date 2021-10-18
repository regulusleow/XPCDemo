//
//  HelperToolService.swift
//  XPCDemo
//
//  Created by jiafeng wu on 2021/8/27.
//

import Cocoa

class HelperToolService: NSObject {
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

extension HelperToolService: NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: HelperToolProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }
}

extension HelperToolService: HelperToolProtocol {
    func upperCase(str: String, reply: (String) -> Void) {
        let result = str.uppercased()
        reply(result)
    }
    
    func checkDaemonPluse(_ reply: @escaping () -> Void) {
        reply()
    }
    
    func setEndpoint(endpoint: NSXPCListenerEndpoint, for PID: Int32) {
        if endpointDict.count > 2 {
            filterEndpoint()
        }
        endpointDict[PID] = endpoint
    }
    
    func getEndpoint(for PID: Int32, reply: @escaping (NSXPCListenerEndpoint?) -> Void) {
        reply(endpointDict[PID])
    }
    
    func getEndpointCollection(reply: @escaping (String) -> Void) {
        reply(endpointDict.description)
    }
}

extension HelperToolService {
    func filterEndpoint() {
        let runningCapDemo = NSRunningApplication.runningApplications(withBundleIdentifier: "com.wjf.XPCDemo").first
        let runningCapHelperDemo = NSRunningApplication.runningApplications(withBundleIdentifier: "com.wjf.HelperDemo").first
        
        var dict = [Int32: NSXPCListenerEndpoint]()
        if let demoPID = runningCapDemo?.processIdentifier {
            dict[demoPID] = endpointDict[demoPID]
        }
        if let helperDemoPID = runningCapHelperDemo?.processIdentifier {
            dict[helperDemoPID] = endpointDict[helperDemoPID]
        }
        
        endpointDict = dict
    }
}
