//
//  SettingListToolbar.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA.
//
import SwiftUI

struct SettingListToolbar: ToolbarContent {
    @Binding var editing: Bool
    @Binding var selectedSettingID: ConsoleSetting.ID?
    @Binding var consoleStatus: Dictionary<UUID, Bool>
    
    let addSetting: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItem {
            Button {
                addSetting()
            } label: {
                Label("Add Setting", systemImage: "plus")
                    .font(.system(size: 20, weight: .medium))
            }
        }
        ToolbarItem {
            Button {
                editing = true
            } label: {
                Label("Edit Setting", systemImage: "pencil")
                    .font(.system(size: 20, weight: .medium))
            }
            .disabled(!editable)
        }
    }
    
    var editable: Bool {
        if let ssid = selectedSettingID {

            let v = consoleStatus[ssid]
            if v == false || v == nil {
                return true
            }else{
                return false
            }
            
        }
        return false
    }
}

