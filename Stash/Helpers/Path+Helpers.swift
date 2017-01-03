//
//  Path+Helpers.swift
//  Stash
//
//

import FileKit
import IDZSwiftCommonCrypto

extension Path {
    public func calculateChecksum() -> String {
        guard let stream = inputStream() else { fatalError("No hash.  This shouldn't happen...") }
        
        let digest = Digest(algorithm: .md5)
        var inputBuffer = Array<UInt8>(repeating: 0, count: 4096)
        
        stream.open()
        while stream.hasBytesAvailable {
            let count = stream.read(&inputBuffer, maxLength: inputBuffer.count)
            let _ = digest.update(buffer: &inputBuffer, byteCount: count)
        }
        stream.close()
        
        return hexString(fromArray: digest.final())
    }
}
