//
//  CMSampleBuffer+Utilities.swift
//  Rivet
//
//  Created by Mike Ponomaryov on 24.02.2021.
//  Copyright © 2021 Mike Ponomaryov. All rights reserved.
//

import Foundation

extension CMSampleBuffer {
    
    static func silentAudio(pts: CMTime, samples: Int, sampleRate: Float64, channels: UInt32) -> CMSampleBuffer? {
        let bytesPerFrame = UInt32(2 * channels)
        let blockSize = samples * Int(bytesPerFrame)
        
        var block: CMBlockBuffer?
        var status = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: nil,
            blockLength: blockSize,
            blockAllocator: nil,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: blockSize,
            flags: 0,
            blockBufferOut: &block
        )
        assert(status == kCMBlockBufferNoErr)

        guard let eBlock = block else { return nil }

        // we seem to get zeros from the above, but I can't find it documented. so... memset:
        status = CMBlockBufferFillDataBytes(with: 0,
                                            blockBuffer: eBlock,
                                            offsetIntoDestination: 0,
                                            dataLength: blockSize)
        guard status == kCVReturnSuccess else { return nil }

        var asbd = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
            mBytesPerPacket: bytesPerFrame,
            mFramesPerPacket: 1,
            mBytesPerFrame: bytesPerFrame,
            mChannelsPerFrame: channels,
            mBitsPerChannel: 16,
            mReserved: 0
        )

        var formatDesc: CMAudioFormatDescription?
        status = CMAudioFormatDescriptionCreate(allocator: kCFAllocatorDefault,
                                                asbd: &asbd,
                                                layoutSize: 0,
                                                layout: nil,
                                                magicCookieSize: 0,
                                                magicCookie: nil,
                                                extensions: nil,
                                                formatDescriptionOut: &formatDesc)
        
        guard status == kCVReturnSuccess, let formatDescription = formatDesc else { return nil }

        var sampleBuffer: CMSampleBuffer?

        status = CMAudioSampleBufferCreateReadyWithPacketDescriptions(
            allocator: kCFAllocatorDefault,
            dataBuffer: eBlock,
            formatDescription: formatDescription,
            sampleCount: samples,
            presentationTimeStamp: pts,
            packetDescriptions: nil,
            sampleBufferOut: &sampleBuffer
        )
        
        guard status == kCVReturnSuccess else { return nil }
        
        do {
            try sampleBuffer?.setOutputPresentationTimeStamp(pts)
        } catch {
            print("error while setting output pts: \(error)")
        }
        
        return sampleBuffer
    }
    
    static func blankVideo(pts: CMTime, duration: CMTime, pixelFormat: OSType, size: CGSize) -> CMSampleBuffer? {
        var pixelBuffer: CVPixelBuffer?
        
        let outputOptions = [kCVPixelBufferOpenGLESCompatibilityKey as String: NSNumber(value: true),
                             kCVPixelBufferIOSurfacePropertiesKey as String: [:]] as [String : Any]
        var status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(size.width),
                                         Int(size.height),
                                         pixelFormat,
                                         outputOptions as CFDictionary,
                                         &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        
        let blackImage = UIGraphicsImageRenderer(size: size).image(actions: { _ in
            UIColor.black.setFill()
            UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        })
        
        guard let outputImage = CIImage(image: blackImage) else { return nil }
        let options = [CIContextOption.workingColorSpace: NSNull(),
                       CIContextOption.outputColorSpace: NSNull(),
                       CIContextOption.useSoftwareRenderer: NSNumber(value: false)]
        let ciContext = CIContext(options: options)
        ciContext.render(outputImage,
                         to: buffer,
                         bounds: CGRect(origin: .zero, size: size),
                         colorSpace: nil)
        
        var info = CMSampleTimingInfo()
        info.presentationTimeStamp = pts
        info.duration = duration
        info.decodeTimeStamp = pts

        var formatDesc: CMFormatDescription?
        status = CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                              imageBuffer: buffer,
                                                              formatDescriptionOut: &formatDesc)
        guard status == kCVReturnSuccess, let formatDescription = formatDesc else { return nil }

        var sampleBuffer: CMSampleBuffer?

        status = CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                          imageBuffer: buffer,
                                                          formatDescription: formatDescription,
                                                          sampleTiming: &info,
                                                          sampleBufferOut: &sampleBuffer)
        guard status == kCVReturnSuccess else { return nil }
        
        do {
            try sampleBuffer?.setOutputPresentationTimeStamp(pts)
        } catch {
            print("error while setting output pts: \(error)")
        }

        return sampleBuffer
    }
    
    func copyWithNewPTS(_ pts: CMTime) -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?
        
        var timingInfo = CMSampleTimingInfo()
        CMSampleBufferGetSampleTimingInfo(self, at: 0, timingInfoOut: &timingInfo)
        timingInfo.presentationTimeStamp = pts
        timingInfo.decodeTimeStamp = pts // kCMTimeInvalid if in sequence
        
        CMSampleBufferCreateCopyWithNewTiming(allocator: kCFAllocatorDefault,
                                              sampleBuffer: self, sampleTimingEntryCount: 1,
                                              sampleTimingArray: &timingInfo,
                                              sampleBufferOut: &sampleBuffer)
        
        do {
            try sampleBuffer?.setOutputPresentationTimeStamp(pts)
        } catch {
            print("error while setting output pts: \(error)")
        }
        
        return sampleBuffer
    }
    
    func scale(to size: CGSize, pixelFormat: OSType) -> CMSampleBuffer? {
        var dstPixelBuffer: CVPixelBuffer? = nil
        
        let outputOptions = [kCVPixelBufferOpenGLESCompatibilityKey as String: NSNumber(value: true),
                             kCVPixelBufferIOSurfacePropertiesKey as String: [:]] as [String : Any]
        var status: CVReturn = CVPixelBufferCreate(kCFAllocatorDefault,
                                                   Int(size.width),
                                                   Int(size.height),
                                                   pixelFormat,
                                                   outputOptions as CFDictionary,
                                                   &dstPixelBuffer)
        guard status == kCVReturnSuccess, let outputBuffer = dstPixelBuffer else { return nil }
        
        guard let pixelBuffer = self.imageBuffer else { return nil }
        var outputImage = CIImage(cvPixelBuffer: pixelBuffer, options: [CIImageOption.colorSpace: NSNull()])
        
        let bufferWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let bufferHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let outputScaleX = size.width / bufferWidth
        let outputScaleY = size.height / bufferHeight
        let scaleValue = min(outputScaleX, outputScaleY)
        var horizontalInset = (size.width - (bufferWidth * outputScaleY)) / 2.0
        var verticalInset = (size.height - (bufferHeight * outputScaleY)) / 2.0
        let isPortrait = size.height > size.width
        if isPortrait {
            horizontalInset = (size.width - (bufferWidth * outputScaleX)) / 2.0
            verticalInset = (size.height - (bufferHeight * outputScaleX)) / 2.0
        }
        
        outputImage = outputImage.transformed(by: CGAffineTransform.init(scaleX: scaleValue, y: scaleValue)) // scale
        outputImage = outputImage.transformed(by: CGAffineTransform.init(translationX: 0, y: CGFloat(verticalInset))) // center vertically
        outputImage = outputImage.transformed(by: CGAffineTransform.init(translationX: CGFloat(horizontalInset), y: 0)) // center horizontally
        
        let options = [CIContextOption.workingColorSpace: NSNull(),
                       CIContextOption.outputColorSpace: NSNull(),
                       CIContextOption.useSoftwareRenderer: NSNumber(value: false)]
        let ciContext = CIContext(options: options)
        ciContext.render(outputImage, to: outputBuffer, bounds: CGRect(origin: .zero, size: size), colorSpace: nil)
        
        var info = CMSampleTimingInfo()
        info.presentationTimeStamp = self.presentationTimeStamp
        info.duration = self.duration
        info.decodeTimeStamp = self.decodeTimeStamp

        var formatDesc: CMFormatDescription?
        status = CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                              imageBuffer: pixelBuffer,
                                                              formatDescriptionOut: &formatDesc)
        guard status == kCVReturnSuccess, let formatDescription = formatDesc else { return nil }

        var sampleBuffer: CMSampleBuffer?

        status = CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                          imageBuffer: pixelBuffer,
                                                          formatDescription: formatDescription,
                                                          sampleTiming: &info,
                                                          sampleBufferOut: &sampleBuffer)
        guard status == kCVReturnSuccess else { return nil }
        
        do {
            try sampleBuffer?.setOutputPresentationTimeStamp(self.outputPresentationTimeStamp)
        } catch {
            print("error while setting output pts: \(error)")
        }

        return sampleBuffer
    }
}
