//
//  Manipulator.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import Foundation
import GameController


class Manipulator : NSObject, ObservableObject, DisplayViewDelegate {
    
    var manipulatingArea: ManipulatingArea
    @Published var converter: ManipulateConverter
    
    // var isValidMouseMotion: Bool = false // マウスカーソルがwindow内にある場合にtrueとする(@ConsoleView)、 mouseMotionを検出を有効にする。
    
    var mouseMoveRelXAccumulation: Float = 0.0
    var mouseMoveRelYAccumulation: Float = 0.0
    
    var manipulatingDeviceType: ManipulatingDeviceType?
        
    var drawHandler : (() -> Void)?
    var lastCursorLocation: CGPoint
    var prevSendCursorLocation: CGPoint
    
    var pointingFrameType : PointingFrameType
    //var isCursorHidden : Bool = false
    
    // var isFullScreen : Bool = false
    
    init(manipulatingArea: ManipulatingArea, converter: ManipulateConverter, pointingFrameType: PointingFrameType) {
        self.manipulatingArea = manipulatingArea
        self.converter = converter
        self.pointingFrameType = pointingFrameType
        
        lastCursorLocation = CGPointZero
        prevSendCursorLocation = CGPointZero
        
        super.init()

        // scnView.delegate = self
        // Set up game controller.
        setup()
        
    }
    
    deinit {
        print("Manipulator deinit.")
    }
   
    
    func setup(){
        
        self.drawHandler = { [weak self] in

            guard let weakself = self else{
                return
            }
            // マウスカーソル移動コマンドについては、drawHandler( 画面描画のタイミング )の頻度で送信する。
            
            if weakself.converter.mousePointingCommandType == .absolute {
                if weakself.prevSendCursorLocation != weakself.lastCursorLocation {
                    if let hLocation = weakself.manipulatingArea.videoLocation(fromViewLocation: weakself.lastCursorLocation) {
                        weakself.converter.mouseCursorMoveAbs(x: hLocation.x, y: hLocation.y, displayDimension: weakself.manipulatingArea.inputDimensions)
                        //print("mouseCursorMoveAbs calld at drawHandler")
                    }
                    weakself.prevSendCursorLocation = weakself.lastCursorLocation
                }
                
            }else{
                if weakself.mouseMoveRelXAccumulation != 0 || weakself.mouseMoveRelYAccumulation != 0 {
                    let displayZoomScale = weakself.manipulatingArea.displayZoomScale
                    
                    weakself.converter.mouseCursorMoveRel(x: Int(weakself.mouseMoveRelXAccumulation / Float(displayZoomScale) ),
                                                          y: Int(weakself.mouseMoveRelYAccumulation / Float(displayZoomScale) ) )
                    //print("mouseCursorMoveRel calld at drawHandler")
                    weakself.mouseMoveRelXAccumulation = 0
                    weakself.mouseMoveRelYAccumulation = 0
                }
                
            }
        }
        
    }
    
    
    func convertPointOrigin(_ point: NSPoint, from: PointingFrameType, to: PointingFrameType) -> CGPoint {
                
        if from == PointingFrameType.bottomleft && to == PointingFrameType.topleft {
            return CGPoint(x: point.x, y: manipulatingArea.displayDimensions.height - point.y)
        }else if from == PointingFrameType.topleft && to == PointingFrameType.bottomleft {
            return CGPoint(x: point.x, y: point.y - manipulatingArea.displayDimensions.height )
        }else{
            return CGPoint(x: point.x, y: point.y)
        }
    }
    
    private func updateAbsoluteMouseCursorLocation(_ location: CGPoint, frameType: PointingFrameType) {
        // ConsoleView  continuousHover から呼ばれる
        
        let convertedPoint: CGPoint = self.convertPointOrigin(location, from:frameType, to:self.pointingFrameType)
        
        self.lastCursorLocation = convertedPoint
        
        // print("MouseMoved point:\(location) convertedPoint: \(convertedPoint) ")
        // この後、画面描画のタイミング drawHandler の中でマウスカーソル移動コマンドを送信する。
    }
    
    private func updateRelativeMouseCursorLocation(_ deltaX: Float, _ deltaY: Float, frameType: PointingFrameType){
        // input は bottomleft が前提
        
        mouseMoveRelXAccumulation += deltaX
        
        let from = frameType
        let to = self.pointingFrameType
        
        if from == PointingFrameType.bottomleft && to == PointingFrameType.topleft {
            mouseMoveRelYAccumulation += -deltaY
        }else if from == PointingFrameType.topleft && to == PointingFrameType.bottomleft {
            mouseMoveRelYAccumulation += -deltaY
        }else{
            mouseMoveRelYAccumulation += deltaY
        }
        
        // この後、画面描画のタイミング drawHandler の中でマウスカーソル移動コマンドを送信する。
    }
    
    func reset() {
        self.converter.reset()
    }
    /*
    var isCursorInTitleBarArea : Bool {
        if self.converter.mousePointingCommandType == .absolute {
            if self.lastCursorLocation.y < 35 {
                return true
            }
        }
        return false
    }
    */
    
    // MARK: - DisplayViewDelegate

    func mouseMoved(event: NSEvent, view: NSView){
        
        if self.converter.mousePointingCommandType == .absolute {
            // event.locationInWindow は bottom-leftで出力される.
            self.updateAbsoluteMouseCursorLocation(view.convert(event.locationInWindow, from: nil), frameType: .bottomleft)
        }else{ // .relative
            // event.deltaX/Y は top-leftで出力される.
            self.updateRelativeMouseCursorLocation(Float(event.deltaX), Float(event.deltaY), frameType: .topleft)
        }

        // print("MouseMoved \(event.locationInWindow),  \(event.deltaX), \(event.deltaY)")
        //if isCursorHidden == false {
        //NSCursor.hide()
        //    isCursorHidden = true
        //}
    }
    
    func mouseEntered(event :NSEvent) {
        //print("MouseEntered ")
        /*
        Task {
            // try await Task.sleep(nanoseconds: UInt64(0.5 * 1000 * 1000 * 1000) )
            await MainActor.run{
                //NSCursor.hide()
                //isCursorHidden = true
             }

        }
         */
    }
    
    func mouseExited(event : NSEvent) {
        //print("MouseExited ")
        /*
        Task {
            // try await Task.sleep(nanoseconds: UInt64(0.5 * 1000 * 1000 * 1000) )
            await MainActor.run{
                //NSCursor.unhide()
                //isCursorHidden = false
            }
        }
         */
    }
    
    func mouseDown(event: NSEvent) {
        self.converter.mouseButtonPressed(button: MouseButton.LeftButton, isPressed: true)
    }
    
    func mouseUp(event: NSEvent) {
        self.converter.mouseButtonPressed(button: MouseButton.LeftButton, isPressed: false)
        /*
        // fullscreen時、画面上部をクリックするとマウスカーソルが現れるので、消去する。
        if self.isFullScreen == true && self.isCursorInTitleBarArea == true {
            Task {
                try await Task.sleep(nanoseconds: UInt64(0.2 * 1000 * 1000 * 1000) )
                await MainActor.run{
                    NSCursor.hide()
                    isCursorHidden = true
                }
            }
        }*/
    }
    
    func rightMouseDown(event: NSEvent) {
        self.converter.mouseButtonPressed(button: MouseButton.RightButton, isPressed: true)
    }
    
    func rightMouseUp(event: NSEvent) {
        self.converter.mouseButtonPressed(button: MouseButton.RightButton, isPressed: false)
    }
    
    func otherMouseDown(event: NSEvent) {
        self.converter.mouseButtonPressed(button: MouseButton.MiddleButton, isPressed: true)
           /*
        // fullscreen時、画面上部をクリックするとマウスカーソルが現れるので、消去する。
        if self.isFullScreen == true && self.isCursorInTitleBarArea == true {
            Task {
                try await Task.sleep(nanoseconds: UInt64(0.2 * 1000 * 1000 * 1000) )
                await MainActor.run{
                    NSCursor.hide()
                    isCursorHidden = true
                }
            }
        }*/
    }
    
    func otherMouseUp(event: NSEvent) {
        self.converter.mouseButtonPressed(button: MouseButton.MiddleButton, isPressed: false)
    }
    
    func mouseDragged(event: NSEvent, view: NSView) {

        if self.converter.mousePointingCommandType == .absolute {
            self.updateAbsoluteMouseCursorLocation(view.convert(event.locationInWindow, from: nil), frameType: .bottomleft)
        }else{ // .relative
            self.updateRelativeMouseCursorLocation(Float(event.deltaX), Float(event.deltaY), frameType: .topleft)
        }
        //print("MouseDragged \(event.locationInWindow),  \(event.deltaX), \(event.deltaY)")
        
    }
    
    func rightMouseDragged(event: NSEvent, view: NSView) {
        
        if self.converter.mousePointingCommandType == .absolute {
            self.updateAbsoluteMouseCursorLocation(view.convert(event.locationInWindow, from: nil), frameType: .bottomleft)
        }else{ // .relative
            self.updateRelativeMouseCursorLocation(Float(event.deltaX), Float(event.deltaY), frameType: .topleft)
        }
        //print("rightMouseDragged \(event.locationInWindow),  \(event.deltaX), \(event.deltaY)")

    }
    
    
    func otherMouseDragged(event: NSEvent, view: NSView) {
        
        if self.converter.mousePointingCommandType == .absolute {
            self.updateAbsoluteMouseCursorLocation(view.convert(event.locationInWindow, from: nil), frameType: .bottomleft)
        }else{ // .relative
            self.updateRelativeMouseCursorLocation(Float(event.deltaX), Float(event.deltaY), frameType: .topleft)
        }
        // print("otherMouseDragged \(event.locationInWindow),  \(event.deltaX), \(event.deltaY)")

    }
    
    func scrollWheel(event: NSEvent) {
        
        // deltaYは切り上げ(ceil)。 deltaY=0.1の場合、1とする。
        var convertedScrollValue = 0.0
        if event.scrollingDeltaY > 0 {
            convertedScrollValue = ceil(event.scrollingDeltaY)
        }else{
            convertedScrollValue = floor(event.scrollingDeltaY)
        }
        // print("scroll value \(convertedScrollValue)")
        self.converter.scrollChanged(scrollValue:Int(convertedScrollValue))
    }
}
