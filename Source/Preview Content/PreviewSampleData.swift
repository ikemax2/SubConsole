//
//  PreviewSampleData.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import SwiftData

@MainActor
class SampleData {
    static let previewDataContainer: ModelContainer = {
        do {
            let container = try ModelContainer(
                for: ConsoleSetting.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            
            let modelContext = container.mainContext
            if try modelContext.fetch(FetchDescriptor<ConsoleSetting>()).isEmpty {
                SampleSettings.contents.forEach {
                    container.mainContext.insert($0)
                }
            }
            return container
            
        }catch{
            fatalError("Failed to create Sample Container.")
        }
    }()
}

