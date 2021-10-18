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
import com_wjf_XPCService

class ViewController: NSViewController {
    
    @IBOutlet var textView: NSTextView!
    @IBOutlet var demoScrollView: NSScrollView!
    
    private var helperAppConnection: NSXPCConnection?
    private var xpcConnection: NSXPCConnection?
    private var listener: NSXPCListener?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        connectXPCService()
        
        listener = NSXPCListener.anonymous()
        listener?.delegate = self
        listener?.resume()
        
        if let listener = self.listener {
            let service = getXPCConnection()
            service?.setEndpoint(endpoint: listener.endpoint, for: ProcessInfo.processInfo.processIdentifier)
        }
    }
    
    override func viewWillAppear() {
        self.view.window?.title = "Main"
    }

    @IBAction func xpcTest(_ sender: NSButton) {
        let service = getXPCConnection()
        service?.upperCase(str: "abcddd") { [weak self] str in
            self?.log(str)
        }
    }
    
    @IBAction func helperConnection(_ sender: NSButton) {
        guard let runningCapHelperDemo = NSRunningApplication.runningApplications(withBundleIdentifier: "com.wjf.HelperDemo").first else {
            log("HelperDemo 未启动")
            return
        }
        
        let service = getXPCConnection()
        service?.getHelperAppEndpoint(for: runningCapHelperDemo.processIdentifier) { [weak self] endpoint in
            guard let endpoint = endpoint else {
                self?.log("EndPoint 不存在")
                return
            }
            self?.helperAppConnect(with: endpoint)
        }
    }
    
    @IBAction func helperDemoAction(_ sender: NSButton) {
        guard let helperAppConnection = self.helperAppConnection else {
            log("demoConnection is nil")
            return
        }
        let demoService = helperAppConnection.remoteObjectProxyWithErrorHandler { [weak self] error in
            self?.log("ERROR CONNECTING: \(error)")
        } as? HelperDemoProtocol
        demoService?.helperDemoStr { [weak self] str in
            self?.log(str)
        }
    }
    
    @IBAction func getEndpointCollection(_ sender: NSButton) {
        let service = getXPCConnection()
        service?.getEndpointCollection { [weak self] in
            self?.log($0)
        }
    }
    
    @IBAction func installAction(_ sender: NSButton) {
        if xpcConnection == nil {
            connectXPCService()
        }
        let service = xpcConnection?.remoteObjectProxyWithErrorHandler { error in
            print(error)
        } as? XPCServiceProtocol
        
        service?.installHelperTool { success in
            if success {
                self.log("安装成功")
            } else {
                self.log("安装失败")
            }
        }
    }
}

extension ViewController: NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: DemoProtocol.self)
        newConnection.exportedObject = DemoService()
        newConnection.resume()
        
        return true
    }
}

extension ViewController {
    func helperAppConnect(with endpoint: NSXPCListenerEndpoint) {
        helperAppConnection = NSXPCConnection(listenerEndpoint: endpoint)
        helperAppConnection?.remoteObjectInterface = NSXPCInterface(with: HelperDemoProtocol.self)
        helperAppConnection?.invalidationHandler = { [weak self] in
            self?.helperAppConnection?.invalidationHandler = nil
            OperationQueue.main.addOperation {
                self?.helperAppConnection = nil
            }
            self?.log("helperAppConnection invalidated")
        }
        helperAppConnection?.interruptionHandler = { [weak self] in
            self?.log("helperAppConnection interrupted")
        }
        helperAppConnection?.resume()
        
        let service = helperAppConnection?.remoteObjectProxyWithErrorHandler { [weak self] error in
            self?.log("连接 HelperDemo 失败: \(error)")
        } as? HelperDemoProtocol
        service?.checkHelperDemoConnection { [weak self] result in
            self?.log(result)
        }
    }
    
    func connectXPCService() {
        if xpcConnection == nil {
            xpcConnection = NSXPCConnection(serviceName: "com.wjf.XPCService")
            xpcConnection?.remoteObjectInterface = NSXPCInterface(with: XPCServiceProtocol.self)
            xpcConnection?.invalidationHandler = { [weak self] in
                self?.xpcConnection?.invalidationHandler = nil
                OperationQueue.main.addOperation {
                    self?.xpcConnection = nil
                    self?.log("xpc service connection invalidated")
                }
            }
            xpcConnection?.resume()
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
    
    func getXPCConnection() -> XPCServiceProtocol? {
        guard let xpcConnection = self.xpcConnection else {
            return nil
        }
        let service = xpcConnection.remoteObjectProxyWithErrorHandler { error in
            print("remote object proxy error: \(error)")
        } as? XPCServiceProtocol
        return service
    }
}
