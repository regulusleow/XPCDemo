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
    
    private var helperConnection: NSXPCConnection?
    private var xpcConnection: NSXPCConnection?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        connectXPCService()
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
        service?.connectHelperApp(for: runningCapHelperDemo.processIdentifier)
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

extension ViewController {
    func connectXPCService() {
        if xpcConnection == nil {
            xpcConnection = NSXPCConnection(serviceName: "com.wjf.XPCService")
            xpcConnection?.remoteObjectInterface = NSXPCInterface(with: XPCServiceProtocol.self)
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
