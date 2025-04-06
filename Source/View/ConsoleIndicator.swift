//
//  ConsoleIndicator.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import SwiftUI

struct ConsoleIndicator: View {

    @Binding var consoleStatus: Dictionary<UUID, Bool>
    let id: UUID
    
    var body: some View {
        if let status = consoleStatus[id] {
            if status == true {
                Circle()
                    .fill(Color.green)
            }else{
                Circle()
                    .fill(Color.gray)
            }
        }else{
            Circle()
                .fill(Color.gray)
        }
    }
}
