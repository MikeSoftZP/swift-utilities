//
//  CVPixelBuffer+Utilities.swift
//  swift-utilities
//
//  Created by Mike Ponomaryov on 27.05.2021.
//  Copyright © 2021 illutex. All rights reserved.
//

import UIKit
import VideoToolbox

extension CVPixelBuffer {
    func deepCopy() -> CVPixelBuffer? {
        let srcBufferLockResult = CVPixelBufferLockBaseAddress(self, .readOnly)
        guard srcBufferLockResult == kCVReturnSuccess else { return nil }
        
        defer {
            CVPixelBufferUnlockBaseAddress(self, .readOnly);
        }
        
        let srcWidth = CVPixelBufferGetWidth(self)
        let srcHeight = CVPixelBufferGetHeight(self)
        let srcPixelFormat = CVPixelBufferGetPixelFormatType(self)
        let srcPixelBufferPlaneCount = CVPixelBufferGetPlaneCount(self)
        
        let manager = PixelBufferManager.shared
        
        let size = CGSize(width: srcWidth, height: srcHeight)
        guard let dstPixelBuffer = manager.pixelBuffer(size: size, pixelFormat: srcPixelFormat) else { return nil }
        
        let dstBufferLockResult = CVPixelBufferLockBaseAddress(dstPixelBuffer, [])
        guard dstBufferLockResult == kCVReturnSuccess else { return nil }

        defer {
            CVPixelBufferUnlockBaseAddress(dstPixelBuffer, []);
        }
        
        if srcPixelBufferPlaneCount == 0 {
            let srcAddress = CVPixelBufferGetBaseAddress(self)
            let dstAddress = CVPixelBufferGetBaseAddress(dstPixelBuffer)
            
            let srcBytesPerRow = CVPixelBufferGetBytesPerRow(self)
            let dstBytesPerRow = CVPixelBufferGetBytesPerRow(dstPixelBuffer)
            
            if srcBytesPerRow == dstBytesPerRow {
                memcpy(dstAddress, srcAddress, srcHeight * srcBytesPerRow)
            } else {
                var srcStartOfRow = srcAddress
                var dstStartOfRow = dstAddress
                for _ in 0..<srcHeight {
                    memcpy(dstStartOfRow, srcStartOfRow, min(srcBytesPerRow, dstBytesPerRow))
                    srcStartOfRow = srcStartOfRow?.advanced(by: srcBytesPerRow)
                    dstStartOfRow = dstStartOfRow?.advanced(by: dstBytesPerRow)
                }
            }
        } else {
            for plane in 0..<srcPixelBufferPlaneCount {
                let srcPlaneAddress = CVPixelBufferGetBaseAddressOfPlane(self, plane)
                let dstPlaneAddress = CVPixelBufferGetBaseAddressOfPlane(dstPixelBuffer, plane)
                
                let srcPlaneHeight = CVPixelBufferGetHeightOfPlane(self, plane)
                
                let srcBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(self, plane)
                let dstBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(dstPixelBuffer, plane)
                
                if srcBytesPerRow == dstBytesPerRow {
                    memcpy(dstPlaneAddress, srcPlaneAddress, srcPlaneHeight * srcBytesPerRow)
                } else {
                    var srcStartOfRow = srcPlaneAddress
                    var dstStartOfRow = dstPlaneAddress
                    for _ in 0..<srcPlaneHeight {
                        memcpy(dstStartOfRow, srcStartOfRow, min(srcBytesPerRow, dstBytesPerRow))
                        srcStartOfRow = srcStartOfRow?.advanced(by: srcBytesPerRow)
                        dstStartOfRow = dstStartOfRow?.advanced(by: dstBytesPerRow)
                    }
                }
            }
        }
        
        return dstPixelBuffer
    }
    
    func image() -> UIImage? {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(self, options: nil, imageOut: &cgImage)
        
        guard let cgImage = cgImage else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
