//
//  ContactDetailViewController.swift
//  ChatSample
//
//  Created by Murali Sai Tummala on 03/05/19.
//  Copyright © 2019 Voxvalley technologies. All rights reserved.
//

import UIKit
import Contacts

class ContactDetailViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    
    
    var contact: CSContact?
    
    @IBOutlet weak var numberTablview: UITableView!
    @IBOutlet weak var Backgroundview: UIView!
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var defaultImage: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        let store = CNContactStore()
        let keys = [CNContactImageDataKey]
        var contact: CNContact? = nil
        
        do {
            contact = try store.unifiedContact(withIdentifier: self.contact!.recordID, keysToFetch: keys as [CNKeyDescriptor])
        } catch {
            
            
        }
        
        self.title = self.contact?.name
        
        var phoneNumber : CSNumber?
        
        if let phoneno = self.contact?.numbers[0] as? CSNumber {
            
            phoneNumber = phoneno
        }
        
        if ((self.contact?.name) != nil) {
            self.title = self.contact?.name
        }
        else{
            self.title = phoneNumber?.number
        }
        
        if let profilePhotoPath = phoneNumber?.profilePhotoPath, profilePhotoPath.count > 0 {
            photoView.image = UIImage(contentsOfFile: profilePhotoPath)
            defaultImage.isHidden = true
        }
        else{
            
            if contact != nil{
                if ((contact?.imageData) != nil){
                    photoView.image = UIImage(data: (contact?.imageData)!)
                    defaultImage.isHidden = true
                }
                else{
                    photoView.backgroundColor = .lightGray
                }
            }
            else{
                photoView.backgroundColor = .lightGray
                
            }
        }
        
    }
    
    //MARK: Tableview Delegate Methods..........
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 1 {
            return 1
        }
        
        return (self.contact?.numbers.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ContactDetailNumberCell") as? ContactDetailNumberCell else {
            return UITableViewCell()
        }
        
        if indexPath.section == 0 {
            
            
            if let phoneNumber : CSNumber = self.contact?.numbers[indexPath.row] as? CSNumber {
                
                cell.typeLabel.text = phoneNumber.label
                cell.number.text = phoneNumber.number
                
                if phoneNumber.contactStatus == CSContactAppStatus.user.rawValue{
                    cell.chatButton.isHidden = false
                }
                else{
                    cell.chatButton.isHidden = true
                    
                }
            }
            
            return cell
            
        }
        else{
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "blcokDetailCell")  else {
                return UITableViewCell()
            }
            
            let optionLabel = cell.contentView.viewWithTag(101) as? UILabel
            
            if let phoneNumber = self.contact?.numbers[0] as? CSNumber{
                
                if phoneNumber.blockedStatus == 1{
                    
                    optionLabel?.text = "UnBlock Contact"
                }
                else{
                    optionLabel?.text = "Block Contact"
                    
                }
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {
            
            let cell = tableView.cellForRow(at: indexPath)
            let optionLabel = cell!.contentView.viewWithTag(101) as? UILabel
            
            if let numBers = self.contact?.numbers as? [CSNumber]{
                
                for phoneNumber in numBers{
                    
                    if phoneNumber.blockedStatus == 1 {
                        
                        let store = CSContactStore.sharedInstance()
                        
                        store?.unblockContact(phoneNumber.number, completionHandler: { error in
                            if error != nil {
                                if let error = error {
                                    print("Un Block Contact:\(error)")
                                }
                            } else {
                                print("Un Block Contact: Success")
                                phoneNumber.blockedStatus = 0
                                DispatchQueue.main.async {
                                    optionLabel?.text = "Block Contact"
                                }
                                
                            }
                        })
                    }
                    else{
                        let store = CSContactStore.sharedInstance()
                        
                        store?.blockContact(phoneNumber.number, completionHandler: { error in
                            if error != nil {
                                if let error = error {
                                    print("Block Contact:\(error)")
                                }
                            } else {
                                print("Block Contact: Success")
                                phoneNumber.blockedStatus = 1
                                DispatchQueue.main.async {
                                    optionLabel?.text = "Un Block Contact"
                                }
                            }
                        })
                    }
                }
            }
            //            numberTablview.reloadData()
        }
    }
    
    @IBAction func chatButtonAction(_ sender: UIButton) {
        
        
        let buttonPosition = sender.convert(CGPoint(x: 0, y: 0), to: numberTablview)
        let indexPath: IndexPath? = numberTablview.indexPathForRow(at: buttonPosition)
        if let indexPath = indexPath {
            
            
            self.tabBarController?.selectedIndex = 1;
            
            let storyboard = UIStoryboard(name: "Chats", bundle: nil)
            let chatviewController = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController
            let phoneNumber = contact?.numbers[indexPath.row] as? CSNumber
            chatviewController?.remoteNumber = phoneNumber?.number ?? ""
            chatviewController?.recordID = contact?.recordID ?? ""
            chatviewController?.chatMode = 1
            
            let navigationController = UINavigationController(rootViewController: chatviewController!)
            navigationController.navigationBar.barTintColor = UIColor(red: 0.0 / 255.0, green: 137.0 / 255.0, blue: 123.0 / 255.0, alpha: 1.0)
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.barStyle = .black
            
            navigationController.modalPresentationStyle = .custom
            present(navigationController, animated: true)
//            let tabbar: UITabBarController? = tabBarController
//            tabBarController?.selectedIndex = 1
//
//            let hnav = tabbar?.viewControllers?[1] as? UINavigationController
//            let vc = hnav?.topViewController as? HistoryViewController
//
//            guard let contact = contact else {return}
//
//            let phoneNumber = contact.numbers[indexPath.row] as? CSNumber
//
//            let storyboard = UIStoryboard(name: "Chats", bundle: nil)
//            let chatviewController = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController
//
//            chatviewController?.recordID = contact.recordID ?? ""
//            chatviewController?.chatMode = 1
//            chatviewController?.remoteNumber = phoneNumber?.number ?? ""
//
//            var navigationController: UINavigationController? = nil
//
//            if let chatViewController = chatviewController {
//                navigationController = UINavigationController(rootViewController: chatViewController)
//            }
//            navigationController?.navigationBar.barTintColor = UIColor(red: 0.0, green: 137.0 / 255.0, blue: 123.0 / 255.0, alpha: 1.0)
//            navigationController?.navigationBar.isTranslucent = false
//            navigationController?.navigationBar.barStyle = .black
//
//            navigationController?.modalPresentationStyle = .custom
//            navigationController?.transitioningDelegate = vc
//
//            vc?.present(navigationController!, animated: true) {
//                self.navigationController?.popViewController(animated: false)
//            }
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
