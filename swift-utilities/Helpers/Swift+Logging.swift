//
//  Swift+Logging.swift
//  swift-utilities
//
//  Created by Mike Ponomaryov on 29.03.2021.
//  Copyright © 2021 Mike Ponomaryov. All rights reserved.
//

import Foundation

enum DebugLoggingLevel: String {
    case none = "", info = "🔵 ", warning = "🟡 ", error = "🔴 ", done = "🟢 "
}

protocol DebugLogging {
    var debugPrefix: String? { get }
    var debugLoggingLevel: DebugLoggingLevel { get }
    var debugLoggingEnabled: Bool { get }
    
    func dPrint(_ items: Any..., separator: String, terminator: String, level: DebugLoggingLevel)
}

extension DebugLogging {
    var debugPrefix: String? { get { return nil } }
    var debugLoggingLevel: DebugLoggingLevel { get { return .none } }
    var debugLoggingEnabled: Bool { get { return true } }
    
    func dPrint(_ items: Any..., separator: String = " ", terminator: String = "\n", level: DebugLoggingLevel = .none) {
        #if DEBUG
        
        if !debugLoggingEnabled {
            return
        }
        
        var logObject: Any
        if items.count == 1 {
            guard let logMessage = items.first else { return }
            logObject = logMessage
        } else {
            logObject = items
        }
        
        var prefixString = ""
        if let prefix = debugPrefix, !prefix.isEmpty {
            prefixString = "\(prefix): "
        }
        
        let debugLevel = level == .none ? debugLoggingLevel : level

        print("\(prefixString)\(debugLevel.rawValue)\(logObject)", separator: separator, terminator: terminator)
        
        #endif
    }
}
