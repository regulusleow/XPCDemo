//
//  ViewController.swift
//  HelperDemo
//
//  Created by jiafeng wu on 2021/8/24.
//

import Cocoa
import com_wjf_XPCHelperTool
import GeneralLibrary

class ViewController: NSViewController {
    
    @IBOutlet var textView: NSTextView!
    
    private var helperDaemonConnection: NSXPCConnection?
    private var demoConnection: NSXPCConnection?
    private var listener: NSXPCListener?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        daemonConnection()
        
        listener = NSXPCListener.anonymous()
        listener?.delegate = self
        listener?.resume()
        
        let service = helperDaemonConnection?.remoteObjectProxyWithErrorHandler { [weak self] error in
            self?.log("remote object proxy error: \(error)")
        } as? HelperEndpointDaemonProtocol
        
        if let listener = self.listener {
            service?.setEndpoint(endpoint: listener.endpoint, for: ProcessInfo.processInfo.processIdentifier)
        }
    }
    
    @IBAction func xpcServiceAction(_ sender: NSButton) {
        guard let demoConnection = self.demoConnection else {
            log("demoConnection is nil")
            return
        }
        let demoService = demoConnection.remoteObjectProxyWithErrorHandler { [weak self] error in
            self?.log("ERROR CONNECTING: \(error)")
        } as? DemoProtocol
        demoService?.demoStr { [weak self] str in
            self?.log(str)
        }
    }
    
    @IBAction func xpcDemoAction(_ sender: NSButton) {
        guard let runningCapDemo = NSRunningApplication.runningApplications(withBundleIdentifier: "com.wjf.XPCDemo").first else {
            log("XPCDemo 未启动")
            return
        }
        
        let service = helperDaemonConnection?.remoteObjectProxyWithErrorHandler { [weak self] error in
            self?.log("helperDaemonConnection ERROR CONNECTING: \(error)")
        } as? HelperEndpointDaemonProtocol
        
        service?.getEndpoint(for: runningCapDemo.processIdentifier) { [weak self] endpoint in
            if let demoEndpoint = endpoint {
                OperationQueue.main.addOperation {
                    self?.xpcDemoConnection(with: demoEndpoint)
                }
            } else {
                self?.log("demoEndpoint is nil")
            }
        }
    }
}

// MARK: - NSXPCListenerDelegate
extension ViewController: NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.remoteObjectInterface = NSXPCInterface(with: DemoProtocol.self)
        newConnection.exportedInterface = NSXPCInterface(with: HelperDemoProtocol.self)
        newConnection.exportedObject = HelperDemoService()
        
        newConnection.resume()
        
        return true
    }
}

// MARK: - Connection
extension ViewController {
    func daemonConnection() {
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
            self?.log("INTERRUIPTED CONNECTION")
        }
        helperDaemonConnection?.resume()
    }
    
    /// 连接 XPCDemo
    /// - Parameter endpoint: XPCDemo 的 endpoint
    func xpcDemoConnection(with endpoint: NSXPCListenerEndpoint) {
        demoConnection = NSXPCConnection(listenerEndpoint: endpoint)
        demoConnection?.remoteObjectInterface = NSXPCInterface(with: DemoProtocol.self)
        demoConnection?.invalidationHandler = { [weak self] in
            self?.demoConnection?.invalidationHandler = nil
            OperationQueue.main.addOperation {
                self?.demoConnection = nil
            }
            self?.log("demoConnection CONNECTION INVALIDATED")
        }
        demoConnection?.interruptionHandler = { [weak self] in
            self?.log("demoConnection INTERRUIPTED CONNECTION")
        }
        demoConnection?.resume()
        
        let service = demoConnection?.remoteObjectProxyWithErrorHandler { [weak self] error in
            self?.log("连接 XPCDemo 失败")
        } as? DemoProtocol
        service?.checkConnection { [weak self] result in
            self?.log(result)
        }
    }
}

// MARK: - utils
extension ViewController {
    func log(_ message: String) {
        OperationQueue.main.addOperation {
            self.textView.string = self.textView.string + "\(message)\n"
        }
    }
}
