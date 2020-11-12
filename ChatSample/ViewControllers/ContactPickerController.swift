//
//  ContactPickerController.swift
//  ChatSample
//
//  Created by Murali Sai Tummala on 09/05/19.
//  Copyright © 2019 Voxvalley technologies. All rights reserved.
//

import UIKit
import VoxSDK

@objc protocol ContactPickerControllerDelegate {
    
    
    @objc optional func contactPickerController(_ picker: ContactPickerController, didFinishPicking contact: CSContact)
    @objc optional func contactPickerController(_ picker: ContactPickerController, didFinishPickingMultipleContacts contacts: [CSContact])
    
    @objc optional  func contactPickerController(_ picker: ContactPickerController, didFinishPickingContactForAudioCall contact: CSContact)
    
    @objc optional  func contactPickerController(_ picker: ContactPickerController, didFinishPickingContactForVideoCall contact: CSContact)
    
    @objc optional  func contactPickerControllerDidCancel(_ picker: ContactPickerController)
    
}


class ContactPickerController: UIViewController,UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate {
    
    static let CP_MODE_SEND_CONTACT: Int = 0
    static let CP_MODE_ADD_PARTICIPANTS: Int = 1
    static let CP_MODE_NEW_MESSAGE: Int = 2
    static let CP_MODE_NEW_CALL: Int = 3
    static let CP_MODE_FORWARD: Int = 4
    static let CP_MODE_CREATE_GROUP: Int = 5
    
    var delegate: ContactPickerControllerDelegate?
    
    var mode: Int = 0
    var filterNumbers: [CSContact] = []
    var isSearching : Bool = false
    
    
    @IBOutlet weak var contactsTableView: UITableView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var noDataLabel: UILabel!
    
    var contactArray = [CSContact]()
    var searchResults : [CSContact] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        let contactStore = CSContactStore.sharedInstance()
        
        var tempContactArray : NSMutableArray? = []
        
        if self.mode ==  ContactPickerController.CP_MODE_SEND_CONTACT{
            
            contactStore?.getContactList(&tempContactArray, flag: true)
        }
        else{
            contactStore?.getContactList(&tempContactArray, flag: false)
            if self.mode == ContactPickerController.CP_MODE_NEW_MESSAGE{
                self.navigationItem.rightBarButtonItem = nil
            }
            
        }
        
        
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
        
        // To be filtered numbers
        /*
         if filterNumbers.count > 0 {
         
         let filterSet = Set<CSNumber>
         
         //            NSSet* filterSet = [NSSet setWithArray:self.filterNumbers];
         
         /*
         for(int i = 0; i < self.contactArray.count; i++) {
         
         CSContact* contact = [self.contactArray objectAtIndex:i];
         
         NSMutableSet* nums = [NSMutableSet setWithArray:contact.numbers];
         
         [nums minusSet:filterSet];
         
         if(nums.count < contact.numbers.count) {
         contact.numbers = [nums allObjects];
         }
         
         */
         
         for contactObj in contactArray{
         
         if let numbersTemp = contactObj.numbers as? [CSNumber]{
         
         var nums = Set<CSNumber>(numbersTemp)
         
         nums.subtract(filterSet as! Set<CSNumber>)
         
         if nums.count < numbersTemp.count
         {
         contactObj.numbers.append(Array(nums))
         }
         }
         }
         
         let emptyPredicate = NSPredicate(block: { contact, bindings in
         
         if (contact as? CSContact)?.numbers.count == 0 {
         return false
         } else {
         return true
         }
         })
         contactArray.filter { emptyPredicate.evaluate(with: $0) }
         }
         
         */
        
        contactsTableView.reloadData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)

        
        if self.mode == ContactPickerController.CP_MODE_SEND_CONTACT {
            self.title = "Select Contact"
//            contactsTableView.allowsMultipleSelection = true
            contactsTableView.allowsMultipleSelectionDuringEditing = true
            contactsTableView.setEditing(true, animated: true)


        }
        else if self.mode == ContactPickerController.CP_MODE_NEW_MESSAGE{
            self.title = "Select Contact"
            contactsTableView.allowsSelectionDuringEditing = true

        }
        else if self.mode == ContactPickerController.CP_MODE_FORWARD{
            self.title = "Select Contact"
            contactsTableView.allowsMultipleSelectionDuringEditing = true
            contactsTableView.setEditing(true, animated: true)

        }
        

    }
    
    @IBAction func cancelButtonAction(_ sender: UIBarButtonItem) {
        
        if let delegatetemp = delegate {
            delegatetemp.contactPickerControllerDidCancel?(self)
        }
        else{
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func doneButtonAction(_ sender: UIBarButtonItem) {
        
        guard let selectedRows = contactsTableView.indexPathsForSelectedRows else {
            cancelButtonAction(sender)
            return
        }
            if mode == ContactPickerController.CP_MODE_FORWARD {
                
                var contacts: [CSContact] = []
                
                for indexPath in selectedRows {
                    
                    let record = contactArray[indexPath.row]
                    if    record  != nil {
                        contacts.append(record)
                    }
                }
                delegate?.contactPickerController?(self, didFinishPickingMultipleContacts: contacts)
                
            }
       else if mode == ContactPickerController.CP_MODE_SEND_CONTACT {
            
            
            for indexPath in selectedRows {
                
                let record = contactArray[indexPath.row]
                    delegate?.contactPickerController?(self, didFinishPicking: record)
            }
            
        }
                
            
            else {
                var indexPath = selectedRows[0]
                
                delegate?.contactPickerController?(self, didFinishPicking: contactArray[indexPath.row])
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
        contactsTableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        isSearching = false
        contactsTableView.reloadData()
        
    }
    
    
    //MARK: -----Tableview methods -----
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return searchResults.count
        }
        
        return contactArray.count
        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell =  tableView.dequeueReusableCell(withIdentifier: "AddParticipantCell") else {
            return UITableViewCell()
            
        }
        
        var contactRecordobj: CSContact? = nil
        
        if isSearching {
            contactRecordobj = searchResults[indexPath.row]
        }
        else{
            contactRecordobj = contactArray[indexPath.row]
        }
        let nameLabel = cell.contentView.viewWithTag(102) as? UILabel
        let numberLabel = cell.contentView.viewWithTag(103) as? UILabel
        
        
        guard let contactRecord = contactRecordobj else { return  cell}
        
        
        if let name = contactRecord.name {
            nameLabel?.text = name
        }
        
        if let phoneNumber = contactRecord.numbers[0] as? CSNumber {
            if let profilename = phoneNumber.profileName,profilename.count > 0 {
                nameLabel?.text = "~\(profilename)"
            }
            if let number = phoneNumber.number {
                numberLabel?.text = number
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var contactRecordobj: CSContact? = nil
        
        if isSearching {
            contactRecordobj = searchResults[indexPath.row]
        }
        else{
            contactRecordobj = contactArray[indexPath.row]
        }
        
        
        guard let contactRecord = contactRecordobj else { return  }
        
        if self.mode != ContactPickerController.CP_MODE_FORWARD{
            if self.mode == ContactPickerController.CP_MODE_NEW_MESSAGE{
                delegate?.contactPickerController?(self, didFinishPicking: contactRecord)
            }
            
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
