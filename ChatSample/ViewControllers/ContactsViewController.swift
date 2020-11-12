//
//  ContactsViewController.swift
//  ChatSample
//
//  Created by Murali Sai Tummala on 25/04/19.
//  Copyright © 2019 Voxvalley technologies. All rights reserved.
//

import UIKit
import Contacts
import VoxSDK


class ContactsViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate {
    
    
    
    @IBOutlet weak var contactTableView: UITableView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var noDataLabel: UILabel!
    var contactArray = [CSContact]()
    var searchResults : [CSContact] = []
    var allContactsFlag : Bool = true
    var store: CNContactStore?
    var selectedIndexPath: IndexPath?
    var isSearching : Bool?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isSearching = false
        
        store = CNContactStore()
        
        if !CSSettings .getAutoSignin() {
            
            CSClient.sharedInstance().login(CSSettings.getLoginId(), withPassword: CSSettings.getPassword(), completionHandler: nil)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleReloadContacts(notification:)), name: NSNotification.Name(rawValue: "ReloadContactsNotification"), object: nil)
        
        let contactStore = CSContactStore.sharedInstance()
        if ((contactStore?.isAccessGrantedForContacts())! == false) {
            contactStore?.promptContactAccess()
        }
        
        // Update UI
        
        let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
        
        
        // Load Contacts ....
        loadContacts()
        
        // Do any additional setup after loading the view.
    }
    
    
    //MARK: -------ButtonActions..........
    
    @IBAction func contextMenuAction(_ sender: UIBarButtonItem) {
        
        
        if self.allContactsFlag == true {
            
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let konverzcontactsaction = UIAlertAction(title: "Konverz Contacts", style: .default, handler: {
                (alertaction:UIAlertAction) in
                
                if self.allContactsFlag == true {
                    
                    self.allContactsFlag = false
                    Appsettings.setAllContactsFlag(flag: false)
                }
                else{
                    self.allContactsFlag = true
                    Appsettings.setAllContactsFlag(flag: true)
                    
                }
                
                self.loadContacts()
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            actionSheet.addAction(konverzcontactsaction)
            actionSheet.addAction(cancelAction)
            
            self.present(actionSheet, animated: true, completion: nil)
            
        }
            
        else{
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let konverzcontactsaction = UIAlertAction(title: "All Contacts", style: .default, handler: {
                (alertaction:UIAlertAction) in
                
                if self.allContactsFlag == true {
                    
                    self.allContactsFlag = false
                    Appsettings.setAllContactsFlag(flag: false)
                }
                else{
                    self.allContactsFlag = true
                    Appsettings.setAllContactsFlag(flag: true)
                    
                }
                
                self.loadContacts()
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            actionSheet.addAction(konverzcontactsaction)
            actionSheet.addAction(cancelAction)
            self.present(actionSheet, animated: true, completion: nil)
            
        }
        
        
    }
    
    
    //MARK: -----SearchBar delegate Methods ............
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
        
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        executeSearch(searchkey: searchText)
        
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
        searchBar.showsCancelButton = false
        searchBar.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
    }
    
    func executeSearch(searchkey : String){
        
        isSearching = true
        
        if searchkey.count > 0 {
            
            let predicate = NSPredicate(block: { (contactData, bindings) -> Bool in
                
                guard let contact = contactData as? CSContact else { return false}
                
                if let matchingName = contact.name{
                    
                    if  (matchingName.range(of: searchkey, options: .caseInsensitive, range: nil, locale: nil) != nil){
                        return true
                    }
                }
                if let number = contact.numbers[0] as? CSNumber{
                    
                    if let numberstr = number.number {
                        
                        if  (numberstr.range(of: searchkey, options: .caseInsensitive, range: nil, locale: nil) != nil){
                            return true
                        }
                    }
                }
                
                return false
            })
            
            let filteredArray = (contactArray as NSArray).filtered(using: predicate)
            
            if let ary = filteredArray as? [CSContact]{
                
                searchResults = ary
                
            }
        }
        contactTableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        isSearching = false
        contactTableView.reloadData()
        
    }
    
    
    //MARK: -----Contacts Fetching.............
    
    
    func loadContacts(){
        
        let contactStore = CSContactStore.sharedInstance()
        
        var tempContactArray : NSMutableArray? = []
        
        contactStore?.getContactList(&tempContactArray, flag: allContactsFlag)
        
        if let array : [CSContact] = tempContactArray as? [CSContact]{
            contactArray = array
            
        }
        
        // Remove self contact
        
        var removedContacts = [CSContact]()
        
        for contact in contactArray {
            
            var numbers = [CSNumber]()
            for phoneNumber in contact.numbers{
                
                if let no : CSNumber = phoneNumber as? CSNumber{
                    
                    if (!no.isEqual(CSSettings.getLoginId())){
                        
                        numbers.append(no)
                    }
                }
            }
            if numbers.count == 0{
                removedContacts.append(contact)
            }
            else{
                contact.numbers = numbers
            }
        }
        
        for contact in removedContacts {
            contactArray.removeAll(where: {
                element in element == contact
            })
        }
        
        if contactArray.count > 0 {
            contactTableView.backgroundView = nil
        } else {
            
            if !CSContactStore.sharedInstance().isAccessGrantedForContacts() {
                noDataLabel.text = "You denied permission for Contacts.\nPlease enable from Settings"
            } else {
                if allContactsFlag == true {
                    noDataLabel.text = "No contacts to show"
                } else {
                    noDataLabel.text = "Your friends are not yet using Konverz"
                }
            }
            contactTableView.backgroundView = noDataLabel
        }
        
        contactTableView.reloadData()
        
    }
    
    
    // MARK:----- Observer Methods.........
    
    
    @objc func handleReloadContacts(notification : Notification) {
        
        loadContacts()
    }
    
    // MARK: --- Tableview delegate Methods ..........
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isSearching! {
            return searchResults.count
        }
        
        return contactArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell =  tableView.dequeueReusableCell(withIdentifier: "ContactCell") else {
            return UITableViewCell()
            
        }
        var contactRecord: CSContact? = nil
        var groupRecord: CSGroup? = nil
        
        if isSearching! {
            contactRecord = searchResults[indexPath.row]
        }
        else{
            contactRecord = contactArray[indexPath.row]
        }
        let contactName = cell.contentView.viewWithTag(102) as? UILabel
        var contactNumber = cell.contentView.viewWithTag(103) as? UILabel
        let initials = cell.contentView.viewWithTag(104) as? UILabel
        let contactImage = cell.contentView.viewWithTag(101) as? UIImageView
        let appContactIcon = cell.contentView.viewWithTag(105) as? UIImageView
        
        var phoneNumber = contactRecord?.numbers[0] as? CSNumber
        
        if let numBer = contactRecord?.numbers {
            for i in 0..<numBer.count {
                var number = contactRecord?.numbers[i] as? CSNumber
                
                if let status = number?.contactStatus{
                    if status == CSContactAppStatus.user.rawValue {
                        phoneNumber = number
                        break
                    }
                }
            }
        }
        
        var name = ""
        
        if ((contactRecord?.name) != nil) {
            name = contactRecord?.name ?? ""
        } else {
            if let nametemp = phoneNumber?.profileName, nametemp.count > 0{
                name = nametemp
            } else {
                if let numbertemp = phoneNumber?.number, numbertemp.count > 0{
                    name = numbertemp
                }
            }
        }
        
        contactName?.text = name
        
        contactNumber?.text = phoneNumber?.number
        
        initials?.text = "";
        
        if let status = phoneNumber?.contactStatus{
            
            if status == CSContactAppStatus.user.rawValue{
                appContactIcon?.isHidden = false
            }
            else{
                appContactIcon?.isHidden = true
            }
        }
        
        contactImage?.layer.cornerRadius = (contactImage?.frame.size.width)!/2.0
        contactImage?.clipsToBounds = true
        
        if let path = phoneNumber?.profilePhotoPath, path.count > 0{
            contactImage?.image = UIImage(contentsOfFile: path)
            initials?.isHidden = true
        }
        else{
            
            let contacterror: Error?
            let keys = [CNContactThumbnailImageDataKey]
            var contact: CNContact? = nil
            
            do {
                contact =  try store?.unifiedContact(withIdentifier: contactRecord!.recordID, keysToFetch: keys as [CNKeyDescriptor])
            } catch  {
                contacterror = error
                fatalError("\(error)")
            }
            
            if contact != nil{
                if contact?.thumbnailImageData != nil {
                    if let thumbnailImageData = contact?.thumbnailImageData {
                        contactImage?.image = UIImage(data: thumbnailImageData)
                        initials?.isHidden = true
                    }
                } else {
                    contactImage?.backgroundColor = .lightGray
                    contactImage?.image = UIImage(named: "")
                    initials?.isHidden = false
                    initials?.text = "\(name.prefix(1))".uppercased()
                }
            }
            else{
                contactImage?.backgroundColor = .lightGray
                contactImage?.image = UIImage(named: "")
                
                initials?.isHidden = false
                initials?.text = "\(name.prefix(1))".uppercased()
            }
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        selectedIndexPath = indexPath
        
        performSegue(withIdentifier: "showContactDetails", sender: self)
        
        selectedIndexPath = nil
    }
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        
        var contact : CSContact?
        if isSearching == true {
            contact = searchResults[(selectedIndexPath?.row)!]
        }
        else{
            contact = contactArray[(selectedIndexPath?.row)!]
        }
        if (segue.identifier?.elementsEqual("showContactDetails"))! {
            
            let destViewController : ContactDetailViewController = segue.destination as! ContactDetailViewController
            destViewController.contact = contact
            
        }
        
        
    }
    
    
}
