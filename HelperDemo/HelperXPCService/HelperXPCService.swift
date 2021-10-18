//
//  HelperXPCService.swift
//  HelperXPCService
//
//  Created by jiafeng wu on 2021/10/18.
//

import Foundation
import GeneralLibrary
import com_wjf_XPCHelperTool

class HelperXPCService: NSObject {
    
    private var listener: NSXPCListener?
    private var helperToolConnection: NSXPCConnection?
    
    override init() {
        super.init()
        listener = NSXPCListener.service()
        listener?.delegate = self
        
        connectHelperTool()
    }
    
    func run() {
        listener?.resume()
    }
    
}

extension HelperXPCService: NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: HelperXPCServiceProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()
        
        return true
    }
}

extension HelperXPCService: HelperXPCServiceProtocol {
    func upperCase(str: String, reply: @escaping (String) -> Void) {
        reply(str.uppercased())
    }
    
    func getMainAppEndpoint(for PID: Int32, reply: @escaping (NSXPCListenerEndpoint?) -> Void) {
        let service = getHelperToolConnection()
        service?.getEndpoint(for: PID) { endpoint in
            reply(endpoint)
        }
    }
    
    func setEndpoint(endpoint: NSXPCListenerEndpoint, for PID: Int32) {
        let service = getHelperToolConnection()
        service?.setEndpoint(endpoint: endpoint, for: PID)
    }
    
    func getEndpointCollection(reply: @escaping (String) -> Void) {
        let service = getHelperToolConnection()
        service?.getEndpointCollection {
            reply($0)
        }
    }
}

extension HelperXPCService {
    func connectHelperTool() {
        helperToolConnection = NSXPCConnection(machServiceName: "com.wjf.XPCHelperTool", options: .privileged)
        helperToolConnection?.remoteObjectInterface = NSXPCInterface(with: HelperToolProtocol.self)
        helperToolConnection?.invalidationHandler = { [weak self] in
            self?.helperToolConnection?.invalidationHandler = nil
            OperationQueue.main.addOperation {
                self?.helperToolConnection = nil
            }
            print("CONNECTION INVALIDATED")
        }
        helperToolConnection?.interruptionHandler = {
            print("INTERRUIPTED CONNECTION")
        }
        helperToolConnection?.resume()
    }
    
    func getHelperToolConnection() -> HelperToolProtocol? {
        if helperToolConnection == nil {
            connectHelperTool()
        }
        let service = helperToolConnection?.remoteObjectProxyWithErrorHandler { error in
            print("helperDaemonConnection ERROR CONNECTING: \(error)")
        } as? HelperToolProtocol
        
        return service
    }
}
