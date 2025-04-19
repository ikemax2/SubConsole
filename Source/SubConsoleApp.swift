//
//  SubConsoleApp.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import SwiftUI
import SwiftData

@main
struct SubConsoleApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.dismissWindow) var dismissWindow
    
    @State var consoleStatus = Dictionary<UUID, Bool>()
    
    @StateObject var deviceDiscovery = DeviceDiscovery()
    let keyboardMonitor = KeyboardMonitor()
    
    var sharedModelContainer: ModelContainer = {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as! String
        print("Document Path:"+documentsPath)
        let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0] as! String
        print("Library Path:"+libraryPath)
        
        let schema = Schema([
            ConsoleSetting.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        
        
    }()
    
    var body: some Scene {
        Window("ConsoleList", id: "consoleList") {
            SettingListView(consoleStatus: $consoleStatus, keyboardMonitor: keyboardMonitor, deviceDiscovery: deviceDiscovery)
                .frame(minWidth: 500, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
            .onAppear(){
                
                Task {
                    let window = NSApplication.shared.keyWindow
                    
                    appDelegate.windows[SettingListView.identifier()] = WeakReference(object:window)
                    // window?.identifier = NSUserInterfaceItemIdentifier(SettingListView.identifier())
                }
            }
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .undoRedo) {}
            CommandGroup(replacing: .pasteboard) {}
            CommandGroup(replacing: .textEditing) {}
            CommandGroup(replacing: .windowSize) {}
            CommandGroup(replacing: .windowArrangement) {}
        }
        
        WindowGroup("Console", id:"console", for: ConsoleSetting.self ){ $setting in
            if let s = setting {
                
                ConsoleView(setting: s, keyboardMonitor: keyboardMonitor, deviceDiscovery: deviceDiscovery)
                    .frame(minWidth: 300, idealWidth: 640, maxWidth: .infinity,
                           minHeight: 200, idealHeight: 480, maxHeight: .infinity)
                    .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { notification in
                        if let window = notification.object as? NSWindow {
                            if window.frameAutosaveName == "consoleList" {
                                // if listView is closed, consoleView will be closed.
                                dismissWindow(id: "console")
                            }
                        }
                    }
                    .windowToolbarFullScreenVisibility(.onHover)
                    .onAppear(){
                        consoleStatus[s.id] = true
                        
                        if let scr = NSScreen.screens.first {
                            print("screen width : \(scr.frame.width)x\(scr.frame.height)")
                            print("screen backingScaleFactor \(scr.backingScaleFactor)")
                        }
                                                                                                
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            // TODO: 同時に複数のウィンドウが開くような状況では、正しく動作しない。
                            let window = NSApplication.shared.keyWindow
                            
                            if s.windowFullScreenStarting == true {
                                window?.toggleFullScreen(nil)
                            }
                            
                            appDelegate.windows[ConsoleView.identifier(ssid: s.id)] = WeakReference(object:window)
                            
                            var screenSize = NSSize(width: 1980, height: 1180)
                            if let ms = NSScreen.main {
                                screenSize = ms.frame.size
                            }
                            
                            let size = s.videoSize0
                            
                            let aspectRatio = size.width / size.height
                            let windowSize = NSSize(width: screenSize.width * 0.3,
                                                    height: screenSize.width * 0.3 / aspectRatio)

                            window?.styleMask.remove(.fullSizeContentView)
                            window?.setContentSize(windowSize)
                            window?.contentAspectRatio = NSSize(width: size.width, height: size.height)
                            
                            window?.backgroundColor = NSColor.black  // residual space color when fullscreen mode
                            
                            //window?.identifier = NSUserInterfaceItemIdentifier(ConsoleView.identifier(ssid: s.id))
                            
                        }
                        
                    }
                    .onDisappear(){

                        //manipulatorCoordinator.manipulator(forSetting: s).close()
                        //manipulatorCoordinator.clear(forSetting: s)
                        
                        consoleStatus[s.id] = false
                        // windows.removeValue(forKey: s.id)

                    }
                    // .navigationTitle(s.name)
            }
        }
        //.commandsRemoved()
        .modelContainer(sharedModelContainer)
        // .windowResizability(.contentMinSize)
    }
    
}
