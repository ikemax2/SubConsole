//
//  ConsoleToolbar.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA.
//
import SwiftUI

struct ConsoleToolbar: ToolbarContent {
    @Binding var muted: Bool
    
    var body: some ToolbarContent {
        ToolbarItem {
            HStack {
                if muted == true{
                    Image(systemName:"keyboard")
                        .font(.system(size: 20, weight: .medium))
                    Image(systemName:"computermouse")
                        .font(.system(size: 20, weight: .medium))
                }else{
                    Image(systemName:"keyboard.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.red)
                    Image(systemName:"computermouse.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.red)
                    
                }
                    
            }
        }
    }
    
}


