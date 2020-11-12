//
//  Util.swift
//  ChatSample
//
//  Created by Murali Sai Tummala on 23/04/19.
//  Copyright © 2019 Voxvalley technologies. All rights reserved.
//

import UIKit

class Util: NSObject {
    
    public func showAlert(withTitle:String, andMessage:String?, onView: Any) {
        
        let alertController = UIAlertController(title: withTitle, message: andMessage, preferredStyle: .alert)
        
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        
        (onView as! UIViewController).present(alertController, animated: true, completion: nil)
    }
    
    
    
}
