//
//  XPCServiceDelegate.swift
//  XPCService
//
//  Created by jiafeng wu on 2021/8/26.
//

import Foundation

class XPCServiceDelegate: NSObject, NSXPCListenerDelegate {
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        
        newConnection.exportedInterface = NSXPCInterface(with: XPCServiceProtocol.self)
        newConnection.exportedObject = XPCService()
        
        newConnection.resume()
        
        return true
    }
}
