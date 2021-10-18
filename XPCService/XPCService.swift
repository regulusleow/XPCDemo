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
    private var authRef: AuthorizationRef?
    
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
            connectHelperTool()
        }
        reply(success)
    }
    
    func getEndpointCollection(reply: @escaping (String) -> Void) {
        let service = getHelperToolConnection()
        service?.getEndpointCollection {
            reply($0)
        }
    }
    
    func getHelperAppEndpoint(for PID: Int32, reply: @escaping (NSXPCListenerEndpoint?) -> Void) {
        let service = getHelperToolConnection()
        service?.getEndpoint(for: PID) { endpoint in
            reply(endpoint)
        }
    }
    
    func setEndpoint(endpoint: NSXPCListenerEndpoint, for PID: Int32) {
        let service = getHelperToolConnection()
        service?.setEndpoint(endpoint: endpoint, for: PID)
    }
}

extension XPCService {
    func connectHelperTool() {
        if self.helperToolConnection == nil {
            self.helperToolConnection = NSXPCConnection(machServiceName: "com.wjf.XPCHelperTool", options: .privileged)
            self.helperToolConnection?.remoteObjectInterface = NSXPCInterface(with: HelperToolProtocol.self)
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
        
        launchDaemonIfItIsNotRunning()
    }
}

extension XPCService {
    func getHelperToolConnection() -> HelperToolProtocol? {
        if helperToolConnection == nil {
            connectHelperTool()
        }
        let service = helperToolConnection?.remoteObjectProxyWithErrorHandler { error in
            print("helperDaemonConnection ERROR CONNECTING: \(error)")
        } as? HelperToolProtocol
        
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
        guard let bundleURL = NSRunningApplication.runningApplications(withBundleIdentifier: "com.wjf.XPCDemo").first?.bundleURL else {
            return
        }
        let url = bundleURL.deletingLastPathComponent().appendingPathComponent("HelperDemo.app", isDirectory: false)
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
        } as? HelperToolProtocol
        
        service?.checkDaemonPluse { [weak self] in
            OperationQueue.main.addOperation {
                self?.launchHelper()
            }
        }
    }
}
