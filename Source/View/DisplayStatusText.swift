//
//  DisplayStatusText.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import SwiftUI

struct DisplayStatusText: View {

    var displayStatus:Binding<DisplayStatus?>
    
    var text : String {
        
        if let dStatus = displayStatus.wrappedValue {
            
            var str = "PixelFormat: \(dStatus.mediaSubtype), "
            str += "Resolution: \(dStatus.resolution), "
            str += "FrameRate: \(String(format:"%.2f", dStatus.framerate))"
            return str
        }else{
            return ""
        }
        
    }
    
    var body: some View {
        Text(text)
    }

}
