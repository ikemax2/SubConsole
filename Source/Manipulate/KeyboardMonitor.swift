//
//  KeyboardMonitor.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
//      reference: https://developer.apple.com/documentation/gamecontroller/supporting-game-controllers
//
import Foundation
import GameController

class KeyboardMonitor : NSObject, ObservableObject {
    
    private weak var manipulator: Manipulator?
    
    override init(){
        super.init()
        setup()
    }
    
    func setManipulator(_ m : Manipulator?){
        manipulator = m
    }
    
    func setup() {
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCKeyboardDidConnect,
                                               object: nil, queue: nil){ [weak self] notification in
            // キーボードが接続された時に呼ばれる
            // App起動後初回のaddObserverも キーボード接続と判定される
            guard let keyboard = notification.object as? GCKeyboard else {
                return
            }
            print("observer GCKeyboardDidConnect")
            
            self?.registerKeyboard(keyboard)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCKeyboardDidDisconnect,
                                               object: nil, queue: nil){ [weak self] notification in
            // キーボードが接続解除された時に呼ばれる
            self?.unregisterKeyboard()
        }
        
        // App起動後2回目以降の生成の場合に対応
        if let keyboard = GCKeyboard.coalesced {
            registerKeyboard(keyboard)
        }
        
    }

    func unregisterKeyboard() {
        // do nothing
    }
    
    func registerKeyboard(_ keyboardDevice: GCKeyboard){
        
        guard let keyboardInput = keyboardDevice.keyboardInput else {
                return
        }
        
        keyboardInput.keyChangedHandler = {  [weak self]
            (_ deviceInput: GCKeyboardInput, _ ButtonInput: GCControllerButtonInput, _ value: GCKeyCode, _ pressed: Bool) -> Void in
            guard let weakSelf = self else {
                return
            }
            
            weakSelf.manipulator?.converter.keyboardButtonPressed(button: value, isPressed: pressed)
            // print("key pressed \(ButtonInput.description) keyCode: 0x\(String(value.rawValue, radix:16))")
        }
        
    }
    
}
