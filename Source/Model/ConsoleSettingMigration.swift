//
//  ConsoleSettingMigration.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import Foundation
import SwiftData

// マイグレーションプランを作成する。
enum ConsoleSettingMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ConsoleSettingSchemaV1.self, ConsoleSettingSchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [MigrationV1toV2.excecute]
    }
    
    fileprivate class MigrationV1toV2 {
        static var new = [ConsoleSettingSchemaV2.ConsoleSetting]()
        
        static let excecute = MigrationStage.custom(
            fromVersion: ConsoleSettingSchemaV1.self,
            toVersion: ConsoleSettingSchemaV2.self,
            willMigrate: { context in
                print("willMigrate start V1->V2")
                do {
                    let old = try context.fetch(FetchDescriptor<ConsoleSettingSchemaV1.ConsoleSetting>())
                               
                    new = old.map {
                        var s = ConsoleSettingSchemaV2.ConsoleSetting(name: $0.name)
                        
                        s.id = $0.id
                        s.videoDeviceID0 = $0.videoDeviceID0
                        s.videoDeviceName0 = $0.videoDeviceName0
                        s.videoDeviceFormatString0 = $0.videoDeviceFormatString0
                        s.videoDeviceFrameDurationString0 = $0.videoDeviceFrameDurationString0
                        s.audioDeviceID0 = $0.audioDeviceID0
                        s.audioDeviceName0 = $0.audioDeviceName0
                        s.manipulatingDeviceType0 = $0.manipulatingDeviceType0
                        s.manipulatingSerialPath0 = $0.manipulatingSerialPath0
                        s.manipulatingSerialBaudRate0 = $0.manipulatingSerialBaudRate0
                        
                        s.mousePointingCommandType0 = $0.mousePointingCommandType0
                        s.mousePointingFrameType0 = $0.mousePointingFrameType0
                        
                        s.windowFullScreenStarting = $0.windowFullScreenStarting
                        s.preventDisplaySleep = $0.preventDisplaySleep
                        
                        return s
                    }
                }catch {
                    fatalError()
                }
                
                do {
                    try context.delete(model: ConsoleSettingSchemaV1.ConsoleSetting.self)
                    try context.save()
                }catch {
                    
                }
            },
            didMigrate: { context in
                print("didMigrate start V1->V2")
                new.forEach { context.insert($0) }
                do {
                    try context.save()
                }catch {
                    fatalError("can't save.")
                }
            }
        )
    }
}

