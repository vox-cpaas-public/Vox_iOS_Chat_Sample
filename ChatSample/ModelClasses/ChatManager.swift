//
//  ChatManager.swift
//  ChatSample
//
//  Created by Murali Sai Tummala on 08/05/19.
//  Copyright © 2019 Voxvalley technologies. All rights reserved.
//

import Foundation
import UIKit
import Photos
import CoreLocation


class ChatManager: NSObject {
    
    
    static let shared:ChatManager = {
       
        let sharedinstance = ChatManager()

        return sharedinstance
        
    }()
    
    func checkForPhotosPermission(withCompletionHandler completionHandler: @escaping (_ success: Bool) -> Void) {
        // Check for photos permission
        let status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        if status == .authorized {
            completionHandler(true)
        } else if status == .denied {
            completionHandler(false)
        } else if status == .restricted {
            completionHandler(false)
        } else if status == .notDetermined {
            
            // Access has not been determined.
            PHPhotoLibrary.requestAuthorization({ status in
                
                if status == .authorized {
                    completionHandler(true)
                } else {
                    completionHandler(false)
                }
            })
        } else {
            completionHandler(false)
        }
    }
    
    func checkForCameraPermission(withCompletionHandler completionHandler: @escaping (_ success: Bool) -> Void) {
        
        // Check for camera permissions
        let mediaType = AVMediaType.video
        
        let authStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
        if authStatus == .authorized {
            completionHandler(true)
        } else if authStatus == .denied {
            completionHandler(false)
        } else if authStatus == .restricted {
            completionHandler(false)
        } else if authStatus == .notDetermined {
            // not determined?!
            AVCaptureDevice.requestAccess(for: mediaType, completionHandler: { granted in
                if granted {
                    completionHandler(true)
                } else {
                    completionHandler(false)
                }
            })
        } else {
            completionHandler(false)
        }
    }

    
    func checkForMicrophonePermission(withCompletionHandler completionHandler: @escaping (_ success: Bool) -> Void) {
        
        // Check for microphone permissions
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            // Success
            completionHandler(true)
        case .denied:
            // Failure
            completionHandler(false)
        case .undetermined:
            // prompt for permission
            AVAudioSession.sharedInstance().requestRecordPermission({ granted in
                if granted {
                    // Success
                    completionHandler(true)
                } else {
                    // Failure
                    completionHandler(false)
                }
            })
            break
        default:
            break
        }
    }
}


