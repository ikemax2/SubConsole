//
//  AppDelegate.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
//      reference: https://github.com/domzilla/Caffeine.git
//
import SwiftUI
import IOKit.pwr_mgt

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    
    var userSessionIsActive : Bool = true
    
    var isPreventingSleep : Bool = false {
        didSet {
            if isPreventingSleep == true {
                activatePreventSleep()
                
            }else{
                // isPreventingSleep => false
                inactivatePreventSleep()
            }
        }
    }
    
    var preventSleepTimer : Timer?
    var sleepAssertionID : IOPMAssertionID?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        //        "アプリ名が書いてあるメニュー" 0
        //        "ファイル" 1
        //        "編集" 2
        //        "フォーマット" 3
        //        "表示(ビルトインの表示)" 4
        //        "ウインドウ" 5
        //        "ヘルプ" 6
        
        // items のサイズがindexを超えて、 例外が上がる。
        /*
        NSApplication.shared.mainMenu?.items[2].isHidden = true
        NSApplication.shared.mainMenu?.items[3].isHidden = true
        NSApplication.shared.mainMenu?.items[4].isHidden = true
        NSApplication.shared.mainMenu?.items[6].isHidden = true
        */
        // 再起動時、以前閉じるときに開いていたwindowsを再度開かないようにする。
        UserDefaults.standard.setValue(false, forKey: "NSQuitAlwaysKeepsWindows")

    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // if last window is closed, application will be terminated.
        return true
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        print("applicationDidBecomeActive")
        userSessionIsActive = true
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        print("applicationDidResignActive")
        userSessionIsActive = false
    }
    
    
    func activatePreventSleep() {
        if preventSleepTimer == nil {
            preventSleepTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { [weak self] timer in
                guard let weakSelf = self else {
                    return
                }
                
                if weakSelf.isPreventingSleep == true && weakSelf.userSessionIsActive == true {
                    // スリープ移行妨害を設定
                    if let aid = weakSelf.sleepAssertionID {
                        IOPMAssertionRelease(aid)
                    }
                    weakSelf.sleepAssertionID = IOPMAssertionID(0)
                    print(kIOPMAssertPreventUserIdleDisplaySleep)
                    IOPMAssertionCreateWithDescription(kIOPMAssertPreventUserIdleDisplaySleep as CFString,
                                                       "SubConsole prevents sleep" as CFString,
                                                       nil,
                                                       nil,
                                                       nil,
                                                       8,  // assertion timeout
                                                       nil,
                                                       &weakSelf.sleepAssertionID!)
                }
            })
        }
        
    }
    
    func inactivatePreventSleep(){
        preventSleepTimer?.invalidate()
        preventSleepTimer = nil
    }
    
}
