//
//  ConsoleSettingTypes.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//

enum ManipulatingDeviceType : String, CaseIterable, Identifiable, Codable {
    case CH9329 = "CH9329"
    
    var id: String { self.rawValue }
}

enum PointingCommandType : Int8, CaseIterable, Identifiable, Codable {
    case absolute = 0
    case relative = 1
    
    var id: Int8 { self.rawValue }
    
    var description : String {
        switch self {
        case .absolute :
            return "Absolute"
        case .relative :
            return "Relative"
        }
    }
}

enum PointingFrameType : Int8, CaseIterable, Identifiable, Codable {
    case topleft = 0 // "Top-Left"
    case bottomleft = 1 // "Bottom-Left"
    
    var id: Int8 { self.rawValue }
    
    var description : String {
        switch self {
        case .topleft :
            return "Top-Left"
        case .bottomleft :
            return "Bottom-Left"
        }
    }
}

enum CursorType : Int8, CaseIterable, Identifiable, Codable {
    //case none = nil // "system default"
    case dot = 1 // "dot"
    case empty = 2 // "empty"
    
    var id: Int8 { self.rawValue }
    
    var description : String {
        switch self {
        case .dot :
            return "Dot"
        case .empty :
            return "Empty"
        }
    }
}
