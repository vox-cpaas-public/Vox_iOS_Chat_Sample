//
//  HistoryViewController.swift
//  ChatSample
//
//  Created by Murali Sai Tummala on 06/05/19.
//  Copyright © 2019 Voxvalley technologies. All rights reserved.
//

import UIKit
import VoxSDK
import Contacts

class HistoryViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,UINavigationControllerDelegate,UIViewControllerTransitioningDelegate,ContactPickerControllerDelegate {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var activityindicator: UIActivityIndicatorView!
    @IBOutlet weak var historyListView: UITableView!
    @IBOutlet weak var noDataLabel: UILabel!
    
    
    var historyRecords = [CSHistoryIndex]()
    
    //    CSHistoryIndex
    
    weak var dbManager: CSDataStore?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        dbManager = CSDataStore.sharedInstance()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleChatNotification(notification:)), name: NSNotification.Name("ChatNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleChatDeliveryNotification(notification:)), name: NSNotification.Name("ChatDeliveryNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppStateNotification(notification:)), name: NSNotification.Name("AppStateNotification"), object: nil)
        
        
        if  let clientstate : CSClientState = CSClient.sharedInstance()?.getState(){
            if clientstate == .inactive {
                self.nameLabel.text = "Waiting for network"
                activityindicator.startAnimating()
            }
            else if (clientstate == .connecting) || clientstate == .ready || clientstate == .none {
                self.nameLabel.text = "Connecting..."
                activityindicator.startAnimating()
            }
            else{
                self.nameLabel.text = "Chats"
                activityindicator.stopAnimating()
                activityindicator.isHidden = true
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadHistory()
    }
    
    
    func loadHistory() {
        
        var records : NSMutableArray? = []
        
        self.dbManager?.getChatHistoryIndexRecords(&records)
        
        historyRecords = [CSHistoryIndex]()
        
        if let array : [CSHistoryIndex] = records as? [CSHistoryIndex]{
            historyRecords = array
        }
        
        var badgeCount: Int = 0
        
        for record in historyRecords {
            if record.unreadCount > 0{
                badgeCount += 1
            }
        }
        
        if badgeCount == 0 {
            self.tabBarController?.tabBar.items?[1].badgeValue = nil
        }
        else{
            self.tabBarController?.tabBar.items?[1].badgeValue = "\(badgeCount)"
        }
        
        if historyRecords.count > 0 {
            historyListView.backgroundView = nil
        }
        else{
            noDataLabel.text = "You have no chat messages"
            historyListView.backgroundView = noDataLabel
        }
        
        historyListView.reloadData()
    }
    
    
    // MARK: VoxSDK Methods .............
    
    @objc func handleChatNotification(notification : NSNotification){
        
        if notification.name.rawValue.elementsEqual("ChatNotification") {
            loadHistory()
            AudioServicesPlayAlertSound(1007)
            
        }
        
    }
    @objc func handleChatDeliveryNotification(notification : NSNotification){
        if notification.name.rawValue.elementsEqual("ChatDeliveryNotification") {
            loadHistory()
        }
        
    }
    @objc func handleAppStateNotification(notification : NSNotification){
        
        if notification.name.rawValue.elementsEqual("ChatDeliveryNotification") {
            
            var clientState : CSClientState!
            
            let ASNotification :Dictionary = notification.userInfo!
            
            let state : NSNumber = ASNotification[kANAppState] as! NSNumber
            
            clientState = CSClientState(rawValue: state.intValue)
            
            guard  let cstate = clientState
                else{
                    return
            }
            switch cstate{
            case .active:
                print("");
            // Login success
            case .inactive:
                nameLabel.text = "Waiting for network"
                activityindicator.isHidden = false
                activityindicator.startAnimating()
            case .connecting,.ready,.none:
                nameLabel.text = "Connecting..."
                activityindicator.isHidden = false
                activityindicator.startAnimating()
            default:
                nameLabel.text = "Chats"
                activityindicator.stopAnimating()
                activityindicator.isHidden = true
                break
                //! TODO handle other states
                
            }
        }
        
    }
    
    // MARK: Tableview Methods.............
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyRecords.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell") as? HistoryCell else { return UITableViewCell() }
        
        let historyRecord = historyRecords[indexPath.row]
        
        var store: CNContactStore?
                
        var dateFormatter = DateFormatter()
        dateFormatter.doesRelativeDateFormatting = true
        dateFormatter.locale = NSLocale.current
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .short
        
        let timestamp = dateFormatter.string(from: historyRecord.details.startTime)
        
        if (timestamp == "Today") {
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .short
            cell.timestampLabel.text = dateFormatter.string(from: historyRecord.details.startTime)
        } else {
            cell.timestampLabel.text = timestamp
        }
        
        if historyRecord.unreadCount == 0 {
            cell.unreadCount.isHidden = true
            cell.message.font = UIFont.systemFont(ofSize: 14.0)
        } else {
            cell.unreadCount.isHidden = false
            cell.unreadCount.clipsToBounds = true
            cell.unreadCount.text = String(format: "  %zd  ", historyRecord.unreadCount)
            cell.message.font = UIFont.boldSystemFont(ofSize: 14.0)
        }
        
        if historyRecord.details.direction == 1 && historyRecord.details.status != CSChatStatus.read.rawValue
        {
            //[cell.message setTextColor:[UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0]];
            cell.timestampLabel.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        } else {
            //[cell.message setTextColor:[UIColor blackColor]];
            cell.timestampLabel.textColor = UIColor.black
        }
        switch historyRecord.details.recordType {
        case  .pstnCall:
            break
        case .videoCall: break
        case .message:
            cell.message.text = historyRecord.details.data
        case .contact:
            cell.message.text = "Contact"
        case .location:
            cell.message.text = "Location"
        case .photo:
            cell.message.text = "0001f4f7 Photo"
        case .video:
            cell.message.text = "0001f4f9 Video"
        case .document:
            cell.message.text = "0001f4c4 Document"
        case .audio:
            cell.message.text = "0001f3a4 Audio"
        default:
            break
        }
        
        cell.contactImage?.layer.cornerRadius = (cell.contactImage?.frame.size.width)!/2.0
        cell.contactImage?.clipsToBounds = true
        
        if historyRecord.type == 0 || historyRecord.type == 2 {
            var contact : CNContact!
            if (historyRecord.contact != nil){
                let phoneNumber = historyRecord.contact.numbers[0] as? CSNumber
                
                if ((historyRecord.contact?.name) != nil) {
                    cell.contactName.text = historyRecord.contact.name ?? ""
                } else {
                    if let nametemp = phoneNumber?.profileName, nametemp.count > 0{
                        cell.contactName.text = nametemp
                    } else {
                        if let numbertemp = phoneNumber?.number, numbertemp.count > 0{
                            cell.contactName.text = numbertemp
                        }
                    }
                }
                if let path = phoneNumber?.profilePhotoPath, path.count > 0{
                    cell.contactImage?.image = UIImage(contentsOfFile: path)
                    cell.defaultContact.isHidden = true
                }
                else{
                    let contacterror: Error?
                    let keys = [CNContactThumbnailImageDataKey]
                    do {
                        contact =  try store?.unifiedContact(withIdentifier: historyRecord.contact.recordID, keysToFetch: keys as [CNKeyDescriptor])
                    } catch  {
                        contacterror = error
                        fatalError("\(error)")
                    }
                    if contact != nil{
                        if contact?.thumbnailImageData != nil {
                            if let thumbnailImageData = contact?.thumbnailImageData {
                                cell.contactImage?.image = UIImage(data: thumbnailImageData)
                            }
                        } else {
                            cell.contactImage?.backgroundColor = .lightGray
                            cell.contactImage?.image = UIImage(named: "")
                        }
                    }
                    else{
                        cell.contactImage?.backgroundColor = .lightGray
                        cell.contactImage?.image = UIImage(named: "")
                    }
                }
            }
            else{
                cell.contactName.text = historyRecord.details.remoteNumber
                cell.contactImage?.backgroundColor = .lightGray
//                cell.contactImage?.image = UIImage(named: "")
                cell.defaultContact.image = UIImage(named: "default_contact_white")
            }

        }
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
         let historyRecord = historyRecords[indexPath.row]
        
        if let details  = historyRecord.details , let contact = historyRecord.contact {
            invokeChatForNumber(number: details.remoteNumber ?? "", recordID: contact.recordID ?? "")
        }
        else{
            invokeChatForNumber(number: historyRecord.details.remoteNumber, recordID: "")
        }
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            let record = self.historyRecords[indexPath.row]
            
            guard let details = record.details else {return}
            self.dbManager?.deleteHistory(forNumber: details.remoteNumber ?? "")
            historyRecords.remove(at: indexPath.row)
            historyListView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    
    @IBAction func newMessageAction(_ sender: UIBarButtonItem) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let contactPickerController = storyboard.instantiateViewController(withIdentifier: "ContactPickerController") as? ContactPickerController
        contactPickerController?.mode = ContactPickerController.CP_MODE_NEW_MESSAGE
        contactPickerController?.delegate = self
        
        var navigationController: UINavigationController? = nil
        if let contactPickerController = contactPickerController {
            navigationController = UINavigationController(rootViewController: contactPickerController)
        }
        navigationController?.navigationBar.barTintColor = UIColor(red: 0.0, green: 137.0 / 255.0, blue: 123.0 / 255.0, alpha: 1.0)
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barStyle = .black
        
        if let navigationController = navigationController {
            present(navigationController, animated: true)
        }
        
    }
    
    
    //MARK: -----------
    
    func invokeChatForNumber(number : String,recordID : String){
        
        self.tabBarController?.selectedIndex = 1;
        
        let storyboard = UIStoryboard(name: "Chats", bundle: nil)
        let chatviewController = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController
        
        chatviewController?.remoteNumber = number
        chatviewController?.recordID = recordID
        chatviewController?.chatMode = 1

        let navigationController = UINavigationController(rootViewController: chatviewController!)
        navigationController.navigationBar.barTintColor = UIColor(red: 0.0 / 255.0, green: 137.0 / 255.0, blue: 123.0 / 255.0, alpha: 1.0)
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.barStyle = .black
        
        navigationController.modalPresentationStyle = .custom
        navigationController.transitioningDelegate = self
        present(navigationController, animated: true)

    }
    
    
    //MARK: ---------- Contact picker Delegate ----------
    
    func contactPickerController(_ picker: ContactPickerController, didFinishPicking contact: CSContact){
        
        picker.dismiss(animated: true, completion: nil)
        
        guard let number = contact.numbers[0] as? CSNumber else { return  }
        
        if let recordid = contact.recordID {
            invokeChatForNumber(number: number.number, recordID: recordid)
        }
        else{
            invokeChatForNumber(number: number.number, recordID: "")

        }
    
    }
    
    
    func contactPickerControllerDidCancel(_ picker: ContactPickerController) {
        picker.dismiss(animated: true, completion: nil)
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
