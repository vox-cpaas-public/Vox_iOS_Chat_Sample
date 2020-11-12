//
//  AppSettings.swift
//  ChatSample
//
//  Created by Murali Sai Tummala on 23/04/19.
//  Copyright © 2019 Voxvalley technologies. All rights reserved.
//

import UIKit



struct Appsettings {

    private static let defaults = UserDefaults.standard
    
    static func setLoginId(value : String){
        
        defaults.set(value, forKey: "AppLoginId")
        defaults.synchronize()
    }
    
    static func getLoginId() -> String{
        
        if let loginid : String =  defaults.value(forKey: "AppLoginId") as? String{
        return loginid
        }
        return ""
        
    }
    
    static func setpassword(value : String){
        
        defaults.set(value, forKey: "Apppassword")
        defaults.synchronize()
    }
    
    static func getPassword() -> String{
        
        
        
        if let password : String =  defaults.value(forKey: "Apppassword") as? String{
            return password
        }
        return ""
        
    }
    
    static func setAllContactsFlag(flag : Bool){
        
        defaults.set(flag, forKey: "AllContactsFlag")
        defaults.synchronize()

        
    }
    
    static func getAllContactsFlag() -> Bool{
        
        
        if let flag : Bool =  defaults.value(forKey: "AllContactsFlag") as? Bool{
            return flag
            
        }
        return false
        
    }
   
    
    
   

    
    
}


