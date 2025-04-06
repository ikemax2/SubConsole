//
//  ManipulateSettingView_CH9329.swift
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
import SwiftUI

struct ManipulateSettingView_CH9329 : View, Equatable {
    
    // Equatable プロトコルを実装する事で、冗長な再描画を防ぐ。(initは更新ごとに呼ばれるが、equalを確認して同じであれば描画はしない。)
    //  https://qiita.com/fuziki/items/6fe7a304b30146ba43c7
    static func == (lhs: ManipulateSettingView_CH9329, rhs: ManipulateSettingView_CH9329) -> Bool {
        return (lhs.portName == rhs.portName && lhs.baudRate == rhs.baudRate)
    }
    
    @Binding var portName: String?
    @Binding var baudRate: Int32?
    
    @StateObject private var converter : ManipulateConverter_CH9329
    
    @State private var selectedPortName : String? = nil
    @State private var selectedBaudRate : Int32 = 9600
        
    @State var isFactoryResetAlertShow: Bool = false

    @State var isFactoryResetResponseShow: Bool = false
    
    @ObservedObject var deviceDiscovery : DeviceDiscovery
    
    let availableBaudRate : [Int32] = [1200,2400,4800,9600,14400,19200,38400,57600,115200]
    
    @State var isWritingBaudRateDialogShow: Bool = false
    @State var newBaudRate: Int32? = 38400
    @State var isSetParamAlertShow : Bool = false
    @State var recentCommandResponse : ManipulateConverter_CH9329.CommandResponse = .unknown

    init(portName: Binding<String?>, baudRate: Binding<Int32?>, deviceDiscovery: DeviceDiscovery) {
        print("ManipulateSettingView initialized")
        self._portName = portName
        self._baudRate = baudRate
        
        self.deviceDiscovery = deviceDiscovery

        self._converter = StateObject(wrappedValue:ManipulateConverter_CH9329(portName: portName.wrappedValue, baudRate: baudRate.wrappedValue, deviceDiscovery: deviceDiscovery))
        
    }
    
    var body: some View {
        VStack{
            Picker(selection: $portName, content: {
                Text(verbatim: "None").tag(String?(nil))
                ForEach(deviceDiscovery.availableSerialPorts.indices, id:\.self) { index in
                    Text(verbatim: deviceDiscovery.availableSerialPorts[index].name).tag(
                        deviceDiscovery.availableSerialPorts[index].name)
                }
            }, label: {
                Text("Port")
                    .frame(maxWidth: 100, alignment:.leading)
            })
            .onChange(of: portName){
                converter.changePort(portName: portName, baudRate: baudRate)
            }
            .onChange(of: deviceDiscovery.availableSerialPorts) {
                if deviceDiscovery.availableSerialPorts.first(where: {$0.name == portName}) == nil {
                    portName = nil as String?
                }
            }
            
            HStack {
                Picker(selection: $baudRate, content: {
                    ForEach(availableBaudRate, id:\.self) { brate in
                        Text(verbatim: "\(brate) bps" ).tag( Optional(brate) )
                    }
                }, label: {
                    Text("BaudRate")
                        .frame(maxWidth: 100, alignment:.leading)
                })
                .onChange(of: baudRate){
                    converter.changePort(portName: portName, baudRate: baudRate)

                }
                .disabled( portName == nil )
            }
            
            HStack {
                Text("Chip Status")
                    .frame(maxWidth: 100, alignment:.leading)
                
                Text(" \(converter.chipConfirmed ? "alive" : "not confirmed" )")
                    .frame(maxWidth: .infinity, alignment:.leading)
                    .padding(.vertical, 3)
                
                Spacer()
            }
            
            
            VStack(alignment: .leading) {
                
                HStack {
                    Text("Chip Information")
                        .frame(maxWidth: .infinity, alignment:.leading)
                    
                    Spacer()
                    
                    Button {
                        converter.getChipInfo()
                        
                    } label: {
                        Text("Reflesh")
                    }
                    .disabled( converter.portIsOpening == false)
                }
                
                ChipInfoTable(converter: converter)
            }
                            
            Divider()
            
            HStack {
                Button {
                    isFactoryResetAlertShow = true
                } label: {
                    Text("Factory Reset")
                }
                .disabled( !(converter.portIsOpening == true && converter.chipConfirmed == true) )
                .confirmationDialog("The setting of CH9329 chip will return to the factory default if continued.",
                                    isPresented: $isFactoryResetAlertShow){
                    
                    Button("OK", role: .destructive){
                        print("factory reset.")
                        Task {
                            let res = await converter.factoryReset()
                            await MainActor.run {
                                recentCommandResponse = res
                                isFactoryResetResponseShow = true
                            }
                        }
                        isFactoryResetAlertShow = false
                    }
                }
                .alert("Notice", isPresented: $isFactoryResetResponseShow) {
                                        
                } message: {
                    Text("factory reset response: \( converter.commandResponseString(recentCommandResponse) )")
                }
                
                Spacer()
                
                Button {
                    isWritingBaudRateDialogShow = true
                } label: {
                    Text("Write BaudRate To Chip")
                }
                .disabled( !(converter.portIsOpening == true && converter.chipConfirmed == true) )
                .sheet(isPresented: $isWritingBaudRateDialogShow, onDismiss: nil) {
                    VStack {
                        Text("Writing BaudRate to Chip")
                            .font(.title3)
                            .frame(maxWidth: .infinity, alignment:.leading)
                        
                        Spacer()
                        VStack {
                            Text("Continue to write the baudrate to the CH9329 chip.")
                                .frame(maxWidth: .infinity, alignment:.leading)
                            
                            Picker(selection: $newBaudRate, content: {
                                ForEach(availableBaudRate, id:\.self) { brate in
                                    Text(verbatim: "\(brate) bps" ).tag( Optional(brate) )
                                }
                            }, label: {
                                Text("New BaudRate")
                                    .frame(maxWidth: 100, alignment:.leading)
                            })
                                
                        }
                        
                        HStack {
                            Spacer(minLength: 50)
                            
                            Button(role: .cancel) {
                                isWritingBaudRateDialogShow = false
                            }label: {
                                Text("Cancel")
                            }
                            
                            Spacer()
                            
                            Button(role: .destructive){
                                Task {
                                    if let nbr = newBaudRate, var newParameter = converter.parameter {
                                        newParameter.serialBaudRate = UInt32(nbr)
                                        let res = await converter.setParameter(newParameter: newParameter)
                                        
                                        await MainActor.run {
                                            recentCommandResponse = res
                                            isSetParamAlertShow = true
                                        }
                                    }
                                    isWritingBaudRateDialogShow = false
                                }
                                
                            } label : {
                                Text("OK")
                                    .foregroundColor(.red)
                            }
                            
                            Spacer(minLength: 50)
                            
                        }.padding()
                        
                    }.padding()
                                                
                }
                .onAppear(){
                    newBaudRate = baudRate
                }
                .alert("Notice", isPresented: $isSetParamAlertShow ) {
                    Button {
                        recentCommandResponse = .unknown
                        isSetParamAlertShow = false
                    }label: {
                        Text("OK")
                    }
                } message: {
                    Text("set Parameter response: \( converter.commandResponseString(recentCommandResponse) )\nTurn off the CH9329 Power and then turn on.")

                }
                
            }
            Spacer()
        }
        .onAppear(){
            // print(" ManipulateSettingView_CH9329 appeared.")
            if converter.portIsOpening == true {
                converter.getChipInfo()
            }
        }
    }
    
    struct ChipInfoTable : View {
                
        @ObservedObject var converter : ManipulateConverter_CH9329

        @State var tableData = [ChipInfoRecord]()
        
        struct ChipInfoRecord : Identifiable {
            var id = UUID()
            
            var title: String
            var data: String?
        }
        
        var body: some View {
            
            Table(tableData) {
                TableColumn("Title") { record in
                    Text(record.title)
                }
                TableColumn("Value") { record in
                    Text(record.data ?? "nil")
                }
            }
            .onChange(of: converter.info){
                tableData = chipInfoData
            }
            .onChange(of: converter.parameter){
                tableData = chipInfoData
            }
            .onChange(of: converter.strings){
                tableData = chipInfoData
            }
            .onAppear(){
                tableData = chipInfoData
            }
            .tableStyle(.inset)
            .padding(.leading)
            
            Text("If the guest computer is powered off, CH9329 will not response to any signals. ")
                .font(.footnote)
                .padding(.leading)
                   
        }
        
        var chipInfoData : [ChipInfoRecord] {
            
            var chipInfoData = [ChipInfoRecord]()
            
            guard let info = converter.info, let parameter = converter.parameter, let strings = converter.strings else {
                return chipInfoData
            }
                        
            chipInfoData.append( ChipInfoRecord(title: "Version", data:info.versionString ) )
            chipInfoData.append( ChipInfoRecord(title: "HID Connected", data: info.connectedString ) )
            chipInfoData.append( ChipInfoRecord(title: "Keyboard Indicator", data: info.indicatorString) )
            chipInfoData.append( ChipInfoRecord(title: "Vendor", data: strings.vendorDescription) )
            chipInfoData.append( ChipInfoRecord(title: "Product", data: strings.productDescription) )
            chipInfoData.append( ChipInfoRecord(title: "Serial Number", data: strings.serialNumberDescription) )
            
            chipInfoData.append( ChipInfoRecord(title: "Action Mode", data: parameter.actionModeString) )
            chipInfoData.append( ChipInfoRecord(title: "Serial Connection Mode", data: parameter.serialComModeString) )
            chipInfoData.append( ChipInfoRecord(title: "Serial Address", data: parameter.serialAddressString ) )
            chipInfoData.append( ChipInfoRecord(title: "Serial Baud Rate", data: parameter.serialBaudRateString ) )
            chipInfoData.append( ChipInfoRecord(title: "Serial Packet Interval", data: parameter.serialPacketIntervalString) )
            chipInfoData.append( ChipInfoRecord(title: "USB VendorID", data: parameter.usbVidString ) )
            chipInfoData.append( ChipInfoRecord(title: "USB ProductID", data: parameter.usbPidString ) )
            chipInfoData.append( ChipInfoRecord(title: "USB-Keyboard Upload Interval", data: parameter.usbUploadIntervalString ) )
            chipInfoData.append( ChipInfoRecord(title: "USB-Keyboard Release Delay", data: parameter.usbReleaseDelayString ) )
            chipInfoData.append( ChipInfoRecord(title: "USB-Keyboard Auto LineFeed Flag", data: parameter.usbAutoLineFeedString ) )
            chipInfoData.append( ChipInfoRecord(title: "USB-Keyboard CR Charactor", data:parameter.usbCarriageReturnCharactorString ) )
            chipInfoData.append( ChipInfoRecord(title: "USB-Keyboard Filtering Charactor", data:parameter.filteringCharactorString ) )
            chipInfoData.append( ChipInfoRecord(title: "USB String Valid Flag", data: parameter.usbStringValidFlagString ) )
            chipInfoData.append( ChipInfoRecord(title: "USB-Keyboard HighSpeed Upload Flag", data: parameter.usbHighSpeedUploadFlagString ) )
            
            return chipInfoData
        }
    }
    
}
