//
//  ViewController.swift
//  HelperDemo
//
//  Created by jiafeng wu on 2021/8/24.
//

import Cocoa
import GeneralLibrary
import HelperXPCService
import com_wjf_XPCHelperTool

class ViewController: NSViewController {
    
    @IBOutlet var textView: NSTextView!
    @IBOutlet var scrollView: NSScrollView!
    
    private var xpcConnection: NSXPCConnection?
    private var mainAppConnection: NSXPCConnection?
    private var listener: NSXPCListener?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        connectHelperXPCService()

        listener = NSXPCListener.anonymous()
        listener?.delegate = self
        listener?.resume()

        if let listener = self.listener {
            let service = getXPCConnection()
            service?.setEndpoint(endpoint: listener.endpoint)
        }
    }
    
    override func viewWillAppear() {
        self.view.window?.title = "Helper"
    }
    
    @IBAction func mainDemoAction(_ sender: NSButton) {
        guard let mainAppConnection = self.mainAppConnection else {
            log("main app is nil")
            return
        }
        let demoService = mainAppConnection.remoteObjectProxyWithErrorHandler { [weak self] error in
            self?.log("ERROR CONNECTING: \(error)")
        } as? DemoProtocol
        demoService?.demoStr { [weak self] str in
            self?.log(str)
        }
    }
    
    @IBAction func mainAppConnectAction(_ sender: NSButton) {
        let service = getXPCConnection()
        service?.getMainAppEndpoint { [weak self] endpoint in
            guard let endpoint = endpoint else {
                self?.log("EndPoint 不存在")
                return
            }
            self?.mainAppConnect(with: endpoint)
        }
    }
}

// MARK: - NSXPCListenerDelegate
extension ViewController: NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: HelperDemoProtocol.self)
        newConnection.exportedObject = HelperDemoService()
        
        newConnection.resume()
        
        return true
    }
}

// MARK: - Connection
extension ViewController {
    func connectHelperXPCService() {
        if xpcConnection == nil {
            xpcConnection = NSXPCConnection(serviceName: "com.wjf.HelperXPCService")
            xpcConnection?.remoteObjectInterface = NSXPCInterface(with: HelperXPCServiceProtocol.self)
            xpcConnection?.invalidationHandler = {
                self.xpcConnection?.invalidationHandler = nil
                OperationQueue.main.addOperation {
                    self.xpcConnection = nil
                    print("connection invalidated")
                }
            }
            xpcConnection?.resume()
        }
    }
    
    /// 连接 Main app
    /// - Parameter endpoint: main app 的 endpoint
    func mainAppConnect(with endpoint: NSXPCListenerEndpoint) {
        mainAppConnection = NSXPCConnection(listenerEndpoint: endpoint)
        mainAppConnection?.remoteObjectInterface = NSXPCInterface(with: DemoProtocol.self)
        mainAppConnection?.invalidationHandler = { [weak self] in
            self?.mainAppConnection?.invalidationHandler = nil
            OperationQueue.main.addOperation {
                self?.mainAppConnection = nil
            }
            self?.log("Main App CONNECTION INVALIDATED")
        }
        mainAppConnection?.interruptionHandler = { [weak self] in
            self?.log("Main App INTERRUIPTED CONNECTION")
        }
        mainAppConnection?.resume()

        let service = mainAppConnection?.remoteObjectProxyWithErrorHandler { [weak self] error in
            self?.log("连接 main app 失败")
        } as? DemoProtocol
        service?.checkConnection { [weak self] result in
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
            self.scrollView.documentView?.scrollToEndOfDocument(nil)
        }
    }
    
    func getXPCConnection() -> HelperXPCServiceProtocol? {
        guard let xpcConnection = self.xpcConnection else {
            return nil
        }
        let service = xpcConnection.remoteObjectProxyWithErrorHandler { error in
            print("remote object proxy error: \(error)")
        } as? HelperXPCServiceProtocol
        return service
    }
}
