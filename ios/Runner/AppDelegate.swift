import UIKit
import Flutter
import AVFoundation
import CoreBluetooth

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {

    var audioEngine: AVAudioEngine?
    var centralManager: CBCentralManager!
    var targetPeripheral: CBPeripheral?
    var audioCharacteristic: CBCharacteristic?

    let targetNames = ["btpw"]
    let audioCharacteristicUUID = CBUUID(string: "0000ABCD-0000-1000-8000-00805F9B34FB") // Reemplaza con el UUID real
    let audioServiceUUID = CBUUID(string: "0000FEED-0000-1000-8000-00805F9B34FB") // Reemplaza con el UUID real

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let pttChannel = FlutterMethodChannel(name: "com.pwseries/ptt", binaryMessenger: controller.binaryMessenger)

        pttChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }

            switch call.method {
            case "connectToPW":import UIKit
                               import Flutter
                               import AVFoundation
                               import CoreBluetooth

                               @UIApplicationMain
                               @objc class AppDelegate: FlutterAppDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {

                                   var audioEngine: AVAudioEngine?
                                   var centralManager: CBCentralManager!
                                   var targetPeripheral: CBPeripheral?
                                   var audioCharacteristic: CBCharacteristic?

                                   let targetNames = ["btpw", "bt_pwaudio", "bt_pwdata"]
                                   let audioCharacteristicUUID = CBUUID(string: "0000ABCD-0000-1000-8000-00805F9B34FB") // Reemplaza con el UUID real
                                   let audioServiceUUID = CBUUID(string: "0000FEED-0000-1000-8000-00805F9B34FB") // Reemplaza con el UUID real

                                   override func application(
                                       _ application: UIApplication,
                                       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
                                   ) -> Bool {

                                       let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
                                       let pttChannel = FlutterMethodChannel(name: "com.pwseries/ptt", binaryMessenger: controller.binaryMessenger)

                                       pttChannel.setMethodCallHandler { [weak self] (call, result) in
                                           guard let self = self else { return }

                                           switch call.method {
                                           case "connectToPW":
                                               self.centralManager = CBCentralManager(delegate: self, queue: nil)
                                               result(nil)
                                           case "startPTT":
                                               self.startPTT()
                                               result(nil)
                                           case "stopPTT":
                                               self.stopPTT()
                                               result(nil)
                                           default:
                                               result(FlutterMethodNotImplemented)
                                           }
                                       }

                                       GeneratedPluginRegistrant.register(with: self)
                                       return super.application(application, didFinishLaunchingWithOptions: launchOptions)
                                   }

                                   // MARK: - Bluetooth

                                   func centralManagerDidUpdateState(_ central: CBCentralManager) {
                                       if central.state == .poweredOn {
                                           central.scanForPeripherals(withServices: nil, options: nil)
                                       }
                                   }

func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, ...) {
    if let name = peripheral.name?.lowercased(), targetNames.contains(name) {
        self.targetPeripheral = peripheral
        self.centralManager.stopScan()
        self.centralManager.connect(peripheral, options: nil)
        peripheral.delegate = self
    }
}


                                   func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
                                       peripheral.discoverServices([audioServiceUUID])
                                   }

                                   func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
                                       guard let services = peripheral.services else { return }
                                       for service in services {
                                           peripheral.discoverCharacteristics([audioCharacteristicUUID], for: service)
                                       }
                                   }

                                   func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
                                       guard let characteristics = service.characteristics else { return }
                                       for characteristic in characteristics {
                                           if characteristic.uuid == audioCharacteristicUUID {
                                               self.audioCharacteristic = characteristic
                                               print("✅ Característica de audio encontrada")
                                           }
                                       }
                                   }

                                   // MARK: - Audio (PTT)

                                   func startPTT() {
                                       guard let audioCharacteristic = audioCharacteristic else {
                                           print("❌ Característica de audio no disponible")
                                           return
                                       }

                                       try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                                       try? AVAudioSession.sharedInstance().setActive(true)

                                       let engine = AVAudioEngine()
                                       let inputNode = engine.inputNode
                                       let bus = 0
                                       let format = inputNode.inputFormat(forBus: bus)

                                       inputNode.installTap(onBus: bus, bufferSize: 1024, format: format) { buffer, _ in
                                           let floatData = buffer.floatChannelData![0]
                                           let frameCount = Int(buffer.frameLength)
                                           var pcmData = Data(capacity: frameCount * 2)

                                           for i in 0..<frameCount {
                                               let clamped = max(-1.0, min(1.0, floatData[i]))
                                               let intSample = Int16(clamped * Float(Int16.max))
                                               pcmData.append(Data(bytes: &intSample, count: 2))
                                           }

                                           let mtu = 180
                                           var offset = 0
                                           while offset < pcmData.count {
                                               let end = min(offset + mtu, pcmData.count)
                                               let chunk = pcmData.subdata(in: offset..<end)
                                               peripheral.writeValue(chunk, for: audioCharacteristic, type: .withoutResponse)
                                               offset = end
                                           }
                                       }

                                       audioEngine = engine
                                       engine.prepare()
                                       try? engine.start()
                                       print("🎙️ PTT iniciado")
                                   }

                                   func stopPTT() {
                                       audioEngine?.stop()
                                       audioEngine?.inputNode.removeTap(onBus: 0)
                                       audioEngine = nil
                                       try? AVAudioSession.sharedInstance().setActive(false)
                                       print("🔇 PTT detenido")
                                   }
                               }

                self.centralManager = CBCentralManager(delegate: self, queue: nil)
                result(nil)
            case "startPTT":
                self.startPTT()
                result(nil)
            case "stopPTT":
                self.stopPTT()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Bluetooth

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name?.lowercased(), targetNames.contains(name) {
            self.targetPeripheral = peripheral
            self.centralManager.stopScan()
            peripheral.delegate = self
            self.centralManager.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([audioServiceUUID])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([audioCharacteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == audioCharacteristicUUID {
                self.audioCharacteristic = characteristic
                print("✅ Característica de audio encontrada")
            }
        }
    }

    // MARK: - Audio (PTT)

    func startPTT() {
        guard let audioCharacteristic = audioCharacteristic else {
            print("❌ Característica de audio no disponible")
            return
        }

        try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try? AVAudioSession.sharedInstance().setActive(true)

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let bus = 0
        let format = inputNode.inputFormat(forBus: bus)

        inputNode.installTap(onBus: bus, bufferSize: 1024, format: format) { buffer, _ in
            let floatData = buffer.floatChannelData![0]
            let frameCount = Int(buffer.frameLength)
            var pcmData = Data(capacity: frameCount * 2)

            for i in 0..<frameCount {
                let clamped = max(-1.0, min(1.0, floatData[i]))
                let intSample = Int16(clamped * Float(Int16.max))
                pcmData.append(Data(bytes: &intSample, count: 2))
            }

            let mtu = 180
            var offset = 0
            while offset < pcmData.count {
                let end = min(offset + mtu, pcmData.count)
                let chunk = pcmData.subdata(in: offset..<end)
                peripheral.writeValue(chunk, for: audioCharacteristic, type: .withoutResponse)
                offset = end
            }
        }

        audioEngine = engine
        engine.prepare()
        try? engine.start()
        print("🎙️ PTT iniciado")
    }

    func stopPTT() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        try? AVAudioSession.sharedInstance().setActive(false)
        print("🔇 PTT detenido")
    }
}
