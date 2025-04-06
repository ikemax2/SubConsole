//
//  VideoRendererMetal420.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
//  reference: https://developer.apple.com/documentation/arkit/displaying-an-ar-experience-with-metal
//  reference: https://developer.apple.com/documentation/metalfx/applying-temporal-antialiasing-and-upscaling-using-metalfx
//
import AVFoundation
import Metal
import MetalFX

class VideoRendererMetal420 : NSObject, VideoRenderer{

    
    var statusUpdateHandler : VideoRenderer.StatusUpdateHandler?
    var drawHandler : VideoRenderer.DrawHandler?
    
    var device : MTLDevice
    
    var displayLink : CAMetalDisplayLink?
    
    var commandQueue : MTLCommandQueue?
    
    var metalPipeline: MTLRenderPipelineState?
    var metalTextureCache : CVMetalTextureCache?
    
    var metalPipelineCopy: MTLRenderPipelineState?
    
    var metalImageBuffer : CVImageBuffer?

    // metalImageBuffer に対するスレッドセーフ用。metalImageBufferにアクセスする処理は、この専用スレッドを使う。
    var renderPrepareQueue = DispatchQueue(label: "renderPrepareQueue", qos: .userInteractive)
        
    var measureFPS = FPSMeasurer()
    var drawFPS = FPSMeasurer()
    
    var captureSize : CMVideoDimensions?
        
    var spatialScalerDescriptor = MTLFXSpatialScalerDescriptor()
    var spatialScaler : MTLFXSpatialScaler?
        
    var metalTextureY: MTLTexture?
    var metalTextureCbcr: MTLTexture?
    var metalTextureOutput: MTLTexture?
    var metalTextureScaled: MTLTexture?
    
    var clearFlag : Bool = false

    override init() {
                
        guard let metalDevice = MTLCreateSystemDefaultDevice() else{
            fatalError()
        }
        self.device = metalDevice
        
        super.init()
        prepareMetal_420v()
        
        // 必ず connectToLayerも呼ぶこと
    }
    
    func prepareMetal_420v() {
        
        self.commandQueue = device.makeCommandQueue()
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, self.device, nil, &metalTextureCache)
        
        // Metal パイプラインステートの作成
        guard let library = self.device.makeDefaultLibrary() else {
            fatalError()
        }
        
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = library.makeFunction(name: "vertexShader")
        pipelineDesc.fragmentFunction = library.makeFunction(name: "fragmentShader420v")
        pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
                
        self.metalPipeline = try! device.makeRenderPipelineState(descriptor: pipelineDesc)
        
        
        let pipelineCopyDesc = MTLRenderPipelineDescriptor()
        pipelineCopyDesc.vertexFunction = library.makeFunction(name: "FSQ_VS_V4T2")
        pipelineCopyDesc.fragmentFunction = library.makeFunction(name: "FSQ_simpleCopy")
        pipelineCopyDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
                
        self.metalPipelineCopy = try! device.makeRenderPipelineState(descriptor: pipelineCopyDesc)
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // fps 計測用
        measureFPS.pulse { fps in
            self.statusUpdateHandler?(sampleBuffer.formatDescription, fps)
        }
        
        self.renderPrepareQueue.async {
            self.captureSize = sampleBuffer.formatDescription?.dimensions
            
            self.metalImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        }
        
        // print("captureOutput called. captureSize: \(self.captureSize?.width ?? -1) x \(self.captureSize?.height ?? -1)")
    }
    
    func metalDisplayLink(_ link: CAMetalDisplayLink, needsUpdate update: CAMetalDisplayLink.Update) {
        
        self.renderPrepareQueue.async{
            if self.clearFlag == true {
                self.draw_none(update)
                self.clearFlag = false
            }else{
                self.draw_Metal_420(update)
            }
        }
        
        self.drawHandler?()
        
        // print("metalDisplayLink called.")
    }
    
    
    func updateSpatialScaler(inputWidth: Int, inputHeight: Int, outputWidth: Int, outputHeight: Int){
                
        if spatialScalerDescriptor.inputWidth != inputWidth ||
            spatialScalerDescriptor.inputHeight != inputHeight ||
            spatialScalerDescriptor.outputWidth != outputWidth ||
            spatialScalerDescriptor.outputHeight != outputHeight {
            
            print("update spatialScaler current width, height = (\(spatialScalerDescriptor.outputWidth) x \(spatialScalerDescriptor.outputHeight) )")
            
            spatialScalerDescriptor.inputWidth = inputWidth
            spatialScalerDescriptor.inputHeight = inputHeight
            spatialScalerDescriptor.outputWidth = outputWidth
            spatialScalerDescriptor.outputHeight = outputHeight
            
            spatialScalerDescriptor.colorTextureFormat = .bgra8Unorm
            spatialScalerDescriptor.outputTextureFormat = .bgra8Unorm
            spatialScalerDescriptor.colorProcessingMode = .perceptual
            
            spatialScaler = spatialScalerDescriptor.makeSpatialScaler(device: self.device)
            
            
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                             width: spatialScalerDescriptor.inputWidth,
                                                                             height: spatialScalerDescriptor.inputHeight,
                                                                             mipmapped: false)
            textureDescriptor.usage = [.renderTarget, .shaderRead]
            textureDescriptor.storageMode = .private
            
            metalTextureOutput = self.device.makeTexture(descriptor: textureDescriptor)
            
            
            let textureScaledDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                                   width: spatialScalerDescriptor.outputWidth,
                                                                                   height: spatialScalerDescriptor.outputHeight,
                                                                                   mipmapped: true)
            textureScaledDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
            textureScaledDescriptor.storageMode = .private
            
            metalTextureScaled = self.device.makeTexture(descriptor: textureScaledDescriptor)
            
        }
    }
    
    func updateCyCbcrTexture(imageBuffer: CVImageBuffer, textureCache: CVMetalTextureCache){
        
        guard isYpCbCr(imageBuffer) else {
            fatalError()
        }
        guard planeCount(imageBuffer) == 2 else {
            fatalError()
        }
        
        do {
            try lock(imageBuffer)
            
            defer {
                _ = try? unlock(imageBuffer)
            }
            

            metalTextureY =  createTexture(fromPixelBuffer: imageBuffer,
                                         textureCache: textureCache,
                                         pixelFormat:.r8Unorm,
                                         planeIndex:0)

            metalTextureCbcr =  createTexture(fromPixelBuffer: imageBuffer,
                                         textureCache: textureCache,
                                         pixelFormat:.rg8Unorm,
                                         planeIndex:1)
            
        }catch{
            print("error occured.")
        }
        
    }
    
    
    func draw_Metal_420(_ update: CAMetalDisplayLink.Update) {

        guard let textureCache = self.metalTextureCache else {
            return
        }
        
        guard let imageBuffer = self.metalImageBuffer, let cSize = self.captureSize else{
            return
        }
        
        let drawable = update.drawable
        
        // TextureY, TextureCbcr update.
        updateCyCbcrTexture(imageBuffer: imageBuffer, textureCache: textureCache)
        
        // TextureOutput, TextureScaled update if necessary
        updateSpatialScaler(inputWidth: Int(cSize.width), inputHeight: Int(cSize.height),
                            outputWidth: drawable.texture.width, outputHeight: drawable.texture.height)
        
        guard let textureY = metalTextureY, let textureCbcr = metalTextureCbcr,
              let textureOutput = self.metalTextureOutput, let textureScaled = self.metalTextureScaled else{
            print("textureOutput, textureScaled is nil ! ")
            return
        }
        
        guard
            let pipeline = metalPipeline, let pipelineCopy = metalPipelineCopy else{
            print("CVMetalTextureCacheCreateTextureFromImage is failure.")
            return
        }
        
        let renderDesc = MTLRenderPassDescriptor()
        renderDesc.colorAttachments[0].texture = textureOutput
        renderDesc.colorAttachments[0].loadAction = .clear
        renderDesc.colorAttachments[0].storeAction = .store
        renderDesc.colorAttachments[0].clearColor = MTLClearColorMake(0.8, 0.7, 0.1, 1.0)
        
        guard let commandBuffer = commandQueue?.makeCommandBuffer(),
              let encoder : MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDesc) else {

            print("can't make CommandBuffer!! ")
            return
        }
                
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentTexture(textureY, index: 0)
        encoder.setFragmentTexture(textureCbcr, index: 1)
        
        // encoder.setVertexBuffer(imagePlaneVertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
        
        // print(" drawable storagemode: \(drawable.texture.storageMode)")
        
        
        spatialScaler?.colorTexture = textureOutput
        spatialScaler?.outputTexture = textureScaled
        // spatialScaler?.outputTextureUsage = .pixelFormatView
        spatialScaler?.encode(commandBuffer: commandBuffer)

        
        let copyDesc = MTLRenderPassDescriptor()
        copyDesc.colorAttachments[0].texture = drawable.texture
        copyDesc.colorAttachments[0].loadAction = .clear
        copyDesc.colorAttachments[0].storeAction = .store
        copyDesc.colorAttachments[0].clearColor = MTLClearColorMake(0.8, 0.7, 0.1, 1.0)
        
        guard let copyEncoder : MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: copyDesc) else{
            print("copyEncoder is nil. ")
            return
        }
        
        copyEncoder.setRenderPipelineState(pipelineCopy)
        // encoder.setFragmentBuffer(textureScaled, offset: 0, index: 0)
        copyEncoder.setFragmentTexture(textureScaled, index: 0)
        copyEncoder.drawPrimitives(type: MTLPrimitiveType.triangle, vertexStart: 0, vertexCount: 3)
        copyEncoder.endEncoding()
        
        
        commandBuffer.present(drawable)
        commandBuffer.commit()

    }
    
    func clear() {
        self.metalImageBuffer = nil  // 最後のキャプチャ結果をクリア
        
        clearFlag = true  // 一度だけ draw_noneを実行し、画面を塗りつぶす。

        spatialScalerDescriptor = MTLFXSpatialScalerDescriptor() // spatialScalerDescriptor をクリア
    }
    
    func draw_none(_ update: CAMetalDisplayLink.Update) {
        let drawable = update.drawable
        
        let textureScaledDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                               width: drawable.texture.width, height: drawable.texture.height,
                                                                               mipmapped: true)
        textureScaledDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        textureScaledDescriptor.storageMode = .private
        
        self.metalTextureScaled = self.device.makeTexture(descriptor: textureScaledDescriptor)
        
        
        guard let pipelineCopy = metalPipelineCopy, let textureScaled = self.metalTextureScaled else{
            print("CVMetalTextureCacheCreateTextureFromImage is failure.")
            return
        }
        
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else {
            print("texture or pipeline is nil. ")
            return
        }
        
        let copyDesc = MTLRenderPassDescriptor()
        copyDesc.colorAttachments[0].texture = drawable.texture
        copyDesc.colorAttachments[0].loadAction = .clear
        copyDesc.colorAttachments[0].storeAction = .store
        copyDesc.colorAttachments[0].clearColor = MTLClearColorMake(0.8, 0.7, 0.1, 1.0)
        
        guard let copyEncoder : MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: copyDesc) else{
            print("copyEncoder is nil. ")
            return
        }
        
        copyEncoder.setRenderPipelineState(pipelineCopy)
        copyEncoder.setFragmentTexture(textureScaled, index: 0)
        copyEncoder.drawPrimitives(type: MTLPrimitiveType.triangle, vertexStart: 0, vertexCount: 3)
        copyEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
