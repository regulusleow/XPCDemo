//
//  ViewController.swift
//  XPCDemo
//
//  Created by jiafeng wu on 2021/8/24.
//

import Cocoa
import ServiceManagement
import com_wjf_XPCHelperTool
import GeneralLibrary

class ViewController: NSViewController {
    
    @IBOutlet var textView: NSTextView!
    @IBOutlet var demoScrollView: NSScrollView!
    
    private var helperDaemonConnection: NSXPCConnection?
    private var helperConnection: NSXPCConnection?
    private var listener: NSXPCListener?
    private var authRef: AuthorizationRef?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        connectToDaemon()
        
        listener = NSXPCListener.anonymous()
        listener?.delegate = self
        listener?.resume()
        
        if let listener = self.listener {
            let service = getHelperDaemonConnection()
            service?.setEndpoint(endpoint: listener.endpoint, for: ProcessInfo.processInfo.processIdentifier)
        }
    }
    
    override func viewWillAppear() {
        self.view.window?.title = "Main"
    }

    @IBAction func xpcTest(_ sender: NSButton) {
        let service = getHelperDaemonConnection()
        service?.upperCase(str: "abcddd") { [weak self] str in
            self?.log(str)
        }
    }
    
    @IBAction func helperConnection(_ sender: NSButton) {
        guard let runningCapHelperDemo = NSRunningApplication.runningApplications(withBundleIdentifier: "com.wjf.HelperDemo").first else {
            log("HelperDemo 未启动")
            return
        }
        
        let service = getHelperDaemonConnection()
        service?.getEndpoint(for: runningCapHelperDemo.processIdentifier) { [weak self] endpoint in
            if let helperDemoEndpoint = endpoint {
                OperationQueue.main.addOperation {
                    self?.helperDemoConnection(with: helperDemoEndpoint)
                }
            } else {
                self?.log("helperDemoEndpoint is nil")
            }
        }
    }
    
    @IBAction func helperDemoAction(_ sender: NSButton) {
        guard let helperConnection = self.helperConnection else {
            log("demoConnection is nil")
            return
        }
        let demoService = helperConnection.remoteObjectProxyWithErrorHandler { [weak self] error in
            self?.log("ERROR CONNECTING: \(error)")
        } as? HelperDemoProtocol
        demoService?.helperDemoStr { [weak self] str in
            self?.log(str)
        }
    }
    
    @IBAction func getEndpointCollection(_ sender: NSButton) {
        let service = getHelperDaemonConnection()
        service?.getEndpointCollection { [weak self] in
            self?.log($0)
        }
    }
    
    @IBAction func installAction(_ sender: NSButton) {
        launchDaemon()
    }
}

// MARK: - NSXPCListenerDelegate
extension ViewController: NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.remoteObjectInterface = NSXPCInterface(with: HelperDemoProtocol.self)
        newConnection.exportedInterface = NSXPCInterface(with: DemoProtocol.self)
        newConnection.exportedObject = DemoService()
        newConnection.resume()
        
        return true
    }
}

// MARK: - launch helper app
extension ViewController {
    func launchHelper() {
        let url = Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("HelperDemo.app", isDirectory: false)
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { [weak self] _, error in
            if let error = error {
                self?.log("launch helper app error: \(error)")
            }
        }
    }
}

extension ViewController {
    func launchDaemonIfItIsNotRunning() {
        let service = helperDaemonConnection?.remoteObjectProxyWithErrorHandler { [weak self] error in
            self?.log("remote object proxy error: \(error)")
            self?.launchDaemon()
        } as? HelperEndpointDaemonProtocol
        
        service?.checkDaemonPluse { [weak self] in
            OperationQueue.main.addOperation {
                self?.launchHelper()
            }
        }
    }
    
    func connectToDaemon() {
        helperDaemonConnection = NSXPCConnection(machServiceName: "com.wjf.XPCHelperTool", options: .privileged)
        helperDaemonConnection?.remoteObjectInterface = NSXPCInterface(with: HelperEndpointDaemonProtocol.self)
        
        helperDaemonConnection?.invalidationHandler = { [weak self] in
            self?.helperDaemonConnection?.invalidationHandler = nil
            OperationQueue.main.addOperation {
                self?.helperDaemonConnection = nil
            }
            self?.log("CONNECTION INVALIDATED")
        }
        helperDaemonConnection?.interruptionHandler = { [weak self] in
            self?.log("INTERRUIPTED CONNECTION!")
        }
        helperDaemonConnection?.resume()
        
        launchDaemonIfItIsNotRunning()
    }
    
    func launchDaemon() {
        let status = AuthorizationCreate(nil, nil, [.preAuthorize, .interactionAllowed, .extendRights], &authRef)
        if status != errAuthorizationSuccess {
            log("Failed to create AuthorizationRef, return code \(status)")
            return
        } else {
            log("SUCCESS AUTHORIZING DAEMON")
        }
        
        var error: Unmanaged<CFError>?
        let success = SMJobBless(kSMDomainSystemLaunchd, "com.wjf.XPCHelperTool" as CFString, authRef, &error)
        if success {
            log("SUCCESSFULLY LAUNCHED DAEMON")
            connectToDaemon()
        } else {
            log("job bless error: \(error.debugDescription)")
        }
    }
    
    func helperDemoConnection(with endpoint: NSXPCListenerEndpoint) {
        helperConnection = NSXPCConnection(listenerEndpoint: endpoint)
        helperConnection?.remoteObjectInterface = NSXPCInterface(with: HelperDemoProtocol.self)
        helperConnection?.invalidationHandler = { [weak self] in
            self?.helperConnection?.invalidationHandler = nil
            OperationQueue.main.addOperation {
                self?.helperConnection = nil
            }
            self?.log("helperConnection CONNECTION INVALIDATED")
        }
        helperConnection?.interruptionHandler = { [weak self] in
            self?.log("helperConnection INTERRUIPTED CONNECTION")
        }
        helperConnection?.resume()
        
        let service = helperConnection?.remoteObjectProxyWithErrorHandler { [weak self] error in
            self?.log("连接 HelperDemo 失败: \(error)")
        } as? HelperDemoProtocol
        service?.checkHelperDemoConnection { [weak self] result in
            self?.log(result)
        }
    }
}

// MARK: - utils
extension ViewController {
    func log(_ message: String) {
        OperationQueue.main.addOperation { [weak self] in
            guard let self = self else {
                return
            }
            self.textView.string = self.textView.string + "\(message)\n"
            self.demoScrollView.documentView?.scrollToEndOfDocument(nil)
        }
    }
    
    func getHelperDaemonConnection() -> HelperEndpointDaemonProtocol? {
        let service = helperDaemonConnection?.remoteObjectProxyWithErrorHandler { [weak self] error in
            self?.log("helperDaemonConnection ERROR CONNECTING: \(error)")
        } as? HelperEndpointDaemonProtocol
        
        return service
    }
}
