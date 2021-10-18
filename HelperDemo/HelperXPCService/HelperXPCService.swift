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
    
    func getMainAppEndpoint(reply: @escaping (NSXPCListenerEndpoint?) -> Void) {
        let service = getHelperToolConnection()
        service?.getMainAppEndpoint {
            reply($0)
        }
    }
    
    func setEndpoint(endpoint: NSXPCListenerEndpoint) {
        let service = getHelperToolConnection()
        service?.setHelperAppEndpoint(endpoint)
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
