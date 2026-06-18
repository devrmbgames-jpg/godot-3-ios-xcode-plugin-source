//
//  amplitude_fix.swift
//  KnowledgePark3D
//
//  Created by RMB Games - Educational Academy on 4/17/26.
//  Copyright © 2026 GodotEngine. All rights reserved.
//

import Foundation


import AmplitudeSwift

@objc(GodotAMPFix)
public class ObjCAmplitudeFixSwift: NSObject {
    
    
    
    @objc public func removeLegacyAmplitudeDatabase(instanceName: String = "") {
        let fm = FileManager.default
        guard let libraryURL = fm.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            return
        }
        
        var dbName = "com.amplitude.database"
        if !instanceName.isEmpty && instanceName.lowercased() != "$default_instance" {
            dbName += "_\(instanceName.lowercased())"
            
        }
        
        let dbURL = libraryURL.appendingPathComponent(dbName)
        let shmURL = libraryURL.appendingPathComponent(dbName + "-shm")
        let walURL = libraryURL.appendingPathComponent(dbName + "-wal")
        
        [dbURL, shmURL, walURL].forEach { url in
            if fm.fileExists(atPath: url.path) {
                try? fm.removeItem(at: url)
            }
        }
    }
}
