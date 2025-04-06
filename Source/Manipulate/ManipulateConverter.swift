//
//  ManipulateConverter.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import GameController

protocol ManipulateConverter {
    
    //var isMouseCursorAbsolute: Bool { get set }
    var mousePointingCommandType : PointingCommandType { get set }
        
    func mouseCursorMoveAbs(x: CGFloat, y: CGFloat, displayDimension: CGSize)
    func mouseCursorMoveRel(x: Int, y: Int)
    func mouseButtonPressed(button: MouseButton, isPressed: Bool)
    func scrollChanged(scrollValue: Int)
    
    func keyboardButtonPressed(button: GCKeyCode, isPressed: Bool)
    
    func reset()
    
    var mute : Bool { get set }
}

enum MouseButton{
    case LeftButton
    case RightButton
    case MiddleButton
}
