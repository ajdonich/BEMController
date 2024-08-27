//
//  BEMFreqMsg.swift
//  BEMController
//
//  Created by Alfred J Donich on 8/23/24.
//

import Foundation

struct BEMFreqMsg : CustomStringConvertible {
    private static var _msgcounter: UInt32 = 0
    let datapacket: DataPacket

    init(mHz freq: Int32) {
        BEMFreqMsg._msgcounter += 1
        datapacket = DataPacket(BEMFreqMsg._msgcounter, freq)
    }

    init(_ data: Data) {
        datapacket = DataPacket(data)
    }

    init(_ buffer: UnsafeMutableRawPointer, _ msglen: Int) {
        datapacket = DataPacket(Data(bytesNoCopy: buffer, count: msglen, deallocator: .none))
    }
    
    func toData() -> Data {
        return datapacket.toData()
    }
    
    var description: String {
        return datapacket.description
    }
    
    struct DataPacket {
        let msgid: UInt32
        let mHz: Int32

        init(_ msgid: UInt32 = 0, _ mHz: Int32) {
            self.msgid = msgid
            self.mHz = mHz
        }
        
        init(_ data: Data) {
            self.msgid = 0
            self.mHz = 0
            withUnsafeMutablePointer(to: &self) { ptr in
                data.copyBytes(
                    to: UnsafeMutableBufferPointer(start: ptr, count: 1),
                    from: 0..<MemoryLayout<DataPacket>.size)
            }
        }

        func toData() -> Data {
            var data = Data(capacity: MemoryLayout<DataPacket>.size)
            withUnsafePointer(to: self) { ptr in
                data.append(UnsafeBufferPointer(start: ptr, count: 1))
            }
            return data
        }
        
        var description: String {
            return "(\(self.msgid), \(self.mHz))"
        }
    }
}
