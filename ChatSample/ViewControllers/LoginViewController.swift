//
//  LoginViewController.swift
//  ChatSample
//
//  Created by Murali Sai Tummala on 22/04/19.
//  Copyright © 2019 Voxvalley technologies. All rights reserved.
//

import UIKit

import VoxSDK

class LoginViewController: UIViewController {

    @IBOutlet weak var checkmark: UIButton!
    @IBOutlet weak var loginID: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    var nameLabel: UILabel!
    var activityIndicator: UIActivityIndicatorView!
    var clientState : CSClientState!
        
    @IBAction func action_Rememberme(_ sender: UIButton) {

        sender.isSelected = !sender.isSelected
        
        if checkmark.isSelected {
            self.checkmark.setImage(UIImage(named: "ic_check_mark"), for: .normal)
        }
        else{
            self.checkmark.setImage(UIImage(named: "ic_Unchek_mark"), for: .normal)
        }
    }
    
    @IBAction func NextAction(_ sender: UIBarButtonItem) {
        
      
        guard self.loginID.text?.count != 0 else {
            
            Util().showAlert(withTitle: "Konverz", andMessage: "Please enter Login ID", onView: self)
            return
        }
        
        guard self.password.text?.count != 0 else {
            Util().showAlert(withTitle: "Konverz", andMessage: "Please enter password", onView: self)
            return
        }
        
        CSClient.sharedInstance()?.login(self.loginID.text!, withPassword: self.password.text!, completionHandler: { response , error in
            
            if error != nil {
                
                if let error = error {
                    print("Error is :\(error)")
                }
            } else {
                
                let returnCode = response?[kARReturnCode] as? Int
                
                guard let sReturnCode = CSReturnCodes(rawValue: returnCode!) else {
                    
                    return
                }
                
                switch sReturnCode {
                    
                case .E_200_OK,.E_202_OK:
                    
                    if self.checkmark.isSelected {
                        
                        Appsettings.setLoginId(value: self.loginID.text!)
                        Appsettings.setpassword(value: self.password.text!)
                    }else {
                        Appsettings.setLoginId(value: "")
                        Appsettings.setpassword(value: "")
                    }
                  
                    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let rootViewController : UITabBarController = storyBoard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
                    UIApplication.shared.keyWindow?.rootViewController = rootViewController;
                    rootViewController.selectedIndex = 0;
                    let overlayView = UIScreen.main.snapshotView(afterScreenUpdates: false)
                    
                    rootViewController.view.addSubview(overlayView)
                    
                    
                    UIView.animate(withDuration: 0.4, delay: 0.0, options: .transitionCrossDissolve, animations: {
                        
                        overlayView.alpha = 0
                        
                    }) { (bool) in
                        
                        overlayView.removeFromSuperview()
                        
                    }
                    
                case .E_401_UNAUTHORIZED:
                    
                    Util().showAlert(withTitle: "Konverz", andMessage: "Login Failed : Unauthorized", onView: self)

                case .E_409_NOTALLOWED:
                    
                    Util().showAlert(withTitle: "Konverz", andMessage: "Login Failed : Not allowed", onView: self)

                case .E_803_USER_DEACTIVATED:
                    
                    Util().showAlert(withTitle: "Konverz", andMessage: "Login Failed : User deactivated", onView: self)

                default:
                    break
                }
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppStateNotification(notification:)), name: NSNotification.Name(rawValue: "AppStateNotification"), object: nil)
        
        clientState = CSClient.sharedInstance()?.getState()

        // Title view
        
        self.nameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        self.nameLabel.backgroundColor = .clear
        self.nameLabel.font = UIFont.systemFont(ofSize: 16.0)
        self.nameLabel.textAlignment = .center
        self.nameLabel.textColor = .white
        
        let titleview = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        titleview.backgroundColor = .clear
        titleview.addSubview(self.nameLabel)
        
        self.loginID.attributedPlaceholder = NSAttributedString(string: "Login ID",
                                                               attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        self.password.attributedPlaceholder = NSAttributedString(string: "Password",
                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        //! start animation
        self.activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 40));
        self.activityIndicator.style = .white;
        titleview.addSubview(self.activityIndicator);
        
        self.navigationItem.titleView = titleview;
        
        if Appsettings.getLoginId().count != 0 {
            self.loginID.text = Appsettings.getLoginId()
            self.password.text = Appsettings.getPassword()
            self.checkmark.setImage(UIImage(named: "ic_check_mark"), for: .normal)
            self.checkmark.isSelected = true
        }
        
        if clientState == CSClientState.ready {
            self.enableControls(flag: true, title: "Login");
        }
        else if clientState == CSClientState.connecting {
            self.enableControls(flag: false, title: "Connecting...");
        }
        else
        {

        self.enableControls(flag: false, title: "Waiting for network");
        }
        
    }

    // MARK: - Delegate Methods
    
    @objc func handleAppStateNotification(notification : Notification) {
        
        if notification.name.rawValue == "AppStateNotification" {
            
            let ASNotification :Dictionary = notification.userInfo!
            
            let state : NSNumber = ASNotification[kANAppState] as! NSNumber
            
            self.clientState = CSClientState(rawValue: state.intValue)
            
            guard  let cstate = self.clientState
                else{
                    return
            }
            
            switch cstate{
            case .active:
                print("");
                // Login success
            case .ready:
                self.enableControls(flag: true, title: "Login")
            case .inactive:
                self.enableControls(flag: false, title: "Waiting for network")
             default:
                break
                //! TODO handle other states
            }
        }
    }
    
    func enableControls(flag : Bool,title : String){
        
        self.nameLabel.text = title;
        if flag {
            
            self.nextButton.isEnabled = true;
            self.activityIndicator.stopAnimating();
        }
        else{
            self.nextButton.isEnabled = false;
            self.activityIndicator.startAnimating();
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
