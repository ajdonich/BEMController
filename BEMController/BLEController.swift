//
//  BLEController.swift
//  BEMController
//
//  Created by Alfred J Donich on 8/22/24.
//

import Foundation
import CoreBluetooth
import SwiftUI

class BLEController: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager?
    private var emagnetPeriferal: CBPeripheral?
    private var mHzCharacteristic: CBCharacteristic?
    private var mHzAcks_a: Binding<[Int32]>? = nil

    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    func bindAckRsp(to value: Binding<[Int32]>) {
        mHzAcks_a = value
    }
    
    func writeFrequency(mHz freq: Int32 = -1, ACK ackbit: Bool = false) {
        if emagnetPeriferal == nil || mHzCharacteristic == nil { return }
        
        let msg = BEMFreqMsg(mHz: freq)
        let data = msg.toData()
        NSLog("writeFrequency \(data.count) bytes : \(data.base64EncodedString()) : \(msg.description)")
        emagnetPeriferal!.writeValue(data, for: mHzCharacteristic!, type: .withoutResponse)
    }
    
    func readFrequency() {
        if emagnetPeriferal == nil || mHzCharacteristic == nil { return }
        emagnetPeriferal!.readValue(for: mHzCharacteristic!)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.centralManager?.scanForPeripherals(withServices: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, 
                        advertisementData: [String : Any], rssi RSSI: NSNumber) 
    {
        if let name = advertisementData["kCBAdvDataLocalName"] as? String {
//            if peripheral.name == nil { NSLog("device: \(name) : rssi \(RSSI) dB") }
//            else { NSLog("device: \(name) : rssi \(RSSI) dB : (\(peripheral.name!))") }

            //if name == "STM32WB" {
            if name == "MyCST" {
            //if name == "P2PSRV1" {
            //if name == "XX-STM32" {
                if peripheral.name == nil { NSLog("discovered device: \(name) (rssi: \(RSSI) dB)") }
                else { NSLog("discovered device: \(name) (rssi: \(RSSI) dB) (name: \(peripheral.name!))") }
                
                emagnetPeriferal = peripheral
                peripheral.delegate = self
                central.connect(peripheral)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let maxlen_w = peripheral.maximumWriteValueLength(for: .withResponse)
        let maxlen_wo = peripheral.maximumWriteValueLength(for: .withoutResponse)
        NSLog("connected to peripheral : maxWriteLen (w_rsp, w/o_rsp): (\(maxlen_w), \(maxlen_wo))")
        
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        if (error != nil) {
            NSLog("discoverServices error: \(error!)")
        } else if peripheral.services == nil {
            NSLog("discoverServices peripheral.services: <nil>")
        } else {
            NSLog("discovered \(peripheral.services!.count) services")
            peripheral.services!.forEach({ srv in
                peripheral.discoverCharacteristics(nil, for: srv)
                NSLog("  UUID: \(srv.uuid)")
            })
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        if (error != nil) {
            NSLog("discoverCharacteristics error: \(error!)")
        } else if service.characteristics == nil {
            NSLog("discoverCharacteristics service.characteristics: <nil>")
        } else {
            NSLog("discovered \(service.characteristics!.count) characteristics")
            service.characteristics!.forEach({ chrt in
                let maxlen_w = peripheral.maximumWriteValueLength(for: .withResponse)
                let maxlen_wo = peripheral.maximumWriteValueLength(for: .withoutResponse)
                NSLog("  UUID: \(chrt.uuid) : maxWriteLen (w, wo): (\(maxlen_w), \(maxlen_wo))")

                peripheral.discoverDescriptors(for: chrt)
                if chrt.uuid.uuidString == "0000FE41-8E22-4541-9D4C-21EDAE82ED19" {
                    mHzCharacteristic = chrt
                }
            })
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: (any Error)?) {
        if (error != nil) {
            NSLog("discoverDescriptors error: \(error!)")
        } else if characteristic.descriptors == nil {
            NSLog("discoverDescriptors characteristic.descriptors: <nil>")
        } else {
            NSLog("discovered \(characteristic.descriptors!.count) descriptors")
            characteristic.descriptors!.forEach({ descr in
                NSLog("   UUID: \(descr.uuid) : descriptor: \(descr)")
            })
        }
    }
    
    //  Callback after CBPeripheral.writeValue(.withResponse)
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if (error != nil) {
            NSLog("writeValue error: \(error!)")
        } else if characteristic.value == nil {
            NSLog("writeValue characteristic UUID: \(characteristic.uuid) : value: <nil>")
        } else {
            NSLog("writeValue characteristic UUID: \(characteristic.uuid) : value: \(characteristic.value!.base64EncodedString())")
        }
    }
    
    //  Callback after CBPeripheral.readValue (or other value update)
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if (error != nil) {
            NSLog("readValue error: \(error!)")
        } else if characteristic.value == nil {
            NSLog("readValue characteristic UUID: \(characteristic.uuid) : value: <nil>")
        } else {
            let data = characteristic.value!
            let msg = BEMFreqMsg(data)
            NSLog("readValue \(data.count) bytes : \(data.base64EncodedString()) : \(msg.description) : UUID: \(characteristic.uuid)")            
        }
    }
}
