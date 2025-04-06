//
//  ManipulateConverter_CH9329.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import SerialGate
import GameController
import SwiftUI

class ManipulateConverter_CH9329: ManipulateConverter, ObservableObject {
    
    // var isMouseCursorAbsolute: Bool = false
    var mousePointingCommandType : PointingCommandType = .absolute
    
    weak var deviceDiscovery : DeviceDiscovery?
    
    @Published var info : Info_CH9329?
    @Published var parameter : Parameter_CH9329?
    @Published var strings : UsbStrings_CH9329?
    
    private weak var port: SGPort?  // SGPortの保持は、 DeviceDiscoveryが担当
    private var baudRate : Int32
    
    @Published var portIsOpening = false
    @Published var chipConfirmed = false
    
    private var dataReceiveTask: Task<Void, Never>?
    
    @Published var mute : Bool = false {
        didSet{
            self.allKeyButtonRelease()
        }
    }
    
    init(portName inputPortName: String?, baudRate inputBaudRate: Int32?, deviceDiscovery: DeviceDiscovery){
        // ManipulateSettingView_CH9329から呼ばれるイニシャライザ  設定画面で info/parameter/strings などを表示するため
        print("ManipulateConverter initialized.")
        self.deviceDiscovery = deviceDiscovery
        
        let selectedPort =  deviceDiscovery.availableSerialPorts.first(where: {$0.name == inputPortName})
        self.baudRate = inputBaudRate ?? 9600

        select(port: selectedPort)
        
        // @StateObject として定義された場合には、以前のconverterが存在しつつ、新しいconverterが生成されることがある
        // SGPort は deviceDiscoveryから取得し、その中にopen/close状態も含まれ、それを引き継ぐ。
        if self.port?.portState == .open {
            portIsOpening = true
        }else{
            openPort()
        }

    }
        
    convenience init(setting: ConsoleSetting, deviceDiscovery: DeviceDiscovery){
        // ConsoleViewから呼ばれるイニシャライザ  マウス/キーボード入力の変換を行うため
        let inputPortName = setting.manipulatingSerialPath0
        let inputBaudRate = setting.manipulatingSerialBaudRate0
        
        self.init(portName: inputPortName, baudRate: inputBaudRate, deviceDiscovery: deviceDiscovery)
        
        //self.isMouseCursorAbsolute = setting.mouseCursorAbsolute0
        self.mousePointingCommandType = setting.mousePointingCommandType0
    }
            
    func close(){
        dataReceiveTask?.cancel()
        closePort()
        select(port: nil)
        
        dataReceiveTask = nil
        info = nil
        parameter = nil
        strings = nil
        chipConfirmed = false
    }
    
    deinit{
        // @StateObject として定義されると、なかなかdeinitが呼ばれることはない
        print("ManipulateConverter deinit called")
        close()
    }
    
    func changePort(portName inputPortName: String?, baudRate inputBaudRate: Int32?) {
        print("changePort called.")
        
        close()
            
        let selectedPort = deviceDiscovery?.availableSerialPorts.first(where: {$0.name == inputPortName})
        self.baudRate = inputBaudRate ?? 9600
            
        select(port: selectedPort)
        if self.port?.portState == .open {
            portIsOpening = true
        }else{
            openPort()
        }
    }
        

    
    private func select(port: SGPort?) {
        self.port = port
    }
    
    private func openPort() {
        // print("openPort start port: \(self.port?.name), open:\(portIsOpening)")
        guard let port, !portIsOpening else { return }
        do {
            try port.set(baudRate: self.baudRate)
            try port.open()
            self.portIsOpening = true
            print("ManipulateConverter_CH9329  port open success. portName: \(port.name) bRate: \(self.baudRate)")

        } catch {
            print(error.localizedDescription)
        }

    }

    private func closePort() {
        // print("closePort port: \(self.port?.name), open:\(portIsOpening)")
        guard let port, portIsOpening else { return }
        do {
            try port.close()
            self.portIsOpening = false
            print("ManipulateConverter_CH9329  port close success. portName: \(port.name)" )
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func sendPort(_ bytes: [UInt8], ignoreMute: Bool = false){
        
        guard let port, portIsOpening else { return }
        
       if ignoreMute == true || self.mute == true {
            return
       }
        
        let d = Data(bytes: bytes, count: bytes.count)
        
        do {
            try port.send(data: d)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func checksum(_ bytes: [UInt8]) -> UInt8 {
        // checksum: all data sum include frame-Header, pick up lower byte
        let c: UInt16 = bytes.reduce(0) { result, element in
            result + UInt16(element)
        }
        
        return UInt8(c & 0x00ff)
    }
    
    

    func request(command: [UInt8]) async -> [UInt8]? {
        
        if self.port == nil {
            print("can't request  port is nil")
            return nil
        }
        
        // withCheckedContinuation : continuation.resume(...) が呼ばれるまで待つ
        // https://zenn.dev/ueeek/articles/20230820swift_evolution_continuation
        let requestResult = await withCheckedContinuation  { continuation in
            
            // コマンド受信準備
            dataReceiveTask = Task {
                do {
                    let result = try await withThrowingTaskGroup(of: [UInt8].self) { group in
                        group.addTask { [weak self] in
                            var responseBuffer : [UInt8] = [UInt8]()
                            
                            guard let sPort = self?.port else {
                                throw CancellationError()
                            }
                            
                            for await rData in sPort.dataStream {
                                switch rData {
                                case let .success(sBuffer):
                                    // print("received text: \(sBuffer.encodedHexadecimals)")
                                    responseBuffer.append(contentsOf: sBuffer)
                                    let rd = responseBuffer.count
                                    if rd > 4 {
                                        if responseBuffer[0] == 0x57 && responseBuffer[1] == 0xAB && responseBuffer[2] == 0x00 {
                                            var rc = responseBuffer[4]
                                            rc += 6
                                            // print("return response length:\(rc), buffer length:\(responseBuffer.count)")
                                            
                                            let bufferCount = responseBuffer.count
                                            if rc > bufferCount {
                                                // 読み込み中。まだ全てのresponseを受け取っていない。 responseBuffer をそのままに、次のbuffer読み込みを待つ。
                                            }else{
                                                // 読み込み完了。
                                                return responseBuffer
                                            }
                                        }else{
                                            print("invalid header.")
                                        }
                                    }
                                    
                                case let .failure(error):
                                    print(error.localizedDescription)
                                }
                            }
                            
                            return responseBuffer
                        }
                        
                        group.addTask {
                            let timeout = Duration.seconds(2)
                            try await Task.sleep(for: timeout)
                            throw CancellationError()
                        }
                        
                        // タイムアウトの実装  上記二つのtaskでタイムレースする
                        // https://zenn.dev/kyome/articles/716138e3640893
                        defer {
                            group.cancelAll()
                        }
                        
                        //先に終わったタスクが r に代入される。 時間測定のタスクは何も返さないので、その場合はタイムアウトということ。
                        guard let r = try await group.next() else {
                            throw CancellationError()
                        }
                        return r
                    }
                    // print("data received count: \(result.count)")
                    
                    continuation.resume(returning: Optional(result))
                    
                } catch {
                    print(error.localizedDescription)
                    continuation.resume(returning: nil)
                }
            }
            
            Task {
                do {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒待つ処理
                }catch{
                    print(error.localizedDescription)
                }                
                // コマンド送信
                self.sendPort(command)
            }
            
        }
        
        dataReceiveTask?.cancel()
        return requestResult
    }
    
    // MARK: - for Chip Setting
    
    enum CommandResponse: UInt8 {
        case success = 0x00
        case timeout = 0xE1
        case headerByteError = 0xE2
        case codeError = 0xE3
        case checkSumError = 0xE4
        case parameterError = 0xE5
        case operationError = 0xE6
        case unknown
    }
    
    func commandResponseString(_ response: CommandResponse) -> String{
        
        var str = String()
        switch response {
        case .success: str += "Success"
        case .timeout: str += "TimeOut"
        case .headerByteError: str += "HeaderByteError"
        case .codeError: str += "CodeError"
        case .checkSumError: str += "CheckSumError"
        case .parameterError: str += "ParameterError"
        case .operationError: str += "OperationError"
        default: str += "Unknown Response"
        }
        
        return str
    }
    
    func getChipInfo(){
        Task {
            if let info = await getInfo(), let strings = await getUsbStrings(), let parameter = await getParameter() {
                
                await MainActor.run {
                    self.info = info
                    self.strings = strings
                    self.parameter = parameter
                    self.chipConfirmed = true
                }
                
            }else{
                print("getChipInfo failed.")
            }
        }
    }
    
    
    func getInfo() async -> Info_CH9329? {
        // print("getInfo called.")
        
        // CMD_GET_INFO 0x01
        let b: [UInt8] = [0x57, 0xAB, 0x00, 0x01, 0x00, 0x03]  // checksum込み
        
        if let buffer = await self.request(command: b) {
            if buffer.count < 8 {
                print("getInfo response is incomplete.")
                return nil
            }
            
            if buffer[3] == 0x81 {
                // response for CMD_GET_INFO
                return Info_CH9329(buffer: Array(buffer[5...7]))
            }
        }
        
        return nil
    }
    
    
    func getUsbStrings() async -> UsbStrings_CH9329? {
        // print("getUsbStrings called.")
        
        var retStrings = UsbStrings_CH9329()
        
        // CMD_GET_USB_STRING 0x0A
        var b2: [UInt8] = [0x57, 0xAB, 0x00, 0x0A, 0x01, 0x02]
        b2.append(checksum(b2))
        
        if let buffer = await self.request(command: b2) {
            if buffer.count < 5 {
                print("getUsbStrings response is incomplete.")
                return nil
            }
            
            if buffer[3] == 0x8A {
                // response for CMD_GET_USB_STRING
                var sBuffer = buffer
                sBuffer.removeSubrange(0...4)
                retStrings.append(buffer: sBuffer)
            }else{
                return nil
            }
        }
        
        
        var b3: [UInt8] = [0x57, 0xAB, 0x00, 0x0A, 0x01, 0x01]
        b3.append(checksum(b3))
        
        if let buffer = await self.request(command: b3) {
            if buffer.count < 5 {
                print("getUsbStrings response is incomplete.")
                return nil
            }
            
            if buffer[3] == 0x8A {
                // response for CMD_GET_USB_STRING
                var sBuffer = buffer
                sBuffer.removeSubrange(0...4)
                retStrings.append(buffer: sBuffer)
            }else{
                return nil
            }
        }
        
        var b4: [UInt8] = [0x57, 0xAB, 0x00, 0x0A, 0x01, 0x00]
        b4.append(checksum(b4))
        
        if let buffer = await self.request(command: b4) {
            if buffer.count < 5 {
                print("getUsbStrings response is incomplete.")
                return nil
            }
            
            if buffer[3] == 0x8A {
                // response for CMD_GET_USB_STRING
                var sBuffer = buffer
                sBuffer.removeSubrange(0...4)
                retStrings.append(buffer: sBuffer)
            }else{
                return nil
            }
        }
        
        return retStrings
    }
    
    
    func getParameter() async -> Parameter_CH9329? {
        // print("getParameter called.")
        
        // CMD_GET_PARA_CFG 0x08
        var b5: [UInt8] = [0x57, 0xAB, 0x00, 0x08, 0x01, 0x00]
        b5.append(checksum(b5))
        
        if let buffer = await self.request(command: b5) {
            if buffer.count < 55 {
                print("getParameter response is incomplete.")
                return nil
            }
            
            if buffer[3] == 0x88 {
                // response for CMD_GET_PARA_CFG
                return Parameter_CH9329(buffer: Array(buffer[5...54]))
            }
        }
        
        return nil
    }
    
    func setParameter(newParameter: Parameter_CH9329) async -> CommandResponse {
        // print("setNewParameter called.")
        
        // CMD_SET_PARA_CFG 0x09
        var b2: [UInt8] = [0x57, 0xAB, 0x00, 0x09, 0x32]
        b2.append(contentsOf: newParameter.encodedBytes())
        b2.append(self.checksum(b2))
        
        if let buffer = await self.request(command: b2) {
            if buffer.count < 6 {
                print("setParameter response is incomplete.")
                return CommandResponse.unknown
            }
            
            if buffer[3] == 0x89 {
                // response for CMD_SET_PARA_CFG
                let response = CommandResponse(rawValue:buffer[5]) ?? .unknown
                print("set new parameter result: \(commandResponseString(response))")
                
                return response
            }
        }
        
        return CommandResponse.unknown
    }
    
    
    func factoryReset() async -> CommandResponse {
        var b2: [UInt8] = [0x57, 0xAB, 0x00, 0x0C, 0x00]
        b2.append(checksum(b2))
        
        if let buffer = await self.request(command: b2) {
            if buffer.count < 6 {
                print("factoryReset response is incomplete.")
                return CommandResponse.unknown
            }
            
            if buffer[3] == 0x8c {
                // response for CMD_SET_DEFAULT_CFG
                let response = CommandResponse(rawValue:buffer[5]) ?? .unknown
                print("set default configuration result: \(commandResponseString(response))")
                
                return response
            }
        }
        
        return CommandResponse.unknown
    }
    
    
    func sendReset() async -> CommandResponse {
        var b2: [UInt8] = [0x57, 0xAB, 0x00, 0x0F, 0x00]
        b2.append(checksum(b2))
        
        if let buffer = await self.request(command: b2) {
            if buffer.count < 6 {
                print("sendReset response is incomplete.")
                return CommandResponse.unknown
            }
            
            if buffer[3] == 0x8F {
                // response for CMD_RESET
                let response = CommandResponse(rawValue:buffer[5]) ?? .unknown
                print("reset result: \(commandResponseString(response))")
                
                return response
            }
        }
        
        return CommandResponse.unknown
    }
    
    
    // MARK: - for ManipulateConverter
    
    var mouseAbsXvalLower: UInt8 = 0
    var mouseAbsXvalUpper: UInt8 = 0
    var mouseAbsYvalLower: UInt8 = 0
    var mouseAbsYvalUpper: UInt8 = 0
    
    var mouseModifier: UInt8 = 0
    
    func mouseCursorMoveAbs(x: CGFloat, y: CGFloat, displayDimension: CGSize){
        //if isMouseCursorAbsolute == false {
        if mousePointingCommandType == .relative {
            return
        }

        guard displayDimension.width > 0 && displayDimension.height > 0 else {
            return
        }
        
        let xval: UInt16 = UInt16(4096.0 * x / displayDimension.width)
        let yval: UInt16 = UInt16(4096.0 * y / displayDimension.height)
        // print("CH9329 x:\(x),  width:\(videoInformation.inputDimensions.width)")
        
        mouseAbsXvalLower = UInt8(xval & 0x00ff)
        mouseAbsXvalUpper = UInt8(xval >> 8)
        mouseAbsYvalLower = UInt8(yval & 0x00ff)
        mouseAbsYvalUpper = UInt8(yval >> 8)
        
        var b: [UInt8] = [
            0x57,
            0xAB,
            0x00,
            0x04,
            0x07,
            0x02,
            mouseModifier,
            mouseAbsXvalLower,
            mouseAbsXvalUpper,
            mouseAbsYvalLower,
            mouseAbsYvalUpper,
            0x00
        ]
        // print("mousemodifier : \(mouseModifier)")
        b.append(checksum(b))
        
        self.sendPort(b) // responseを確認しない
    }
    
    func mouseCursorMoveRel(x: Int, y: Int){
        //if isMouseCursorAbsolute == true {
        if mousePointingCommandType == .absolute {
            return
        }
        
        var px = x
        var py = y
        if (px > 127) {
            px = 127
        }
        if (px < -128) {
            px = -128
        }
        if (py > 127) {
            py = 127
        }
        if (py < -128) {
            py = -128
        }
            
        if (px < 0) {
            px = 0x100 + px
        }
        if (py < 0) {
            py = 0x100 + py
        }
        
        var b: [UInt8] = [0x57, 0xAB, 0x00, 0x05, 0x05, 0x01, mouseModifier, UInt8(px), UInt8(py), 0x00]
        
        b.append(checksum(b))
        
        self.sendPort(b) // responseを確認しない
    }
    
    func mouseButtonPressed(button: MouseButton, isPressed: Bool){
        
        switch button {
        case .LeftButton:
            mouseModifier = isPressed ? 0x01 | mouseModifier : ~(0x01) & mouseModifier
        case .RightButton:
            mouseModifier = isPressed ? 0x02 | mouseModifier : ~(0x02) & mouseModifier
        case .MiddleButton:
            mouseModifier = isPressed ? 0x04 | mouseModifier : ~(0x04) & mouseModifier
        }
        // print("mouseModifier: \(mouseModifier)")

        //if isMouseCursorAbsolute == true {
        if mousePointingCommandType == .absolute {
            
            var b: [UInt8] = [0x57, 0xAB, 0x00, 0x04, 0x07, 0x02,
                              mouseModifier,
                              mouseAbsXvalLower,
                              mouseAbsXvalUpper,
                              mouseAbsYvalLower,
                              mouseAbsYvalUpper,
                              0x00]
            b.append(checksum(b))
            self.sendPort(b)
            
        }else {
            var b: [UInt8] = [0x57, 0xAB, 0x00, 0x05, 0x05, 0x01, mouseModifier, 0x00, 0x00, 0x00]
            b.append(checksum(b))
            self.sendPort(b)
        }
    }
    
    func scrollChanged(scrollValue: Int){
        var ps = scrollValue
        if ps > 127 {
            ps = 127
        }
        if ps < -127 {
            ps = -127
        }

        if ps < 0 {
            ps = 0x100+ps
        }
        
        let scrollModifier = UInt8(ps)
        
        //if isMouseCursorAbsolute == true {
        if mousePointingCommandType == .absolute {
            var b: [UInt8] = [0x57, 0xAB, 0x00, 0x04, 0x07, 0x02,
                              mouseModifier,
                              mouseAbsXvalLower,
                              mouseAbsXvalUpper,
                              mouseAbsYvalLower,
                              mouseAbsYvalUpper,
                              scrollModifier]
            b.append(checksum(b))
            self.sendPort(b)
            
        }else {
            var b: [UInt8] = [0x57, 0xAB, 0x00, 0x05, 0x05, 0x01, mouseModifier, 0x00, 0x00, scrollModifier]
            b.append(checksum(b))
            self.sendPort(b)
            
        }
        
    }
    
    var keyboardModifier: UInt8 = 0
    var keyboardGeneralKeys: [UInt8] = []
    
    func keyboardButtonPressed(button: GCKeyCode, isPressed: Bool){
        
        switch button {
        case .leftControl:
            keyboardModifier = isPressed ? 0x01 | keyboardModifier : ~(0x01) & keyboardModifier
        case .leftShift:
            keyboardModifier = isPressed ? 0x02 | keyboardModifier : ~(0x02) & keyboardModifier
        case .leftAlt:
            keyboardModifier = isPressed ? 0x04 | keyboardModifier : ~(0x04) & keyboardModifier
        case .leftGUI:
            keyboardModifier = isPressed ? 0x08 | keyboardModifier : ~(0x08) & keyboardModifier
        case .rightControl:
            keyboardModifier = isPressed ? 0x10 | keyboardModifier : ~(0x10) & keyboardModifier
        case .rightShift:
            keyboardModifier = isPressed ? 0x20 | keyboardModifier : ~(0x20) & keyboardModifier
        case .rightAlt:
            keyboardModifier = isPressed ? 0x40 | keyboardModifier : ~(0x40) & keyboardModifier
        case .rightGUI:
            keyboardModifier = isPressed ? 0x80 | keyboardModifier : ~(0x80) & keyboardModifier
        default:
            if isPressed == true {
                keyboardGeneralKeys.append(UInt8(button.rawValue))
            }else{
                var i = keyboardGeneralKeys.count - 1
                while( i >= 0 ){
                    if keyboardGeneralKeys[i] == UInt8(button.rawValue) {
                        _ = keyboardGeneralKeys.remove(at:i)
                    }
                    i -= 1
                }
            }
        }
        // print("keyboardModifier: \(keyboardModifier)")
        
        var b: [UInt8] = [0x57, 0xAB, 0x00, 0x02, 0x08, keyboardModifier, 0x00]
            
        var j = 0
        keyboardGeneralKeys.forEach { element in
            b.append(element)
            j += 1
        }
        
        while(j < 6){
            b.append(0x00)
            j += 1
        }
        
        b.append(checksum(b))
        self.sendPort(b)
        
    }
    
    func chipReset() {
        Task {
            _ = await sendReset()
            keyboardModifier = 0
            keyboardGeneralKeys = [UInt8]()
            mouseModifier = 0
            
            mouseAbsXvalLower = 0
            mouseAbsXvalUpper = 0
            mouseAbsYvalLower = 0
            mouseAbsYvalUpper = 0
        }
    }
    
    func reset() {
        keyboardModifier = 0
        keyboardGeneralKeys = [UInt8]()
        mouseModifier = 0
        
        mouseAbsXvalLower = 0
        mouseAbsXvalUpper = 0
        mouseAbsYvalLower = 0
        mouseAbsYvalUpper = 0
        
        self.allKeyButtonRelease()
    }
    
    func allKeyButtonRelease(){
        // print("allKeyButtonRelease")
        // 修飾キー 全て送信 OFF
        var b2: [UInt8] = [0x57, 0xAB, 0x00, 0x02, 0x08, 0x00, 0x00]
        var j = 0
        while(j < 6){
            b2.append(0x00)
            j += 1
        }
        b2.append(checksum(b2))
        self.sendPort(b2)
        
    }

}

