//
//  FPSMeasurer.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA.
//
import Foundation

struct FPSMeasurer {
    
    let startDate =  Date()
    var previousDate : Date? = nil
    var elapsedTime: TimeInterval = 0.0
    var calledCount: Int32 = 0
            
    var updatedTime: TimeInterval = 0.0
    var updatedThreshould : TimeInterval = 1.0
    
    typealias UpdateHandler = (_ fps : Double) -> ()

    mutating func pulse(updateHandler : UpdateHandler?) {
        let cDate = Date()

        if let pDate = previousDate {
            elapsedTime = cDate.timeIntervalSince(pDate)
        }else{
            elapsedTime = cDate.timeIntervalSince(startDate)
        }
        previousDate = cDate
        calledCount += 1
        
        updatedTime += elapsedTime
        if updatedTime > updatedThreshould {
            let fps = Double(calledCount) / updatedTime
            updatedTime = 0.0
            calledCount = 0
            
            updateHandler?(fps)
        }
    }
}
