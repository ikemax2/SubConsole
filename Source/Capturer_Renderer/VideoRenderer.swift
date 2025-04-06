//
//  VideoRenderer.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA.
//
import AVFoundation

protocol VideoRenderer : AVCaptureVideoDataOutputSampleBufferDelegate, CAMetalDisplayLinkDelegate {
    
    typealias DrawHandler = () -> Void
    typealias StatusUpdateHandler = (_ description: CMFormatDescription?, _ fps: Float64) -> Void
    
    var statusUpdateHandler : StatusUpdateHandler? { get set }
    var drawHandler : DrawHandler? { get set }
    
    func connectToLayer(_ metalLayer: CAMetalLayer)
    
    var displayLink : CAMetalDisplayLink? { get set }
    
    func clear()
}

extension VideoRenderer {
    
    func connectToLayer(_ metalLayer: CAMetalLayer) {
                
        let metalDisplayLink = CAMetalDisplayLink(metalLayer: metalLayer)

        metalDisplayLink.preferredFrameRateRange = CAFrameRateRange(minimum: 30.0, maximum: 60.0)
        metalDisplayLink.preferredFrameLatency = 2.0
        metalDisplayLink.add(to: RunLoop.current, forMode: RunLoop.Mode.common)

        self.displayLink = metalDisplayLink
        self.displayLink?.delegate = self

    }
    
    func createTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, textureCache: CVMetalTextureCache,
                       pixelFormat: MTLPixelFormat, planeIndex: Int) -> MTLTexture? {
        var mtlTexture: MTLTexture? = nil
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        
        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, pixelFormat, width, height, planeIndex, &texture)
        
        if status == kCVReturnSuccess {
            mtlTexture = CVMetalTextureGetTexture(texture!)
        }
        
        return mtlTexture
    }
    
    func isYpCbCr(_ imageBuf : CVImageBuffer)  -> Bool {
        
        let type = CVPixelBufferGetPixelFormatType(imageBuf)
        switch type{
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
            return true
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            return true
        case kCVPixelFormatType_420YpCbCr8Planar:
            return true
        default:  // unsupported.
            print("buffer pixelColorType: \(type.fourCharCodeString)")
            return false
        }

    }
    
    
    func planeCount(_ imageBuf : CVImageBuffer) ->  Int {
        return CVPixelBufferGetPlaneCount(imageBuf)
    }
    
    
    func lock(_ imageBuf : CVImageBuffer) throws {
        let cvReturn = CVPixelBufferLockBaseAddress(imageBuf, .readOnly)
        //EXC_BAD_ACCESS発生。
        if cvReturn != kCVReturnSuccess {
            //throw CVReturnError(code: cvReturn)
            fatalError()
        }
    }
    
    func unlock(_ imageBuf : CVImageBuffer) throws {
        let cvReturn = CVPixelBufferUnlockBaseAddress(imageBuf, .readOnly)
        if cvReturn != kCVReturnSuccess {
            // throw CVReturnError(code: cvReturn)
            fatalError()
        }
    }
    
}
