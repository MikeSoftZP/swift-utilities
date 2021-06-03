//
//  PixelBufferManager.swift
//  Rivet
//
//  Created by Mike Ponomaryov on 26.05.2021.
//  Copyright © 2021 Mike Ponomaryov. All rights reserved.
//

import AVFoundation

final class PixelBufferManager {
    
    private enum Constants {
        static let defaultFlushInterval: TimeInterval = 1.0
    }
    
    static let shared = PixelBufferManager()
    
    var autoFlush = true
    var flushInterval = Constants.defaultFlushInterval
    
    private var flushTimer: Timer?
    private var pools = [CFDictionary: PixelBufferPool]()
    private let defaultAttributes: [NSObject: AnyObject]
    private var queue = DispatchQueue(label: "com.illutex.pixelbufferpool.manager")
    
    private init() {
        defaultAttributes = [
            kCVPixelBufferIOSurfacePropertiesKey: [:] as AnyObject,
            kCVPixelBufferCGImageCompatibilityKey: true as AnyObject,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true as AnyObject,
            kCVPixelBufferMetalCompatibilityKey: true as AnyObject
        ]
        autoFlushPixelBufferPools(true)
    }
    
    deinit {
        flushTimer?.invalidate()
    }
    
    func autoFlushPixelBufferPools(_ autoFlushPools: Bool, timeInterval: TimeInterval = Constants.defaultFlushInterval) {
        queue.sync {
            flushInterval = timeInterval > 0 ? timeInterval : Constants.defaultFlushInterval
            autoFlush = autoFlushPools
            
            DispatchQueue.main.async {
                self.flushTimer?.invalidate()
                
                if self.autoFlush {
                    let timer = Timer(timeInterval: self.flushInterval, repeats: true, block: { _ in
                        self.flushUnusedBufferPools()
                    })
                    RunLoop.main.add(timer, forMode: .common)
                    self.flushTimer = timer
                }
            }
        }
    }
    
    func pixelBuffer(size: CGSize, pixelFormat: OSType = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) -> CVPixelBuffer? {
        var attributes = defaultAttributes
        
        attributes[kCVPixelBufferWidthKey] = size.width as AnyObject
        attributes[kCVPixelBufferHeightKey] = size.height as AnyObject
        attributes[kCVPixelBufferPixelFormatTypeKey] = pixelFormat as AnyObject

        return pixelBuffer(attributes: attributes as CFDictionary)
    }
    
    func pixelBuffer(attributes: CFDictionary) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        
        queue.sync {
            let isValidAttributes = Self.validatePixelBufferAttributes(attributes)
            if isValidAttributes, let pool: PixelBufferPool = pixelBufferPool(for: attributes) {
                pixelBuffer = pool.createPixelBuffer()
                if !autoFlush {
                    pool.flush()
                }
            }
        }
        
        return pixelBuffer
    }
    
    func pixelBufferPool(for attributes: CFDictionary) -> CVPixelBufferPool? {
        return pixelBufferPool(for: attributes)?.pool
    }
    
    static func validatePixelBufferAttributes(_ attributes: CFDictionary) -> Bool {
        guard let attribs = attributes as? [String: AnyObject], !attribs.isEmpty else { return false }
        
        let width = attribs[kCVPixelBufferWidthKey as String] as? Float ?? 0
        let height = attribs[kCVPixelBufferWidthKey as String] as? Float ?? 0
        let pixelFormat = attribs[kCVPixelBufferPixelFormatTypeKey as String] as? OSType
        
        if pixelFormat != nil && width > 0 && height > 0 {
            return true
        }
        
        return false
    }
}

private extension PixelBufferManager {
    private func pixelBufferPool(for attributes: CFDictionary) -> PixelBufferPool? {
        var pool = pools[attributes]
        
        if pool == nil {
            pool = PixelBufferPool(with: attributes)
            pools[attributes] = pool
        }
        
        return pool
    }
    
    private func flushUnusedBufferPools() {
        queue.sync {
            let nowDate = Date()
            
            pools = pools.filter { attributes, pool in
                if nowDate.timeIntervalSince(pool.lastAccessDate) >= flushInterval {
                    pool.flush()
                    return false
                }
                return true
            }
        }
    }
}

private class PixelBufferPool {
    private(set) var pool: CVPixelBufferPool
    private(set) var size: CGSize
    private(set) var lastAccessDate: Date
    
    init?(with attributes: CFDictionary) {
        print("PixelBufferPool - init")
        
        var pixelBufferPool: CVPixelBufferPool?
        let result = CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, attributes, &pixelBufferPool)
        guard let pixelBufferPool = pixelBufferPool, result == kCVReturnSuccess else { return nil }
        
        pool = pixelBufferPool
        lastAccessDate = Date()
        size = .zero
    }
    
    deinit {
        print("PixelBufferPool - deinit")
        flush()
    }
    
    func createPixelBuffer() -> CVPixelBuffer? {
        let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: 1)
        let result = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, pixelBufferPointer)
        
        defer {
            lastAccessDate = Date()
            pixelBufferPointer.deallocate()
        }
        
        if let pixelBuffer = pixelBufferPointer.pointee, result == kCVReturnSuccess {
            defer {
                pixelBufferPointer.deinitialize(count: 1)
            }
            return pixelBuffer
        } else {
            print("PixelBufferPool - Failed to allocate pixel buffer from pool")
        }
        
        return nil
    }
    
    func createPixelBuffer_unsafe() -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let result = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
        guard let pixelBuffer = pixelBuffer, result == kCVReturnSuccess else { return nil }
        
        lastAccessDate = Date()
        
        return pixelBuffer
    }
    
    func flush() {
        lastAccessDate = Date()
        CVPixelBufferPoolFlush(pool, CVPixelBufferPoolFlushFlags(rawValue: 0))
    }
}

