//
//  XPCService.swift
//  XPCService
//
//  Created by jiafeng wu on 2021/8/26.
//

import Cocoa
import ServiceManagement
import com_wjf_XPCHelperTool
import GeneralLibrary

class XPCService: NSObject {
    
    private var listener: NSXPCListener?
    private var authorization: Data?
    private var helperToolConnection: NSXPCConnection?
    private var helperAppConnection: NSXPCConnection?
    private var authRef: AuthorizationRef?
    
    override init() {
        super.init()
        listener = NSXPCListener.service()
        listener?.delegate = self
        
//        if let listener = self.listener {
//            let service = getHelperToolConnection()
//            service?.setEndpoint(endpoint: listener.endpoint, for: ProcessInfo.processInfo.processIdentifier)
//        }
    }
    
    func run() {
        listener?.resume()
    }
}

// MARK: - NSXPCListenerDelegate

extension XPCService: NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: XPCServiceProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()
        
        return true
    }
}

// MARK: - XPCServiceProtocol

extension XPCService: XPCServiceProtocol {
    func upperCase(str: String, reply: @escaping (String) -> Void) {
        let service = getHelperToolConnection()
        service?.upperCase(str: str) {
            reply($0)
        }
    }
    
    func installHelperTool(reply: @escaping (Bool) -> Void) {
        let success = launchDaemon()
        if success {
            connectionHelperTool()
        }
        reply(success)
    }
    
    func getEndpointCollection(reply: @escaping (String) -> Void) {
        let service = getHelperToolConnection()
        service?.getEndpointCollection {
            reply($0)
        }
    }
    
    func connectHelperApp(for PID: Int32) {
        let service = getHelperToolConnection()
        service?.getEndpoint(for: PID) { [weak self] endpoint in
            guard let endpoint = endpoint else {
                print("helperDemoEndpoint is nil")
                return
            }
            self?.helperAppConnect(with: endpoint)
        }
    }
}

extension XPCService {
    func helperAppConnect(with endpoint: NSXPCListenerEndpoint) {
        helperAppConnection = NSXPCConnection(listenerEndpoint: endpoint)
        helperAppConnection?.remoteObjectInterface = NSXPCInterface(with: HelperDemoProtocol.self)
        helperAppConnection?.invalidationHandler = { [weak self] in
            self?.helperAppConnection?.invalidationHandler = nil
            OperationQueue.main.addOperation {
                self?.helperAppConnection = nil
            }
            print("helperAppConnection invalidated")
        }
        helperAppConnection?.interruptionHandler = {
            print("helperAppConnection interrupted")
        }
        helperAppConnection?.resume()
        
        let service = helperAppConnection?.remoteObjectProxyWithErrorHandler { error in
            print("连接 HelperDemo 失败: \(error)")
        } as? HelperDemoProtocol
        service?.checkHelperDemoConnection { result in
            print(result)
        }
    }
    
    func connectionHelperTool() {
        if self.helperToolConnection == nil {
            self.helperToolConnection = NSXPCConnection(machServiceName: "com.wjf.XPCHelperTool", options: .privileged)
            self.helperToolConnection?.remoteObjectInterface = NSXPCInterface(with: HelperEndpointDaemonProtocol.self)
            self.helperToolConnection?.invalidationHandler = {
                self.helperToolConnection?.invalidationHandler = nil
                OperationQueue.main.addOperation {
                    self.helperToolConnection = nil
                }
                print("helperToolConnection invalidated")
            }
            self.helperToolConnection?.interruptionHandler = {
                print("helperToolConnection interrupted")
            }
            self.helperToolConnection?.resume()
        }
        
//        launchDaemonIfItIsNotRunning()
    }
}

extension XPCService {
    func getHelperToolConnection() -> HelperEndpointDaemonProtocol? {
        if helperToolConnection == nil {
            connectionHelperTool()
        }
        let service = helperToolConnection?.remoteObjectProxyWithErrorHandler { error in
            print("helperDaemonConnection ERROR CONNECTING: \(error)")
        } as? HelperEndpointDaemonProtocol
        
        return service
    }
    
    func launchDaemon() -> Bool {
        let status = AuthorizationCreate(nil, nil, [.preAuthorize, .interactionAllowed, .extendRights], &authRef)
        if status != errAuthorizationSuccess {
            print("Failed to create AuthorizationRef, return code \(status)")
            return false
        } else {
            print("SUCCESS AUTHORIZING DAEMON")
        }
        
        var error: Unmanaged<CFError>?
        let success = SMJobBless(kSMDomainSystemLaunchd, "com.wjf.XPCHelperTool" as CFString, authRef, &error)
        if success {
            print("SUCCESSFULLY LAUNCHED DAEMON")
        } else {
            print("job bless error: \(error.debugDescription)")
        }
        return success
    }
    
    func launchHelper() {
        let url = Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("HelperDemo.app", isDirectory: false)
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, error in
            if let error = error {
                print("launch helper app error: \(error)")
            }
        }
    }
    
    func launchDaemonIfItIsNotRunning() {
        guard let helperToolConnection = self.helperToolConnection else {
            return
        }
        let service = helperToolConnection.remoteObjectProxyWithErrorHandler { [weak self] error in
            print("remote object proxy error: \(error)")
            _ = self?.launchDaemon()
        } as? HelperEndpointDaemonProtocol
        
        service?.checkDaemonPluse { [weak self] in
            OperationQueue.main.addOperation {
                self?.launchHelper()
            }
        }
    }
}
