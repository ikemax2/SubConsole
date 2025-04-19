//
//  DisplayView.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import AppKit
import AVFoundation

protocol DisplayViewDelegate : AnyObject {
    func mouseMoved(event: NSEvent, view: NSView)
    func mouseEntered(event :NSEvent)
    func mouseExited(event : NSEvent)
    
    func mouseDown(event: NSEvent)
    func mouseUp(event: NSEvent)
    func rightMouseDown(event: NSEvent)
    func rightMouseUp(event: NSEvent)
    func otherMouseDown(event: NSEvent)
    func otherMouseUp(event: NSEvent)
    
    func mouseDragged(event: NSEvent, view: NSView)
    func rightMouseDragged(event: NSEvent, view: NSView)
    func otherMouseDragged(event: NSEvent, view: NSView)
    func scrollWheel(event: NSEvent)
}

class DisplayView : NSView {
    
    var metalLayer: CAMetalLayer
    var videoRenderer : VideoRenderer
    var videoAudioCapturer : VideoAudioCapturer?
    
    weak var manipulator: Manipulator?
    
    weak var delegate : DisplayViewDelegate?
           
    var cursor : NSCursor?
    
    init(statusUpdateHandler: VideoRenderer.StatusUpdateHandler? = nil,
         manipulator: Manipulator? = nil,
         drawHandler: VideoRenderer.DrawHandler? = nil,
         cursorType: CursorType? = nil) {
        
        self.metalLayer = CAMetalLayer()
        self.manipulator = manipulator
        self.delegate = manipulator
        
        // VideoRenderer : 画面描画を担当する(Metal使用)
        self.videoRenderer = VideoRendererMetal420()
        self.videoRenderer.statusUpdateHandler = statusUpdateHandler
        self.videoRenderer.drawHandler = drawHandler
        
        super.init(frame: CGRect(origin: .zero, size: CGSize(width:200, height:200)))
        
        prepareMetalLayer()
        
        self.videoRenderer.connectToLayer(self.metalLayer)
                
        // load cursor Image
        
        switch cursorType {
        case .dot:
            if let image = NSImage(named: "cursor_dot.png") {
                cursor = NSCursor(image: image, hotSpot:.zero)
            }else{
                fatalError()
            }
        case .empty:
            if let image = NSImage(named: "cursor_empty.png") {
                cursor = NSCursor(image: image, hotSpot:.zero)
            }else{
                fatalError()
            }
        case .none:
            break            
        }
        
    }
    
    func prepareMetalLayer(){
        guard let dev = MTLCreateSystemDefaultDevice() else {
            fatalError()
        }
        
        self.metalLayer.device = dev
        self.metalLayer.pixelFormat = .bgra8Unorm
        self.metalLayer.framebufferOnly = false
        //self.metalLayer.contentsGravity = .topLeft
        self.metalLayer.contentsGravity = .resizeAspect        
        self.metalLayer.contentsScale = 2.0   // TODO: 環境に応じて変更
        self.metalLayer.drawsAsynchronously = true
        self.metalLayer.removeAllAnimations()
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refleshCapturer(captureDevice: AVCaptureDevice,
                         captureFormat: AVCaptureDevice.Format, captureFrameDuration: CMTime,
                         audioDevice: AVCaptureDevice?){
        
        self.wantsLayer = true
        
        
        self.videoAudioCapturer?.stop()
        
        // VideoAudioCapturer : Video/Audio のキャプチャを担当する
        self.videoAudioCapturer = VideoAudioCapturer(captureDevice: captureDevice,
                                                     captureFormat: captureFormat,
                                                     captureFrameDuration: captureFrameDuration,
                                                     audioDevice: audioDevice,
                                                     manipulatingArea: self.manipulator?.manipulatingArea)
        
        guard let capturer = self.videoAudioCapturer else {
            fatalError("videoAudioCapturer is nil!!")
        }
        
        // VideoAudioCapturer に VideoRenderer をセット -> キャプチャのたびに画面描画する。
        capturer.setVideoRenderer(self.videoRenderer)
        
        let previewAudioOutput = AVCaptureAudioPreviewOutput()
        previewAudioOutput.volume = 1.0
        
        capturer.setAudioOutput(previewAudioOutput)
        
        
        capturer.configureSession()
        
        drawableSizeReflesh()
        metalLayerReflesh()
        
        capturer.start()
    }
    
    func inactive() {
        // キャプチャを停止した上で、表示をリセット。
        self.wantsLayer = true
        
        self.videoAudioCapturer?.stop()
        self.videoRenderer.clear()
        
        self.videoAudioCapturer = nil
        // videoRenderer はそのまま残しておく。
    }
    
    func drawableSizeReflesh() {
        // metalLayerの描画サイズを変更する。 refleshCapturer と layoutから呼び出される。
        
        let cScale = self.metalLayer.contentsScale
        // viewサイズとMetalによるdrawableSizeは等しいものとする。 = metalLayerのcontentsGravityは機能しない。
        let dimensions = self.frame.size
        self.metalLayer.drawableSize = CGSize(width: CGFloat(dimensions.width) * cScale,
                                              height: CGFloat(dimensions.height) * cScale )
        
        print(" drawable dimensions: \(self.metalLayer.drawableSize.width) x \(self.metalLayer.drawableSize.height) ")
    }
    
    
    func metalLayerReflesh() {
        // metalLayer を viewに組み込む
        // initでは、 self.layer は nil. ビュー生成後に呼ばれることを想定。
        
        if let viewLayer = self.layer {
            self.metalLayer.removeFromSuperlayer()
            viewLayer.addSublayer(self.metalLayer)
            viewLayer.backgroundColor = NSColor.black.cgColor
        }else{
            fatalError("viewLayer is nil!! ")
        }
    }
    
    
    override func layout() {
        // layout() はviewサイズ変更があったときに呼ばれる。
        
        print("DisplayView frame did change. \(self.frame.width)x\(self.frame.height)")
        
        CATransaction.begin()
        // アニメーションなし
        CATransaction.setDisableActions(true)
        if let layer = self.layer {
            if let sublayers = layer.sublayers {
                for index in sublayers.indices {
                    sublayers[index].frame = self.frame
                }
            }
        }
        CATransaction.commit()
        // TODO: メニューバーを自動非表示させない場合に、マウスカーソル位置と一致しない。
        self.manipulator?.manipulatingArea.displayDimensions = self.frame.size
        
        print(" metalLayer contentsScale: \(self.metalLayer.contentsScale)")
        
        drawableSizeReflesh()
        
        //親クラスのlayout()を呼ぶ。必須。
        super.layout()
    }
    
    
    // MARK: - for manipulating
    
    override func updateTrackingAreas() {
        // mouseMoved() が値を返すために実装
        super.updateTrackingAreas()
        
        guard manipulator != nil else{
            return
        }
        
        if !trackingAreas.isEmpty {
            for area in trackingAreas {
                removeTrackingArea(area)
            }
        }
        
        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .mouseMoved,
            .cursorUpdate,
            .activeInKeyWindow,
            .inVisibleRect
            //.activeAlways
            //.activeWhenFirstResponder
                
        ]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
        
    }
    
    override func keyDown(with event: NSEvent){
        // do nothing
        // キー押下の際に、ビープ音を発生させないために実装。
        // キーボードの取り扱いは、 KeyboardMonitor内 GCKeyboardによって行う。
    }
    
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    override var acceptsFirstResponder: Bool {
        //  フォーカスが当たっている状態で
        // キー押下の際に、ビープ音を発生させないために実装。
        return true
    }
    
    // mouseMoved は、NSTrackingAreaなどを利用しないと反応しない
    override func mouseMoved(with event: NSEvent){
        delegate?.mouseMoved(event: event, view: self)
    }
    
    override func mouseEntered(with event: NSEvent) {
        //cursorInRectangle = true
        //addCursorRect(self.bounds, cursor: NSCursor(image: cursorImage, hotSpot:.zero))
        delegate?.mouseEntered(event: event)
    }
    
    override func mouseExited(with event: NSEvent) {
        //cursorInRectangle = false
        //NSCursor.arrow.set()
        delegate?.mouseExited(event: event)
    }
        
    override func mouseDown(with event: NSEvent){
        delegate?.mouseDown(event: event)
    }
    
    override func mouseUp(with event: NSEvent){
        delegate?.mouseUp(event: event)
    }
    
    override func rightMouseDown(with event: NSEvent){
        delegate?.rightMouseDown(event: event)
    }
    
    override func rightMouseUp(with event: NSEvent){
        delegate?.rightMouseUp(event: event)
    }
    
    override func otherMouseDown(with event: NSEvent){
        delegate?.otherMouseDown(event: event)
    }
    
    override func otherMouseUp(with event: NSEvent){
        delegate?.otherMouseUp(event: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        delegate?.mouseDragged(event: event, view: self)
    }
        
    override func rightMouseDragged(with event: NSEvent) {
        delegate?.rightMouseDragged(event: event, view: self)
    }
    
    override func otherMouseDragged(with event: NSEvent) {
        delegate?.otherMouseDragged(event: event, view: self)
    }
    
    override func scrollWheel(with event: NSEvent) {
        delegate?.scrollWheel(event: event)
    }
    
    override func cursorUpdate(with event: NSEvent) {
        super.cursorUpdate(with: event)
        cursor?.set()
    }
    
    /*
    override func resetCursorRects() {
        print("resetCursorRects called.")
       // discardCursorRects()
       // addCursorRect(self.visibleRect, cursor: NSCursor(image: cursorImage, hotSpot:.zero))
    }
    */
}

