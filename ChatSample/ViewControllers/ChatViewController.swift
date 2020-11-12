//
//  ChatViewController.swift
//  ChatSample
//
//  Created by Murali Sai Tummala on 25/04/19.
//  Copyright © 2019 Voxvalley technologies. All rights reserved.
//

import UIKit
import Contacts
import VoxSDK
import MapKit
import MobileCoreServices
import AVFoundation
import MediaPlayer
import Photos
//import InStatDownloadButton





class ChatViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,UITextViewDelegate,ChatDetailCellDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIDocumentMenuDelegate,UIDocumentPickerDelegate,MPMediaPickerControllerDelegate,LocationViewControllerDelegate,ContactPickerControllerDelegate,UIDocumentInteractionControllerDelegate,AVAudioRecorderDelegate,AVAudioPlayerDelegate,UIGestureRecognizerDelegate{
    
    
    static let ktypeMsgStr = "Type a message"
    var remoteNumber = ""
    var recordID = ""
    var chatMode: Int = 0
    
    weak var dbManager: CSDataStore?
    var chatSession: CSChat?
    var forwardRecord: CSHistory?
    var unreadIndexPath: IndexPath?
    var swipedIndexPath: IndexPath?
    var presenceTimer: Timer?
    
    @IBOutlet weak var backBtn: UIButton!
    
    var nameLabel: UILabel!
    var lastSeenLabel: UILabel!
    
    @IBOutlet weak var dataTableView: UITableView!
    @IBOutlet weak var chatTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var emoticonButton: UIButton!
    @IBOutlet weak var chatEditView: UIView!
    @IBOutlet weak var editViewBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var editViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var noDataLabel: UILabel!
    
    var lastSeenDate: Date?
    var onlineStatus = false
    var recordLimit: Int = 0
    var historyRecords = [[CSHistory]]()
    var sectionHeaders = [Date]()
    
    
    var audioData: Data?
    var playerSlider: UISlider?
    var audioPlayer: AVAudioPlayer?
    var recordedData: Data?
    var playButton: UIButton?
    var timer: Timer?
    @IBOutlet weak var time_duration: UILabel!
    @IBOutlet weak var recordingView: UIView!
    
    
    
    var recorder: AVAudioRecorder?
    var session: AVAudioSession?
    var isRecording = false
    var playingRow: Int = 0
    var song: MPMediaItem?
    var profileImage:UIImageView!
    var exportURL: URL?
    
    
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        
        dismiss(animated: true, completion: nil)
        
    }
    
    //MARK: View life cycle methods.....
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.endEditing(true)
        recordingView.isHidden = true
        chatTextView.resignFirstResponder()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardFrameWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardFrameWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        // custom title view for name and last seen info
        let titleView = UIView()
        titleView.backgroundColor = UIColor.clear
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 2436:
                titleView.frame = CGRect(x: 50, y: self.backBtn.frame.size.height/2 + 20, width: 200, height: 44)
                
            case 2688:
               titleView.frame = CGRect(x: 50, y: self.backBtn.frame.size.height/2 + 20, width: 200, height: 44)
                
            case 1792:
                titleView.frame = CGRect(x: 50, y: self.backBtn.frame.size.height/2 + 20, width: 200, height: 44)
                
            default:
               titleView.frame = CGRect(x: 50, y: self.backBtn.frame.size.height/2, width: 200, height: 44)
            }
        }
       
       
        titleView.addSubview(self.profileImage)
        titleView.addSubview(self.nameLabel)
        titleView.addSubview(self.lastSeenLabel)
        titleView.tag = 99
        self.navigationController?.view.addSubview(titleView)
        self.navigationController?.view.bringSubviewToFront(titleView)
        
        if historyRecords.count > 0 {
            
            if let unreadindex = unreadIndexPath{
                
                dataTableView.scrollToRow(at: unreadindex, at: .top, animated: true)
                
            }
            else{
                let section  = historyRecords.count - 1
                
                let  indexPath = IndexPath(row: historyRecords[section].count-1, section: section)
                
                
                dataTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
            
            if (unreadIndexPath != nil){
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                    self.refreshHistoryInfo()
                })
            }
            
        }
        
        // register for chat notification
        NotificationCenter.default.addObserver(self, selector: #selector(handleChatNotification(notification:)), name: NSNotification.Name("ChatNotification"), object: nil)
        
        // register for chat delivery notification
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeliveryNotification(notification:)), name: NSNotification.Name("ChatDeliveryNotification"), object: nil)
        
        // register for presence notification
        NotificationCenter.default.addObserver(self, selector: #selector(handlePresenceNotification(notification:)), name: NSNotification.Name("PresenceNotification"), object: nil)
        
        // register for download notification
        NotificationCenter.default.addObserver(self, selector: #selector(handleDownloadNotification(notification:)), name: NSNotification.Name("DownloadNotification"), object: nil)
        
        // register for progress notification
        NotificationCenter.default.addObserver(self, selector: #selector(handleProgressNotification(notification:)), name: NSNotification.Name("FTProgressNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleThumbnailDownloadNotification(notification:)), name: NSNotification.Name("ThumbnailDownloadNotification"), object: nil)
        
        // TODO : Do we need to register to background notifications ??
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppEnterBackground(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppEnterForeground(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
      
        
        for subView in navigationController?.view.subviews ?? [] {
            if subView.tag == 99 {
                subView.removeFromSuperview()
            }
        }
        view.endEditing(true)
        NotificationCenter.default.removeObserver(self)
        if presenceTimer != nil {
            presenceTimer?.invalidate()
            presenceTimer = nil
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        recordLimit = 1000
        lastSeenDate = nil
        onlineStatus = false
        
        profileImage = UIImageView(frame: CGRect(x:0, y: 0, width: 40, height: 40))
        self.nameLabel = UILabel(frame: CGRect(x:self.profileImage.frame.size.width, y: 0, width: 150, height: 26))
        self.nameLabel.backgroundColor = .clear
        self.nameLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
        self.nameLabel.textAlignment = .center
        self.nameLabel.textColor = .white
        
        self.lastSeenLabel = UILabel(frame: CGRect(x:self.profileImage.frame.size.width, y: 26, width: 200, height: 14))
        self.lastSeenLabel.backgroundColor = .clear
        self.lastSeenLabel.font = UIFont.systemFont(ofSize: 12.0)
        self.lastSeenLabel.textAlignment = .center
        self.lastSeenLabel.textColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1.0)
        
        if chatMode == 0 {
            let contactStore = CSContactStore.sharedInstance()
            let record = contactStore?.getGroup(self.remoteNumber)
            self.nameLabel.text = record?.name
        }
        else{
            
            self.remoteNumber = self.remoteNumber.replacingOccurrences(of: "(", with: "")
            self.remoteNumber = self.remoteNumber.replacingOccurrences(of: ")", with: "")
            self.remoteNumber = self.remoteNumber.replacingOccurrences(of: "-", with: "")
            self.remoteNumber = self.remoteNumber.trimmingCharacters(in: .whitespaces)
            
            let contact = CSContactStore.sharedInstance()?.lookupContacts(byNumber: self.remoteNumber)
            let phoneNumber = contact?.numbers[0] as? CSNumber
            
            if contact != nil{
                if let contctname = contact?.name, contctname.count > 0{
                    self.nameLabel.text = contctname
                }
                else{
                    if let profilName = phoneNumber?.profileName, profilName.count > 0{
                        self.nameLabel.text = profilName
                    }
                    else{
                        self.nameLabel.text = phoneNumber?.number
                    }
                }
            }
            else{
                self.nameLabel.text = remoteNumber
                self.lastSeenLabel.text = ""
            }
       
           if phoneNumber?.profilePhotoPath != nil && phoneNumber?.profilePhotoPath != "" {
               profileImage.image = UIImage.init(contentsOfFile:phoneNumber?.profilePhotoPath ?? "")
            }
            else{
                self.profileImage.image = UIImage(named:"default_contact_white")
                self.profileImage.backgroundColor = UIColor.lightGray
            }
            self.profileImage.layer.cornerRadius = self.profileImage.frame.size.width/2;
            self.profileImage.clipsToBounds = true;
        }
        dbManager = CSDataStore.sharedInstance()
        chatSession = CSChat(forNumber: self.remoteNumber, withDelegate: nil)
        chatSession?.chatMode = self.chatMode
        unreadIndexPath = nil
        loadHistory(showUnreadSeparator: true)
        chatTextView.textContainerInset = UIEdgeInsets(top: 4.0, left: 0.0, bottom: 4.0, right: 0.0)
       
        // Presence refresh timeout
        
        presenceTimer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(self.presenceRefreshTimeout(_:)), userInfo: nil, repeats: true)
        chatSession?.getPresenceStatus()
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressed(onRecordButton:)))
        sendButton.addGestureRecognizer(longPressGesture)
        
    }
    
    func refreshHistoryInfo() {
        
        loadHistory(showUnreadSeparator: false)
        
        DispatchQueue.main.async {
            self.dataTableView.reloadData()
        }
        
        if historyRecords.count > 0 {
            
            if let unreadindex = unreadIndexPath{
                DispatchQueue.main.async {
                    self.dataTableView.scrollToRow(at: unreadindex, at: .top, animated: true)
                }
            }
            else{
                let section  = historyRecords.count - 1
                
                var indexPath : IndexPath!
                // TO-DO
                
                indexPath = IndexPath(row: historyRecords[section].count-1, section: section)
                
                DispatchQueue.main.async {
                    
                    self.dataTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                }
            }
            
            if (unreadIndexPath != nil){
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                    self.refreshHistoryInfo()
                })
            }
        }
    }
    
    // MARK: Button Actions.
    @IBAction func showMenu(_ sender: UIButton) {
        
        
        let menuSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        
        let contactAction = UIAlertAction(title: "Send Contact", style: .default, handler: {(alertaction:UIAlertAction) in
            
            // Send Contact
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let contactPickerController = storyboard.instantiateViewController(withIdentifier: "ContactPickerController") as? ContactPickerController
            contactPickerController?.mode = ContactPickerController.CP_MODE_SEND_CONTACT
            contactPickerController?.delegate = self
            
            var navigationController: UINavigationController? = nil
            if let contactPickerController = contactPickerController {
                navigationController = UINavigationController(rootViewController: contactPickerController)
            }
            navigationController?.navigationBar.barTintColor = UIColor(red: 0.0, green: 137.0 / 255.0, blue: 123.0 / 255.0, alpha: 1.0)
            navigationController?.navigationBar.isTranslucent = false
            navigationController?.navigationBar.barStyle = .black
            
            if let navigationController = navigationController {
                self.present(navigationController, animated: true)
            }
        })
        let locationAction = UIAlertAction(title: "Send Location", style: .default, handler: {(alertaction:UIAlertAction) in
            
            // Send Location
            let storyboard = UIStoryboard(name: "Chats", bundle: nil)
            let locationViewController = storyboard.instantiateViewController(withIdentifier: "LocationViewController") as? LocationViewController
            locationViewController?.delegate = self
            
            var navigationController: UINavigationController? = nil
            if let locationViewController = locationViewController {
                navigationController = UINavigationController(rootViewController: locationViewController)
            }
            navigationController?.navigationBar.barTintColor = UIColor(red: 0.0, green: 137.0 / 255.0, blue: 123.0 / 255.0, alpha: 1.0)
            navigationController?.navigationBar.isTranslucent = false
            navigationController?.navigationBar.barStyle = .black
            
            if let navigationController = navigationController {
                self.present(navigationController, animated: true)
            }
            
        })
        let documentAction = UIAlertAction(title: "Send Document", style: .default, handler: {(alertaction:UIAlertAction) in
            // Send Document
            
            let importMenu = UIDocumentPickerViewController(documentTypes: ["public.text"], in: .import)
            importMenu.delegate = self
            UINavigationBar.appearance().tintColor = UIColor.green
            
            self.present(importMenu, animated: true) {
                UINavigationBar.appearance().tintColor = UIColor.white
            }
            
        })
        let sendAudioAction = UIAlertAction(title: "Send Audio/Music", style: .default, handler: {(alertaction:UIAlertAction) in
            
            // Send Audio
            
            let medidPlayer = MPMediaPickerController(mediaTypes: .anyAudio)
            medidPlayer.allowsPickingMultipleItems = false
            medidPlayer.modalPresentationStyle = .currentContext
            medidPlayer.showsCloudItems = false
            medidPlayer.delegate = self
            UINavigationBar.appearance().tintColor = UIColor.green
            
            self.present(medidPlayer, animated: true) {
                UINavigationBar.appearance().tintColor = UIColor.white
            }
            
            
        })
        let sendPhotoAction = UIAlertAction(title: "Send Photo/Video", style: .default, handler: {(alertaction:UIAlertAction) in
            
            // Send Photo/Video Library
            
            ChatManager.shared.checkForPhotosPermission(withCompletionHandler: {(success : Bool) in
                
                if success{
                    let imagePickerController = UIImagePickerController()
                    imagePickerController.delegate = self
                    imagePickerController.allowsEditing = false
                    imagePickerController.sourceType = .photoLibrary
                    if let available = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
                        imagePickerController.mediaTypes = available
                    }
                    imagePickerController.navigationBar.barTintColor = UIColor(red: 0.0, green: 137.0 / 255.0, blue: 123.0 / 255.0, alpha: 1.0)
                    imagePickerController.navigationBar.isTranslucent = false
                    imagePickerController.navigationBar.barStyle = .black
                    
                    self.present(imagePickerController, animated: true)
                }
                else{
                    let alert = UIAlertController(title: nil, message: "Konverz needs permission to access photos/videos. Enable in Settings and try again", preferredStyle: .alert)
                    let settingsButton = UIAlertAction(title: "Settings", style: .default, handler: { action in
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    })
                    alert.addAction(settingsButton)
                    
                    let okButton = UIAlertAction(title: "Ok", style: .default, handler: { action in
                    })
                    
                    alert.addAction(okButton)
                    self.present(alert, animated: true)
                    
                }
                
            })
            
        })
        let TakePhotoAction = UIAlertAction(title: "Take Photo/Video", style: .default, handler: {(alertaction:UIAlertAction) in
            
            
            // Take Photo/Video Camera
            
            ChatManager.shared.checkForCameraPermission(withCompletionHandler: {(success : Bool) in
                
                if success{
                    let imagePickerController = UIImagePickerController()
                    imagePickerController.delegate = self
                    imagePickerController.allowsEditing = false
                    imagePickerController.sourceType = .camera
                    if let available = UIImagePickerController.availableMediaTypes(for: .camera) {
                        imagePickerController.mediaTypes = available
                    }
                    imagePickerController.navigationBar.barTintColor = UIColor(red: 0.0, green: 137.0 / 255.0, blue: 123.0 / 255.0, alpha: 1.0)
                    imagePickerController.navigationBar.isTranslucent = false
                    imagePickerController.navigationBar.barStyle = .black
                    
                    self.present(imagePickerController, animated: true)
                }
                else{
                    let alert = UIAlertController(title: nil, message: "Konverz needs permission to access photos/videos. Enable in Settings and try again", preferredStyle: .alert)
                    let settingsButton = UIAlertAction(title: "Settings", style: .default, handler: { action in
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    })
                    alert.addAction(settingsButton)
                    
                    let okButton = UIAlertAction(title: "Ok", style: .default, handler: { action in
                    })
                    
                    alert.addAction(okButton)
                    self.present(alert, animated: true)
                    
                }
                
            })
            
        })
        
        menuSheet.addAction(contactAction)
        menuSheet.addAction(locationAction)
        menuSheet.addAction(documentAction)
        menuSheet.addAction(sendAudioAction)
        menuSheet.addAction(sendPhotoAction)
        menuSheet.addAction(TakePhotoAction)
        menuSheet.addAction(cancelAction)
        self.present(menuSheet, animated: true, completion: nil)
        
    }
    
    @IBAction func sendAction(_ sender: UIButton) {
        
        var text = self.chatTextView.text
        text = text?.trimmingCharacters(in: .whitespaces)
        
        if (chatTextView.text == ChatViewController.ktypeMsgStr) || (chatTextView.text == "") {
            
            return
        }
        else if text!.count > 0 {
            
            chatSession?.sendMessage(text)
            refreshHistoryInfo()
            chatTextView.text = ""
            
            chatTextView.isScrollEnabled = false
            
            UIView.animate(withDuration: 0.1, animations: {
                
                self.editViewHeightConstraint.constant = 45
                self.view.layoutIfNeeded()
            }) { finished in
            }
        } else {
            sendButton.setImage(UIImage(named: "send"), for: .normal)
        }
    }
    
    
    
    //MARK:    ----- Audio Attachment Methods -----
    
    func setAudioRecorderSettings() {
        let fileName = "AUD-\(Int(Date().timeIntervalSince1970) * 1000).aac"
        
        
        guard let pathComponents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last else {return}
        
        let pathArray : [String] = [pathComponents, fileName]
        
        
        var outputFileURL = NSURL.fileURL(withPathComponents: pathArray )
        
        
        // Setup audio session
        session = AVAudioSession.sharedInstance()
        do {
            try session?.setCategory(.playAndRecord, options: .defaultToSpeaker)
        } catch {
        }
        
        var recordSetting: [String : Any] = [:]
        
        recordSetting[AVFormatIDKey] = NSNumber(value: Int32(kAudioFormatMPEG4AAC))
        recordSetting[AVSampleRateKey] = NSNumber(value: 44100.0)
        recordSetting[AVNumberOfChannelsKey] = NSNumber(value: 2)
        recordSetting[AVEncoderAudioQualityKey] = NSNumber(value: 4)
        do {
            
            if let outputFileURLTemp = outputFileURL {
                recorder = try AVAudioRecorder(url: outputFileURLTemp, settings: recordSetting)
                
            }
        }
        catch {
        }
        recorder?.delegate = self
        recorder?.isMeteringEnabled = true
        recorder?.prepareToRecord()
        
    }
    
    func startRecording() {
        time_duration.text = "Recording....  00:00                                       "
        //  record_time = @"00:00";
        recordingView.isHidden = false
        isRecording = true
        do {
            try session?.setActive(true, options: [])
        } catch  {
            
        }
        recorder?.record()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateSlider), userInfo: nil, repeats: true)
        isRecording = true
        recorder?.record()
    }
    
    func stopRecording() {
        view.endEditing(true)
        isRecording = false
        recordingView.isHidden = true
        recorder?.stop()
        timer?.invalidate()
        time_duration.text = ""
        do {
            try session?.setActive(false, options: [])
        } catch  {
            
        }
        
    }
    
    @objc func updateSlider() {
        // Update the slider about the music time
        
        guard let recorder = recorder else { return  }
        
        if recorder.isRecording {
            let minutes = floor(recorder.currentTime / 60)
            let seconds = Int(recorder.currentTime - (minutes * 60))
            
            let time = String(format: "%02ld:%02ld", minutes, seconds)
            time_duration.text = "Recording....  \(time)                                       "
            //  record_time = time;
        }
    }
    
    func sendRecording() {
        recordingView.isHidden = true
//        chatSession?.sendAudio(recorder?.url)
        refreshHistoryInfo()
        
    }
    
    @objc func longPressed(onRecordButton gesture: UILongPressGestureRecognizer?) {
        if gesture?.state == .began {
            let clientState = CSClient.sharedInstance().getState()
            if clientState == .inactive {
            }
            
            setAudioRecorderSettings()
            startRecording()
        } else if gesture?.state == .ended {
            
            stopRecording()
        }
    }
    
    func startRecordNotification() {
        
        let clientState = CSClient.sharedInstance().getState()
        if clientState == .inactive {
        }
        setAudioRecorderSettings()
        startRecording()
        
    }
    
    func stopRecordingNotification() {
        
        stopRecording()
    }
    
    
    //MARK: -----Audio Recorder Delegate-----
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        
        let menuSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let recordingAction = UIAlertAction(title: "Send Recording", style: .default, handler: {(alertaction:UIAlertAction) in
            
            self.sendRecording()
            
        })
        
        menuSheet.addAction(recordingAction)
        menuSheet.addAction(cancelAction)
        
        present(menuSheet, animated: true, completion: nil)
        
    }
    
    
    //MARK: -----MediaPicker Methods -----
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        mediaPicker.dismiss(animated: true, completion: nil)
        
        // Assign the selected item(s) to the music player and start playback.
        
        if mediaItemCollection.count < 1{
            return
        }
        
        song = mediaItemCollection.items[0]
        handleExportTapped()
        
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    
    func handleExportTapped() {
        
        guard let song = song else {
            return
        }
        
        let assetURL = song.value(forProperty: MPMediaItemPropertyAssetURL) as? URL
        var songAsset: AVURLAsset? = nil
        if let assetURL = assetURL {
            songAsset = AVURLAsset(url: assetURL, options: nil)
        }
        /* approach 1: export just the song itself
         */
        
        guard let songAssettemp = songAsset else { return  }
        
        guard let exporter = AVAssetExportSession(asset: songAssettemp, presetName: AVAssetExportPresetAppleM4A) else { return  }
        
        exporter.outputFileType = AVFileType("com.apple.m4a-audio")
        let fileName = "AUD-\(Int(Date().timeIntervalSince1970) * 1000).m4a"
        var paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        
        let exportFile = URL(fileURLWithPath: (paths[0] )).appendingPathComponent(fileName)
        exportURL = exportFile
        exporter.outputURL = exportFile
        
        exporter.exportAsynchronously(completionHandler: {
            switch exporter.status {
                
            case .failed:
                // log error to text view
                let exportError: Error? = exporter.error
                if let exportError = exportError {
                    print("AVAssetExportSessionStatusFailed: \(exportError)")
                }
            case .completed:
                print("AVAssetExportSessionStatusCompleted")
//                self.chatSession?.sendAudio(self.exportURL)
                self.chatSession?.sendAudio(self.exportURL, fileName: "")
                self.refreshHistoryInfo()
            case .unknown:
                print("AVAssetExportSessionStatusUnknown")
            case .exporting:
                print("AVAssetExportSessionStatusExporting")
            case .cancelled:
                print("AVAssetExportSessionStatusCancelled")
            case .waiting:
                print("AVAssetExportSessionStatusWaiting")
            default: break
                
            }
            
        })
    }
    
    func myDocumentsDirectory() -> String? {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        return paths[0]
        
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        recordedData = nil
        audioPlayer = nil
        playButton?.isSelected = false
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .defaultToSpeaker)
            
        } catch {
        }
        
    }
    
    
    /*
     
     
     */
    
    
    //MARK: ---- ImagePickerDelegate
    
    
    func scaleAndRotateImage(_ image: UIImage) -> UIImage? {
        
        var kMaxResolution: Int = 320
        
        guard let imgRef = image.cgImage else { return UIImage() }
        
        let width: CGFloat = CGFloat(integerLiteral: imgRef.width)
        let height: CGFloat = CGFloat(integerLiteral: imgRef.height)
        
        var transform: CGAffineTransform = .identity
        var bounds = CGRect(x: 0, y: 0, width: width, height: height)
        
        
        let scaleRatio: CGFloat = bounds.size.width / width
        
        let imageSize = CGSize(width: width, height: height)
        var boundHeight: CGFloat = 0.0
        let orient: UIImage.Orientation = image.imageOrientation
        
        switch orient {
        case UIImage.Orientation.up /*EXIF = 1 */:
            transform = CGAffineTransform.identity
        case UIImage.Orientation.upMirrored /*EXIF = 2 */:
            transform = CGAffineTransform(translationX: imageSize.width, y: 0.0)
            transform = transform.scaledBy(x: -1.0, y: 1.0)
        case UIImage.Orientation.down /*EXIF = 3 */:
            transform = CGAffineTransform(translationX: imageSize.width, y: imageSize.height)
            transform = transform.rotated(by: .pi)
        case UIImage.Orientation.downMirrored /*EXIF = 4 */:
            transform = CGAffineTransform(translationX: 0.0, y: imageSize.height)
            transform = transform.scaledBy(x: 1.0, y: -1.0)
        case UIImage.Orientation.leftMirrored /*EXIF = 5 */:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
        case UIImage.Orientation.left /*EXIF = 6 */:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(translationX: 0.0, y: imageSize.width)
            transform = transform.rotated(by: 3.0 * .pi / 2.0)
        case UIImage.Orientation.rightMirrored /*EXIF = 7 */:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            transform = transform.rotated(by: .pi / 2.0)
        case UIImage.Orientation.right /*EXIF = 8 */:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(translationX: imageSize.height, y: 0.0)
        default :
            let error: NSError?
            
            //          TO-DO  NSException.raise(NSExceptionName(rawValue: "Exception"), format:"Invalid image orientation", arguments:nil)
            break
            
        }
        
        UIGraphicsBeginImageContext(bounds.size)
        
        let context = UIGraphicsGetCurrentContext()
        
        if orient == .right || orient == .left {
            context?.scaleBy(x: -scaleRatio, y: scaleRatio)
            context?.translateBy(x: -height, y: 0)
        } else {
            context?.scaleBy(x: scaleRatio, y: -scaleRatio)
            context?.translateBy(x: 0, y: -height)
        }
        
        context?.concatenate(transform)
        
        UIGraphicsGetCurrentContext()?.draw(imgRef, in: CGRect(x: 0, y: 0, width: width, height: height))
        let imageCopy: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return imageCopy
        
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        
        guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String else { return  }
        
        
        if mediaType.elementsEqual("public.image") {
            
            DispatchQueue.main.async {
                var image: UIImage?
                print("\(#function) before scaleAndRotateImage")
                if picker.allowsEditing == true {
                    
                    if let imagetemp = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
                        image = self.scaleAndRotateImage(imagetemp)
                    }
                } else {
                    if let imagetemp = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                        image = self.scaleAndRotateImage(imagetemp)
                    }
                }
                print("\(#function) after scaleAndRotateImage")
                
                let imageData: Data? = image?.pngData()
                
                print("\(#function) before sendPhoto")
                
                var fromCamera = false
                
                if picker.sourceType == UIImagePickerController.SourceType.camera {
                    fromCamera = true
                } else {
                    fromCamera = false
                }
                
                
                if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset{
                    
                    if let fileName = asset.value(forKey: "filename") as? String, let imageUrl = info[UIImagePickerController.InfoKey.imageURL] as? URL{
                        
                        if #available(iOS 11.0, *) {
                            self.chatSession?.sendPhoto(imageUrl, fileName: fileName, fromCamera: fromCamera)
                        }
                        else{
                            self.chatSession?.sendPhoto(imageData, fileName: nil, contentType: CSImagePng, fromCamera: fromCamera)
                        }
                    }
                }
                else{
                    if let data = imageData {
                        self.chatSession?.sendPhoto(data, fileName: nil, contentType: CSImagePng, fromCamera: fromCamera)
                    }
                }
                
                print("\(#function) after sendPhoto")
                
                self.refreshHistoryInfo()
                
            }
        }
        if mediaType.elementsEqual("public.movie") {
            
            if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL{
                
//                self.chatSession?.sendVideo(videoUrl, fromCamera: true)
                self.chatSession?.sendVideo(videoUrl, fromCamera: true, fileName: "")
            }
            
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    
    
    //MARK: ----- DocumentMenu Delegate
    
    
    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
        
        
    }
    
    
    func documentMenu(_ documentMenu: UIDocumentPickerViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
        
    }
    
    
    /*
     -(void)documentMenu:(UIDocumentMenuViewController *)documentMenu didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker {
     
     documentPicker.delegate = self;
     [self presentViewController:documentPicker animated:YES completion:nil];
     }
     
     */
    //MARK: ------ DocumentPickerDelegate
    
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        for url in urls {
//            self.chatSession?.sendFile(url)
            self.chatSession?.sendFile(url, fileName: "")
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
//        self.chatSession?.sendFile(url)
        self.chatSession?.sendFile(url, fileName: "")
    }
    
    //MARK: ----- document interaction
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return navigationController!
    }
    
    func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        
    }
    
    //MARK: ---------- Contact picker Delegate ----------
    
    func contactPickerController(_ picker: ContactPickerController, didFinishPicking contact: CSContact){
        
        picker.dismiss(animated: true, completion: nil)
        self.chatSession?.send(contact)
        refreshHistoryInfo()
        
    }
    
    func contactPickerController(_ picker: ContactPickerController, didFinishPickingMultipleContacts contacts: [CSContact]) {
        
        
        picker.dismiss(animated: true, completion: nil)
        
        for contact in contacts {
            
            
            guard let phoneNumber = contact.numbers[0] as? CSNumber else {return}
            
            
            self.chatSession = CSChat(forNumber: phoneNumber.number ?? "", withDelegate: nil)
            
            guard let forwardRecord = forwardRecord else {return}
            
            
            switch forwardRecord.recordType {
                
            case .contact:
                
                self.chatSession?.send(contact)
                
            case .location:
                self.chatSession?.sendLocation("", latpos: forwardRecord.latpos, lonpos: forwardRecord.lonpos)
            case .message:
                self.chatSession?.sendMessage(forwardRecord.data)
            case .photo:
                
                let fileUrl = URL(fileURLWithPath: forwardRecord.localPath, isDirectory: false)
                do{
                    self.chatSession?.sendPhoto(try Data(contentsOf: fileUrl), fileName: nil, contentType: CSImagePng, fromCamera: false)
                }
                catch{
                    
                }
            case .video:
                let fileUrl = URL(fileURLWithPath: forwardRecord.localPath, isDirectory: false)
//                self.chatSession?.sendVideo(fileUrl, fromCamera: false)
                self.chatSession?.sendVideo(fileUrl, fromCamera: false, fileName: "")
            case .document:
                let fileUrl = URL(fileURLWithPath: forwardRecord.localPath, isDirectory: false)
//                self.chatSession?.sendFile(fileUrl)
                self.chatSession?.sendFile(fileUrl, fileName: "")
            default: break
                
            }
            
        }
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let rootViewController = storyBoard.instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController
        let overlayView: UIView = UIScreen.main.snapshotView(afterScreenUpdates: false)
        rootViewController?.view.addSubview(overlayView)
        
        UIApplication.shared.keyWindow?.rootViewController = rootViewController
        rootViewController?.selectedIndex = 1 // Contacts View
        
        UIView.animate(withDuration: 0.4, delay: 0.0, options: .transitionCrossDissolve, animations: {
            overlayView.alpha = 0
        }) { finished in
            overlayView.removeFromSuperview()
        }
        
    }
    
    
    
    func contactPickerControllerDidCancel(_ picker: ContactPickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: ---------- Location Delegate ----------
    
    func locationViewController(_ picker: LocationViewController?, didFinishPickingLocation location: CLLocationCoordinate2D) {
        
        self.chatSession?.sendLocation("", latpos: location.latitude, lonpos: location.longitude)
        refreshHistoryInfo()
        picker?.dismiss(animated: true, completion: nil)
        
    }
    
    func locationViewControllerDidCancel(_ picker: LocationViewController?) {
        picker?.dismiss(animated: true, completion: nil)
        
    }
    
    
    
    //MARK:  ----- timer handling
    
    
    @objc func presenceRefreshTimeout(_ timer: Timer?) {
        refreshLastSeenLabel()
    }
    
    
    
    
    
    //MARK:  ----- UIViewControllerAnimatedTransitioning -----
    
    let ChatPresentedViewHeightPortrait: CGFloat = 720.0
    let ChatPresentedViewHeightLandscape: CGFloat = 440.0
    
    /*
     func rect(forDismissedState transitionContext: Any, isPresenting: Bool) -> CGRect {
     
     var fromViewController: UIViewController?
     let containerView: UIView? = (transitionContext as AnyObject).containerView
     
     if isPresenting {
     fromViewController = (transitionContext as AnyObject).viewController(forKey: .from)
     } else {
     fromViewController = (transitionContext as AnyObject).viewController(forKey: .to)
     }
     
     switch fromViewController?. {
     case .landscapeRight?:
     return CGRect(x: CGFloat(-ChatPresentedViewHeightLandscape), y: 0, width: CGFloat(ChatPresentedViewHeightLandscape), height: containerView?.bounds.size.height ?? 0.0)
     case .landscapeLeft?:
     return CGRect(x: containerView?.bounds.size.width, y: 0, width: CGFloat(ChatPresentedViewHeightLandscape), height: containerView?.bounds.size.height)
     case .portraitUpsideDown?:
     return CGRect(x: 0, y: CGFloat(-ChatPresentedViewHeightPortrait), width: containerView?.bounds.size.width, height: CGFloat(ChatPresentedViewHeightPortrait))
     case .portrait?:
     //            return CGRectMake(0, containerView.bounds.size.height,
     //                              containerView.bounds.size.width, PresentedViewHeightPortrait);
     return CGRect(x: containerView?.bounds.size.width, y: 0, width: containerView.bounds.size.width, height: containerView.bounds.size.height)
     default:
     return CGRect.zero
     }
     
     }
     
     
     */
    //MARK: --- Tableview methods Handling.........
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return  historyRecords.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyRecords[section].count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 28))
        
        let dateLabel = UILabel(frame: CGRect(x: (tableView.frame.size.width - 100) / 2, y: 4, width: 100, height: 20))
        dateLabel.font = UIFont.boldSystemFont(ofSize: 12)
        dateLabel.textAlignment = .center
        dateLabel.textColor = UIColor.white
        dateLabel.backgroundColor = UIColor(red: 102.0 / 255.0, green: 204.0 / 255.0, blue: 1.0, alpha: 1.0)
        dateLabel.layer.cornerRadius = 10
        dateLabel.clipsToBounds = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.doesRelativeDateFormatting = true
        dateFormatter.locale = NSLocale.current
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .medium
        var text: String? = nil
        
        text = dateFormatter.string(from: sectionHeaders[section])
        dateLabel.text = text
        
        view.addSubview(dateLabel)
        
        return view
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        let record = historyRecords[indexPath.section][indexPath.row]
        
        let rightCellIdentifier = "RightChatCell"
        let leftCellIdentifier = "LeftChatCell"
        
        let rightImageCellIdentifier = "RightGIFCell"
        let leftImageCellIdentifier = "LeftGIFCell"
        
        let rightVideoCellIdentifier = "RightVideoCell"
        let leftVideoCellIdentifier = "LeftVideoCell"
        
        let rightContactCellIdentifier = "RightContactCell"
        let leftContactCellIdentifier = "LeftContactCell"
        
        let infoCellIdentifier = "ChatInfoCell"
        let callInfoCellIdentifier = "CallInfoCell"
        
        let rightAudioCellIdentifier = "RightAudioCell"
        let leftAudioCellIdentifier = "LeftAudioCell"
        
        var cell: ChatDetailCell? = nil
        
        switch record.recordType {
        case .info:
            cell = tableView.dequeueReusableCell(withIdentifier: infoCellIdentifier) as? ChatDetailCell
            break
        case .call:
            cell = tableView.dequeueReusableCell(withIdentifier: callInfoCellIdentifier) as? ChatDetailCell
            break
        case .contact:
            
            if record.direction == 0{
                cell = tableView.dequeueReusableCell(withIdentifier: rightContactCellIdentifier) as? ChatDetailCell
            }else{
                cell = tableView.dequeueReusableCell(withIdentifier: leftContactCellIdentifier) as? ChatDetailCell
            }
            
            let name = cell?.contentView.viewWithTag(102) as? UILabel
            let timestamp = cell?.contentView.viewWithTag(103) as? UILabel
            
            
            let jsonData: Data? = record.data.data(using: .utf8)
            var contact: [AnyHashable : Any]? = nil
            do {
                if let jsonData = jsonData {
                    contact = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [AnyHashable : Any]
                }
            } catch {
                
            }
            
            if let nametext = contact?["name"] as? String{
                name?.text = nametext
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = NSLocale.current
            dateFormatter.timeStyle = .short
            dateFormatter.dateStyle = .none
            
            timestamp?.text = dateFormatter.string(from: record.startTime)
            if record.direction == 0{
                let deliveryStatus = cell?.contentView.viewWithTag(104) as? UIImageView
                deliveryStatus?.image = imageForStatus(status: CSChatStatus(rawValue: record.status)!)
            }
            
            break
        case .location:
            if record.direction == 0{
                cell = tableView.dequeueReusableCell(withIdentifier: rightImageCellIdentifier) as? ChatDetailCell
            }else{
                cell = tableView.dequeueReusableCell(withIdentifier: leftImageCellIdentifier) as? ChatDetailCell
            }
            
            weak var imageView = cell?.contentView.viewWithTag(101) as? UIImageView
            imageView?.image = UIImage()
            
            let options = MKMapSnapshotter.Options()
            options.showsBuildings = true
            options.showsPointsOfInterest = true
            options.region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(record.latpos, record.lonpos), latitudinalMeters: 1000, longitudinalMeters: 1000)
            options.scale = UIScreen.main.scale
            options.size = CGSize(width: 128.0, height: 128.0)
            
            let snapshotter = MKMapSnapshotter(options: options)
            snapshotter.start(completionHandler: { snapshot, error in
                
                imageView?.image = snapshot?.image
            })
            
            let timestamp = cell?.contentView.viewWithTag(103) as? UILabel
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = NSLocale.current
            dateFormatter.timeStyle = .short
            dateFormatter.dateStyle = .none
            
            timestamp?.text = dateFormatter.string(from: record.startTime)
         
            if record.direction == 0 {
                let gifButton = cell?.contentView.viewWithTag(106) as? UIButton
                let activity = cell?.contentView.viewWithTag(109) as? UIButton
                gifButton?.isHidden = true
                activity?.isHidden = true
                let deliveryStatus = cell?.contentView.viewWithTag(104) as? UIImageView
                deliveryStatus?.image = imageForStatus(status: CSChatStatus(rawValue: record.status)!)
            }
  
            break
        case .message:
            
            if record.direction == 0{
                cell = tableView.dequeueReusableCell(withIdentifier: rightCellIdentifier) as? ChatDetailCell
            }else{
                cell = tableView.dequeueReusableCell(withIdentifier: leftCellIdentifier) as? ChatDetailCell
            }
            
            let message = cell?.contentView.viewWithTag(102) as? UILabel
            let timestamp = cell?.contentView.viewWithTag(103) as? UILabel
            
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = NSLocale.current
            dateFormatter.timeStyle = .short
            dateFormatter.dateStyle = .none
            
            timestamp?.text = dateFormatter.string(from: record.startTime)
            
            if let meSsage = record.data{
                message?.text = meSsage
            }
            if record.direction == 0{
                let deliveryStatus = cell?.contentView.viewWithTag(104) as? UIImageView
                deliveryStatus?.image = imageForStatus(status: CSChatStatus(rawValue: record.status)!)
            }
            break
        case .photo:
            if record.direction == 0{
                cell = tableView.dequeueReusableCell(withIdentifier: rightImageCellIdentifier) as? ChatDetailCell
            }else{
                cell = tableView.dequeueReusableCell(withIdentifier: leftImageCellIdentifier) as? ChatDetailCell
            }
            
            let imageView = cell?.contentView.viewWithTag(101) as? UIImageView
            
            var res: Bool = FileManager.default.fileExists(atPath: record.localPath, isDirectory: nil)
            
            res = FileManager.default.fileExists(atPath: record.data, isDirectory: nil)
            
            if FileManager.default.fileExists(atPath: record.localPath, isDirectory: nil) {
                
                imageView?.image = UIImage(contentsOfFile: record.localPath)
            } else if FileManager.default.fileExists(atPath: record.thumbnailPath, isDirectory: nil) {
                imageView?.image = UIImage(contentsOfFile: record.thumbnailPath)
            } else {
                imageView?.image = UIImage()
            }
            
            let timestamp = cell?.contentView.viewWithTag(103) as? UILabel
            let dateFormatter = DateFormatter()
            dateFormatter.locale = NSLocale.current
            dateFormatter.timeStyle = .short
            dateFormatter.dateStyle = .none
            let activity = cell?.contentView.viewWithTag(109) as? UIButton
            activity?.addTarget(self, action: #selector(instaDownloadBtn), for: UIControl.Event.touchUpInside)
            timestamp?.text = dateFormatter.string(from: record.startTime)
            if record.direction == 0{
                let deliveryStatus = cell?.contentView.viewWithTag(104) as? UIImageView
                if record.status ==  0 {
                     activity?.isHidden = false
//                     activity?.downloadState = .pending
                     deliveryStatus?.image = imageForStatus(status: CSChatStatus(rawValue: record.status)!)
                }else{
                     activity?.isHidden = true
//                      activity?.downloadState = .finish
                     deliveryStatus?.image = imageForStatus(status: CSChatStatus(rawValue: record.status)!)
                }
               
            }
            if record.transferStatus == .downloadCompleted || record.transferStatus == .uploadCompleted {
                activity?.isHidden = true
            }
            
            break
        case .video:
            if record.direction == 0{
                cell = tableView.dequeueReusableCell(withIdentifier: rightVideoCellIdentifier) as? ChatDetailCell
            }else{
                cell = tableView.dequeueReusableCell(withIdentifier: leftVideoCellIdentifier) as? ChatDetailCell
            }
            
            let imageView = cell?.contentView.viewWithTag(101) as? UIImageView
            
            if record.thumbnailPath.count > 0 && record.thumbnailStatus == .downloadCompleted {
                imageView?.image = UIImage(contentsOfFile: record.thumbnailPath)
            } else {
                let asset = AVURLAsset(url: URL(fileURLWithPath: record.localPath), options: nil)
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                imageGenerator.apertureMode = .encodedPixels
                imageGenerator.requestedTimeToleranceAfter = CMTime.zero;
                imageGenerator.requestedTimeToleranceBefore = CMTime.zero;
                var thumbnailImageRef: CGImage? = nil
                var time: CMTime = asset.duration
                time.value = CMTimeValue(0)
                do {
                    thumbnailImageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)

                    if let thumbnailImageRefTemp = thumbnailImageRef{

                        imageView?.image = UIImage(cgImage: thumbnailImageRefTemp)
                    }

                } catch {
                }
    
            }
            
            let timestamp = cell?.contentView.viewWithTag(103) as? UILabel
            let dateFormatter = DateFormatter()
            dateFormatter.locale = NSLocale.current
            dateFormatter.timeStyle = .short
            dateFormatter.dateStyle = .none
            
            timestamp?.text = dateFormatter.string(from: record.startTime)
            
          
            let activity = cell?.contentView.viewWithTag(109) as? UIButton
            let playButton = cell?.contentView.viewWithTag(106) as? UIButton
             playButton?.isHidden = true
             activity?.addTarget(self, action: #selector(instaDownloadBtn), for: UIControl.Event.touchUpInside)
           
            
            if record.direction == 0{
                let deliveryStatus = cell?.contentView.viewWithTag(104) as? UIImageView
                if record.status ==  0 {
                    activity?.isHidden = false
//                    activity?.downloadState = .pending
                    deliveryStatus?.image = imageForStatus(status: CSChatStatus(rawValue: record.status)!)
                }else{
                    activity?.isHidden = true
//                    activity?.downloadState = .finish
                    deliveryStatus?.image = imageForStatus(status: CSChatStatus(rawValue: record.status)!)
                }
                
            }
            
            if record.transferStatus == .downloadCompleted || record.transferStatus == .uploadCompleted {
                print("process completed")
                activity?.isHidden = true
                playButton?.isHidden = false
            }
            break
        case .audio:
            if record.direction == 0{
                cell = tableView.dequeueReusableCell(withIdentifier: rightAudioCellIdentifier) as? ChatDetailCell
            }else{
                cell = tableView.dequeueReusableCell(withIdentifier: leftAudioCellIdentifier) as? ChatDetailCell
            }
            let timestamp = cell?.contentView.viewWithTag(103) as? UILabel
            let dateFormatter = DateFormatter()
            dateFormatter.locale = NSLocale.current
            dateFormatter.timeStyle = .short
            dateFormatter.dateStyle = .none
            
            timestamp?.text = dateFormatter.string(from: record.startTime)
            
            let bubbleImage = cell?.viewWithTag(101) as? UIImageView
            bubbleImage?.layer.cornerRadius = 8
            
            let play = cell?.viewWithTag(109) as? UIButton
            //[play setTag:indexPath.row];
            play?.addTarget(self, action: #selector(self.playAudioRecording(_:)), for: .touchUpInside)
            
            let duration = cell?.contentView.viewWithTag(110) as? UILabel
            
            let parseArray = record.localPath.components(separatedBy: ".")
            
            if (parseArray.last == "aac") || (parseArray.last == "mp3") || (parseArray.last == "m4a") {
                
                // Audio implemetation
                
                let fileUrl = URL(fileURLWithPath: record.localPath)
                
                do{
                    let temp_recordedData =  try Data(contentsOf: fileUrl)
                    var player: AVAudioPlayer? = nil
                    do {
                        player = try AVAudioPlayer(data: temp_recordedData)
                        duration?.text = formatTimeString((player?.duration)!, asNegative: false)
                        player = nil
                        
                    } catch {
                        print("error is \(error)")
                    }
                }
                catch
                {
                    print("error is \(error)")
                }
                
            }
            if(record.direction == 0) {
                
                let deliveryStatus = cell?.contentView.viewWithTag(104) as? UIImageView
                deliveryStatus?.image = imageForStatus(status: CSChatStatus(rawValue: record.status)!)
                
            }
            
            let activity = cell?.contentView.viewWithTag(105) as? UIActivityIndicatorView
            
//            if record.transferStatus == .downloadInProgress || record.transferStatus == .uploadInProgress  || record.transferStatus == .downloadPending  || record.transferStatus == .uploadPending  {
//                play?.isHidden = true
//                activity?.startAnimating()
//            } else {
//                play?.isHidden = false
//                activity?.stopAnimating()
//            }
            
            break
            
        case .document:
            if record.direction == 0{
                cell = tableView.dequeueReusableCell(withIdentifier: rightContactCellIdentifier) as? ChatDetailCell
            }else{
                cell = tableView.dequeueReusableCell(withIdentifier: leftContactCellIdentifier) as? ChatDetailCell
            }
            
            let docicon = cell?.contentView.viewWithTag(105) as? UIImageView
            
            docicon?.image = UIImage(named: "document")
            
            let name = cell?.contentView.viewWithTag(102) as? UILabel
            
            if (record.fileName != nil) && record.fileName.count > 0 {
                name?.text = record.fileName
            } else {
                name?.text = URL(fileURLWithPath: record.localPath).lastPathComponent
            }
            let timestamp = cell?.contentView.viewWithTag(103) as? UILabel
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = NSLocale.current
            dateFormatter.timeStyle = .short
            dateFormatter.dateStyle = .none
            
            timestamp?.text = dateFormatter.string(from: record.startTime)
            let deliveryStatus = cell?.contentView.viewWithTag(104) as? UIImageView
            deliveryStatus?.image = imageForStatus(status: CSChatStatus(rawValue: record.status)!)
            
            break
            
        default:
            break
            
        }
        cell?.canBecomeFirstResponder
        cell?.cellDelegate = self
        cell?.layoutIfNeeded()
        if indexPath.row == historyRecords.count - 1 && recordLimit == historyRecords.count {
            recordLimit += 20
            loadHistory(showUnreadSeparator: false)
        }
        
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        view.endEditing(true)
        
        let record = historyRecords[indexPath.section][indexPath.row]
        
        switch record.recordType {
        case .location:
            let url = "http://maps.apple.com/maps?saddr=\(record.latpos),\(record.lonpos)"
            if let url = URL(string: url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            break
        case .document,.photo,.video:
            if !(record.transferStatus == .downloadCompleted || record.transferStatus == .uploadCompleted) {
                return
            }
            
            let url = URL(fileURLWithPath: record.localPath)
            
            let popup = UIDocumentInteractionController(url: url)
            
            popup.name = self.nameLabel.text
            
            popup.delegate = self
            popup.presentPreview(animated: true)
            break
        case .contact:
             let storyboard = UIStoryboard(name: "Chats", bundle: nil)
             let sharedContactVC = storyboard.instantiateViewController(withIdentifier:"ShareContactViewController") as! ShareContactViewController
             sharedContactVC.record = record
          
             let jsonData: Data? = record.data.data(using: .utf8)
             do {
                if let jsonData = jsonData {
                    sharedContactVC.contact = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? NSDictionary
                }
             } catch {
             }
             
            self.navigationController?.pushViewController(sharedContactVC, animated: true)
            break
            
        default:
            break
        }
    }
    
    @objc func saveTapped() {
        // ...
    }
    @objc func deleteTapped() {
        // ...
    }
    
    @objc func instaDownloadBtn( _sender: UIButton) {
        
        let buttonPosition = _sender.convert(CGPoint.zero, to: self.dataTableView)
        let indexPath = self.dataTableView.indexPathForRow(at:buttonPosition)
        let cell = self.dataTableView.cellForRow(at:indexPath!) as! ChatDetailCell
        let record = historyRecords[indexPath?.section ?? 0][indexPath?.row ?? 0]
        print("insta Download")
        let activity = cell.contentView.viewWithTag(109) as? UIButton
        activity?.tag = indexPath?.row ?? 0
        let gifButton = cell.contentView.viewWithTag(106) as? UIButton
        gifButton?.isHidden = true
        activity?.isHidden = false
        
//        if record.transferStatus == .uploadInProgress || record.transferStatus == .downloadInProgress {
//            activity?.isHidden = false
////            activity?.downloadState = .start
////            activity?.downloadState = .downloading
//            let progress: Progress? = chatSession?.getProgressForMessage(record.messageID)
////            activity?.progressView.progress = Double(progress?.fractionCompleted ?? 0.0)
//
//        } else if record.transferStatus == .downloadInProgress || record.transferStatus == .uploadInProgress {
//            let progress: Progress? = chatSession?.getProgressForMessage(record.messageID)
////            activity?.downloadState = .downloading
////            activity?.progressView.progress = Double(progress?.fractionCompleted ?? 0.0)
//            gifButton?.isHidden = true
//            activity?.isHidden = false
//        } else {
//            activity?.isHidden = true
////            activity?.downloadState = .finish
//            if (record.contentType == "image/gif") {
//                gifButton?.isHidden = false
//            } else {
//                gifButton?.isHidden = true
//            }
//        }
    }
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let record = historyRecords[indexPath.section][indexPath.row]
        
        switch record.recordType {
            
        case .contact:
            return 64
        case .info:
            return 32
        case .location:
            return 184
        case .message:
            let rect: CGRect = record.data.boundingRect(with: CGSize(width: 245.0, height: 0.0), options: .usesLineFragmentOrigin, attributes: [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16.0)
                ], context: nil)
            return ceil(rect.size.height) + 56
        case .photo:
            return 270
        case .video:
            return 270
            
        default:
            return 64
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 28.0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            let record = historyRecords[indexPath.section][indexPath.row]
            dbManager?.deleteHistoryRecord(record.messageID)
            
            let section = historyRecords[indexPath.section]
            if (section.count) <= 1 {
                historyRecords.remove(at: indexPath.section)
                sectionHeaders.remove(at: indexPath.section)
                dataTableView.deleteSections(NSIndexSet(index: indexPath.section) as IndexSet, with: .fade)
            } else {
                historyRecords[indexPath.section].remove(at: indexPath.row)
                dataTableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }
   
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(copyItem(_:)) || action == #selector(deleteItem(_:)) || action == #selector(forwardItem(_:)){
            return true
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        
        
        if action == #selector(self.copy(_:)) {
            
            let record = historyRecords[indexPath.section][indexPath.row]
            UIPasteboard.general.string = record.data
        } else if action == #selector(self.infoMenuAction(_:)) {
            
            swipedIndexPath = indexPath
            
            performSegue(withIdentifier: "showMessageInfo", sender: self)
        } else if action == #selector(self.shareMenuAction(_:)) {
            
            swipedIndexPath = indexPath
            
            performSegue(withIdentifier: "showMessageInfo", sender: self)
            
            let record = historyRecords[indexPath.section][indexPath.row]
            showUIActivityViewController(record)
        }
       else if action == #selector(self.forwardMenuAction(_:)) {
            
            // TBD
            performSegue(withIdentifier: "showMessageInfo", sender: self)
            var record = historyRecords[indexPath.section][indexPath.row]
            // [GlobalVariables sharedInstance].forwardMsgDic = [[NSMutableDictionary alloc]init];
            //   [GlobalVariables sharedInstance].isFromForwardMessage = true ;
            //  [self setForwardMsgDic:record];
        } else if action == #selector(self.deleteMenuAction(_:)) {
            
            let record = historyRecords[indexPath.section][indexPath.row]
            dbManager?.deleteHistoryRecord(record.messageID)
            historyRecords[indexPath.section].remove(at: indexPath.row)
            dataTableView.deleteRows(at: [indexPath], with: .fade)
        }
        
    }
    
    //MARK: ChatDetailcell Delegate....

    func tableCellSelected(tableCell: ChatDetailCell)
    {
        let longprss : UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressDetected(sender:)))
        longprss.delegate = self
        tableCell.addGestureRecognizer(longprss)
    }
  
    @objc func longPressDetected(sender : UILongPressGestureRecognizer){
        print("long press detected")
       
            let touchPoint = sender.location(in: self.dataTableView)
            if let indexPath = self.dataTableView.indexPathForRow(at: touchPoint) {
                let cell = self.dataTableView.cellForRow(at:indexPath) as! ChatDetailCell
                print("Long pressed row: \(indexPath.row) \(touchPoint)" )
                cell.canBecomeFirstResponder
                let menuCOntroller : UIMenuController  = UIMenuController.shared
                let forwarditem = UIMenuItem(title: "Forward", action: #selector(forwardItem(_:)))
                let copyitem = UIMenuItem(title: "Copy", action: #selector(copyItem(_:)))
                let deleteitem = UIMenuItem(title: "Delete", action: #selector(deleteItem(_:)))
                menuCOntroller.menuItems = [copyitem,forwarditem,deleteitem]
                menuCOntroller.setTargetRect(self.dataTableView .rectForRow(at:indexPath), in: self.dataTableView)
                menuCOntroller.setMenuVisible(true, animated: true)
            }
    }
    
   
    
    
    @IBAction func forwardItem(_ sender: Any){
        print("forward tapped")
        
        let btn = sender as? UIMenuController
        var frame: CGRect?
        let btnFrame = btn?.menuFrame
        frame = btnFrame
      //  if (chatEditView.frame.origin.y - chatEditView.frame.size.height) > (btnFrame?.origin.y ?? 0.0) {
       //     frame?.origin.y = (btnFrame?.origin.y ?? 0.0) + 85
            frame?.size.width = 1
            frame?.size.height = 1
            let view = UIView(frame: frame ?? CGRect.zero)
            self.view.addSubview(view)
            let btn_Position = view.convert(CGPoint.zero, to: dataTableView)
            let indexPath: IndexPath? = dataTableView.indexPathForRow(at: btn_Position)
            view.removeFromSuperview()
            let record = (historyRecords[indexPath?.section ?? 0])[indexPath?.row ?? 0]
            setForwardMsgDic(record)
      //  }
    }
    @IBAction func copyItem(_ sender: Any){
        print("copy tapped")
        let btn = sender as? UIMenuController
        let btnFrame = btn?.menuFrame
        var frame: CGRect?
        frame = btnFrame
      //  if (chatEditView.frame.origin.y - chatEditView.frame.size.height) > (frame?.origin.y ?? 0.0) {
         //   frame?.origin.y = (btnFrame?.origin.y ?? 0.0) + 85
            frame?.size.width = 1
            frame?.size.height = 1
           let view = UIView(frame: frame ?? CGRect.zero)
            self.view.addSubview(view)
            let btn_Position = view.convert(CGPoint.zero, to: dataTableView)
            var indexPath: IndexPath? = dataTableView.indexPathForRow(at: btn_Position)
            view.removeFromSuperview()
            let record = (historyRecords[indexPath?.section ?? 0])[indexPath?.row ?? 0]
            let pasteboard = UIPasteboard.general
            pasteboard.string = record.data
//}
    }
    
    @IBAction func deleteItem(_ sender: Any){
        print("delete tapped")
        let btn = sender as? UIMenuController
        
        var frame: CGRect?
        let btnFrame = btn?.menuFrame
         frame = btnFrame
      //  if (chatEditView.frame.origin.y - chatEditView.frame.size.height) > (btnFrame?.origin.y ?? 0.0) {
        //    frame?.origin.y = (btnFrame?.origin.y ?? 0.0) + 85
            frame?.size.width = 1
            frame?.size.height = 1
            let view = UIView(frame: frame ?? CGRect.zero)
            self.view.addSubview(view)
            let btn_Position = view.convert(CGPoint.zero, to: dataTableView)
            let indexPath: IndexPath? = dataTableView.indexPathForRow(at: btn_Position)
            view.removeFromSuperview()
            
            if let indexpath = indexPath{
                let record = (historyRecords[indexpath.section ])[indexpath.row]
                dbManager?.deleteHistoryRecord(record.messageID)
                (historyRecords[indexpath.section]).remove(at: indexpath.row)
                dataTableView.deleteRows(at: [indexpath], with: .fade)
            }
       // }
    }
    //MARK: Custom menu items
    
    @objc func infoMenuAction(_ sender: Any) {
        
    }

    
    @objc func shareMenuAction(_ sender: Any) {
        let btn = sender as? UIMenuController
        var frame: CGRect?
        let btnFrame = btn?.menuFrame
        if (chatEditView.frame.origin.y - chatEditView.frame.size.height) > (btnFrame?.origin.y ?? 0.0) {
            frame?.origin.y = (btnFrame?.origin.y ?? 0.0) + 85
            frame?.size.width = 1
            frame?.size.height = 1
            let view = UIView(frame: frame ?? CGRect.zero)
            self.view.addSubview(view)
            let btn_Position = view.convert(CGPoint.zero, to: dataTableView)
            let indexPath: IndexPath? = dataTableView.indexPathForRow(at: btn_Position)
            view.removeFromSuperview()
            let record = (historyRecords[indexPath?.section ?? 0])[indexPath?.row ?? 0]
            showUIActivityViewController(record)
        }
    }
    
    @objc func forwardMenuAction(_ sender: Any) {
        let btn = sender as? UIMenuController
        var frame: CGRect?
        let btnFrame = btn?.menuFrame
        if (chatEditView.frame.origin.y - chatEditView.frame.size.height) > (btnFrame?.origin.y ?? 0.0) {
            frame?.origin.y = (btnFrame?.origin.y ?? 0.0) + 85
            frame?.size.width = 1
            frame?.size.height = 1
            let view = UIView(frame: frame ?? CGRect.zero)
            self.view.addSubview(view)
            let btn_Position = view.convert(CGPoint.zero, to: dataTableView)
            let indexPath: IndexPath? = dataTableView.indexPathForRow(at: btn_Position)
            view.removeFromSuperview()
            let record = (historyRecords[indexPath?.section ?? 0])[indexPath?.row ?? 0]
            setForwardMsgDic(record)
        }
        
    }
    
  
    override func copy(_ sender: (Any)?) {
        let btn = sender as? UIMenuController
        let btnFrame = btn?.menuFrame
        var frame: CGRect?
        frame = btnFrame
        if (chatEditView.frame.origin.y - chatEditView.frame.size.height) > (frame?.origin.y ?? 0.0) {
            frame?.origin.y = (btnFrame?.origin.y ?? 0.0) + 85
            frame?.size.width = 1
            frame?.size.height = 1
            let view = UIView(frame: frame ?? CGRect.zero)
            view.addSubview(view)
            let btn_Position = view.convert(CGPoint.zero, to: dataTableView)
            var indexPath: IndexPath? = dataTableView.indexPathForRow(at: btn_Position)
            view.removeFromSuperview()
            let record = (historyRecords[indexPath?.section ?? 0])[indexPath?.row ?? 0]
            let pasteboard = UIPasteboard.general
            pasteboard.string = record.data
        }
    }
    
    @objc func deleteMenuAction(_ sender: Any) {
        let btn = sender as? UIMenuController
        
        var frame: CGRect?
        let btnFrame = btn?.menuFrame
        
        if (chatEditView.frame.origin.y - chatEditView.frame.size.height) > (btnFrame?.origin.y ?? 0.0) {
            frame?.origin.y = (btnFrame?.origin.y ?? 0.0) + 85
            frame?.size.width = 1
            frame?.size.height = 1
            let view = UIView(frame: frame ?? CGRect.zero)
            view.addSubview(view)
            let btn_Position = view.convert(CGPoint.zero, to: dataTableView)
            let indexPath: IndexPath? = dataTableView.indexPathForRow(at: btn_Position)
            view.removeFromSuperview()
            
            if let indexpath = indexPath{
                let record = (historyRecords[indexpath.section ])[indexpath.row]
                dbManager?.deleteHistoryRecord(record.messageID)
                (historyRecords[indexpath.section]).remove(at: indexpath.row)
                dataTableView.deleteRows(at: [indexpath], with: .fade)
            }
        }
    }
    
    @objc func setForwardMsgDic(_ record: CSHistory?) {
        forwardRecord = record
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let contactPickerController = storyboard.instantiateViewController(withIdentifier: "ContactPickerController") as? ContactPickerController
        contactPickerController?.mode = ContactPickerController.CP_MODE_FORWARD
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
    
    
    func showUIActivityViewController(_ record: CSHistory) {
        
        var activityItems = [Any]()
        
        switch record.recordType {
        case .contact:
            activityItems = [record.data as Any]
        case .location:
            let locUrl = URL(string: "http://maps.apple.com/?daddr=\(record.latpos),\(record.lonpos)")
            activityItems = [locUrl as Any]
        case .message:
            activityItems = [record.data as Any]
        case .photo:
            let fileUrl = URL(fileURLWithPath: record.localPath, isDirectory: false)
            activityItems = [fileUrl as Any]

        case .video:
            let fileUrl = URL(fileURLWithPath: record.localPath, isDirectory: false)
            activityItems = [fileUrl as Any]
        case .document:
            let fileUrl = URL(fileURLWithPath: record.localPath, isDirectory: false)
            activityItems = [fileUrl as Any]
        default:
            break
        }
        var activityViewControntroller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityViewControntroller.excludedActivityTypes = []
        var sub_msg = "Konverz - Shared File"
        activityViewControntroller.setValue(sub_msg, forKey: "subject")
        activityViewControntroller.setValue("Konverz", forKey: "title")
        if UI_USER_INTERFACE_IDIOM() == .pad {
            activityViewControntroller.popoverPresentationController?.sourceView = view
            activityViewControntroller.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.size.width / 2, y: view.bounds.size.height / 4, width: 0, height: 0)
        }
        
        activityViewControntroller.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
        }
        
        present(activityViewControntroller, animated: true)

        
    }
    
    func imageForStatus(status : CSChatStatus) -> UIImage? {
        
        switch status {
        case .sending:
            return UIImage(named: "sending")
        case .sent:
            return UIImage(named: "sent")
        case .delivered:
            return UIImage(named: "delivered")
        case .displayed:
            return UIImage(named: "displayed")
            
        default:
            break
        }
        
        return nil
        
    }
    
    
    //MARK:  Audio Attachment Methods
    
    @objc func playAudioRecording(_ btn: UIButton) {
        
        if btn.isSelected {
            audioPlayer?.pause()
            btn.isSelected = false
            playButton = nil
        }
        else{
            let buttonPosition = btn.convert(CGPoint.zero, to: dataTableView)
            let indexPath: IndexPath? = dataTableView.indexPathForRow(at: buttonPosition)
            var cell: UITableViewCell? = nil
            let record = (historyRecords[indexPath?.section ?? 0])[indexPath?.row ?? 0]
            if let indexPath = indexPath {
                cell = dataTableView.cellForRow(at: indexPath)
            }
            playerSlider?.value = 0
            playButton?.isSelected = false
            playerSlider = cell?.viewWithTag(108) as? UISlider
            time_duration = cell?.viewWithTag(110) as? UILabel
            playerSlider?.addTarget(self, action: #selector(self.sliderValueChanged(_:)), for: .touchDragInside)
            playerSlider?.tintColor = UIColor.darkGray
            playerSlider?.maximumTrackTintColor = UIColor.darkGray
            
            
            if audioPlayer?.isPlaying ?? false {
                audioPlayer?.stop()
                if recordedData != nil {
                    
                    do{
                        var currentCellData = try Data(contentsOf: URL(fileURLWithPath: record.localPath))
                        if !(recordedData == currentCellData) {
                        } else {
                            btn.isSelected = false
                            return
                        }
                    }
                    catch{
                        
                    }
                    playButton = btn
                    audioPlayer?.play()
                    btn.isSelected = true
                }
            }
            else{
                
                if recordedData != nil {
                    do{
                        var currentCellData = try Data(contentsOf: URL(fileURLWithPath: record.localPath))
                        if !(recordedData == currentCellData) {
                            audioPlayer?.stop()
                            btn.isSelected = false
                        } else {
                            playButton = btn
                            audioPlayer?.play()
                            btn.isSelected = true
                            playingRow = indexPath?.row ?? 0
                            dataTableView.reloadData()
                            return
                        }
                    }
                    catch{
                        
                    }
                }
            }
            
            playButton = btn
            btn.isSelected = true
            
            do {
                
                try AVAudioSession.sharedInstance().setCategory(.playback, options: .defaultToSpeaker)
                
            } catch {
            }
            var parseArray = record.localPath.components(separatedBy: ".")
            if (parseArray.last == "aac") || (parseArray.last == "mp3") || (parseArray.last == "m4a") {
                // Audio implemetation
                do{
                    recordedData = try Data(contentsOf: URL(fileURLWithPath: record.localPath))
                }
                catch{
                    
                }
            }
            
            var error: Error?
            do {
                if let recordedDataTemp = recordedData{
                    audioPlayer = try AVAudioPlayer(data: recordedDataTemp)
                }
                
            } catch {
            }
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            playerSlider?.maximumValue = Float(audioPlayer?.duration ?? 0)
            playerSlider?.value = Float(audioPlayer?.currentTime ?? 0)
            time_duration.text = "recording... 00:00" //@"00:00";
            timer = Timer.scheduledTimer(timeInterval: 0.0, target: self, selector: #selector(self.updateTime(_:)), userInfo: nil, repeats: true)
            
            audioPlayer?.play()
            playingRow = indexPath?.row ?? 0
            dataTableView.reloadData()
            
            
            
        }
        
    }
    
    @objc func updateTime(_ timer: Timer?) {
        
        playerSlider?.value = Float(audioPlayer?.currentTime ?? 0)
        let currentTime: CMTime = CMTimeMake(value: Int64(audioPlayer?.currentTime ?? 0), timescale: 1)
        let avplayerCurrentTime = CMTimeGetSeconds(currentTime)
        let elapsed = formatTimeString(avplayerCurrentTime, asNegative: false)
        
        time_duration.text = !(elapsed == "00:00") ? elapsed : "00:00"
        
        if audioPlayer?.duration == audioPlayer?.currentTime {
            
            playerSlider?.value = 0
            
            self.timer?.invalidate()
        }
    }
    
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        print("slider value = \(sender.value)")
        let buttonPosition = sender.convert(CGPoint.zero, to: dataTableView)
        let indexPath: IndexPath? = dataTableView.indexPathForRow(at: buttonPosition)
        if playingRow == Int(indexPath?.row ?? 0) {
            if recordedData != nil {
                audioPlayer?.currentTime = TimeInterval(sender.value)
            }
        }
    }
    
    func formatTimeString(_ s: TimeInterval, asNegative negative: Bool) -> String? {
        
        var seconds = Int(s)
        let hours: Int = seconds / 3600
        seconds -= hours * 3600
        let mins: Int = seconds / 60
        seconds -= mins * 60
        
        let sign = negative ? "" : ""
        if hours > 0 {
            return String(format: "%@%i:%02d:%02d", sign, hours, mins, seconds)
        } else {
            return String(format: "%@%02d:%02d", sign, mins, seconds)
        }
    }
    
    
    
    
    
    
    
    
    //MARK:- Load History........
    
    func loadHistory(showUnreadSeparator : Bool){
        
        var records : NSMutableArray? = []
        var historyRecordsTemp = [CSHistory]()
        historyRecords = [[CSHistory]]()
        
        var showunreadseparator : Bool? = showUnreadSeparator
        
        self.dbManager?.getChatHistoryRecords(&records, forNumber: self.remoteNumber, withRecordLimit: UInt(self.recordLimit))
        unreadIndexPath = nil
        
        if let array : [CSHistory] = records as? [CSHistory]{
            historyRecordsTemp = array
        }
        var previousDateComponents : DateComponents? = nil
        var section = [CSHistory]()
        
        for record in historyRecordsTemp {
            
            var currentDateComponents: DateComponents = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute, .second], from: record.startTime)
            
            if showunreadseparator == true && record.direction == 1 && record.status == CSChatStatus.receiving.rawValue || record.status == CSChatStatus.received.rawValue{
                
                let infoRecord = CSHistory()
                infoRecord.recordType = .info
                infoRecord.data = "Unread Messages"
                section.append(infoRecord)
                showunreadseparator = false
                self.unreadIndexPath = IndexPath(row: section.count-1, section: historyRecords.count)
            }
            
            if previousDateComponents == nil{
                sectionHeaders.append(record.startTime)
            }
            else if previousDateComponents?.day == currentDateComponents.day{
                
            }
            else{
                historyRecords.append(section)
                section = [CSHistory]()
                sectionHeaders.append(record.startTime)
            }
            
            previousDateComponents = currentDateComponents
            section.append(record)
            
            if record.direction == 1 && (record.status == CSChatStatus.received.rawValue || record.status == CSChatStatus.receiving.rawValue) {
                DispatchQueue.main.async(execute: {
                    self.chatSession?.sendReadReceipt(record.messageID)
                })
            }
        }
        
        if  section.count != 0 {
            historyRecords.append(section)
        }
    }
    
    //MARK: ----- Keyboard handling.....
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func handleKeyboardFrameWillChange(notification: NSNotification) {
        
        let keyboardEndFrame: CGRect? = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        
        let animationCurve = UIView.AnimationCurve(rawValue: (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as AnyObject).intValue ?? 0)
        let animationDuration = TimeInterval((notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.intValue ?? 0)
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(animationDuration)
        if let animationCurve = animationCurve {
            UIView.setAnimationCurve(animationCurve)
        }
        if #available(iOS 11.0, *) {
            editViewBottomLayoutConstraint.constant = (keyboardEndFrame?.size.height ?? 0.0) - view.safeAreaInsets.bottom
        } else {
            editViewBottomLayoutConstraint.constant = (keyboardEndFrame?.size.height)!
        }
        
        // Scroll the Tbale
        
        if historyRecords.count > 0 {
            if let unreadindex = unreadIndexPath{
                
                dataTableView.scrollToRow(at: unreadindex, at: .top, animated: true)
            }
            else{
                let section  = historyRecords.count - 1
                var indexPath : IndexPath!
                indexPath = IndexPath(row: historyRecords[section].count-1, section: section)
                dataTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
        
        UIView.commitAnimations()
        
    }
    
    @objc func handleKeyboardFrameWillHide(notification: NSNotification) {
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.25)
        UIView.setAnimationCurve(.easeInOut)
        
        editViewBottomLayoutConstraint.constant = 0
        
        view.layoutIfNeeded()
        
        // Scroll the Tbale
        
        if historyRecords.count > 0 {
            if let unreadindex = unreadIndexPath{
                
                dataTableView.scrollToRow(at: unreadindex, at: .top, animated: true)
            }
            else{
                let section  = historyRecords.count - 1
                var indexPath : IndexPath!
                indexPath = IndexPath(row: historyRecords[section].count-1, section: section)
                dataTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
        UIView.commitAnimations()
        
    }
    
    func scrollToCaret(in textView: UITextView?, animated: Bool) {
        
        var rect: CGRect? = nil
        if let end = textView?.selectedTextRange?.end {
            rect = textView?.caretRect(for: end)
        }
        rect?.size.height += textView?.textContainerInset.bottom ?? 0.0
        textView?.scrollRectToVisible(rect ?? CGRect.zero, animated: animated)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        let newSize = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat(MAXFLOAT)))
        
        if ceilf(Float(newSize.height)) == Float(textView.frame.size.height) {
            return
        }
        if newSize.height > 199 {
            
            if textView.isScrollEnabled {
                print("Scroll enabled")
            } else {
                print("Scroll disabled")
            }
            
            textView.isScrollEnabled = true
            textView.scrollRangeToVisible(textView.selectedRange)
            view.layoutIfNeeded()
        } else {
            
            textView.isScrollEnabled = false
            
            UIView.animate(withDuration: 0.1, animations: {
                
                self.editViewHeightConstraint.constant = CGFloat(ceilf(Float(newSize.height)) + 17)
                self.view.layoutIfNeeded()
            }) { finished in
                
                if newSize.height == 199 {
                    
                    UIView.animate(withDuration: 0.1, animations: {
                        
                        textView.isScrollEnabled = true
                        self.view.layoutIfNeeded()
                    })
                }
            }
        }
    }
    
   
    func textViewDidChangeSelection(_ textView: UITextView) {
        textView.layoutIfNeeded()
        var caretRect: CGRect? = nil
        if let end = textView.selectedTextRange?.end {
            caretRect = textView.caretRect(for: end)
        }
        print("y \(caretRect?.origin.y ?? 0.0)")
        caretRect?.size.height += textView.textContainerInset.bottom
        textView.scrollRectToVisible(caretRect ?? CGRect.zero, animated: false)
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if self.chatTextView.text != nil {
            sendButton.setImage(UIImage(named: "send"), for: .normal)
        }
        else{
            sendButton.setImage(UIImage(named: "audio"), for: .normal)
            
        }
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if textView.text.elementsEqual(ChatViewController.ktypeMsgStr) {
            textView.text = ""
        }
        textView.becomeFirstResponder()
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        
        if textView.text.elementsEqual("") {
            chatTextView.textColor = .lightGray
        }
        sendButton.setImage(UIImage(named: "audio"), for: .normal)
        textView.resignFirstResponder()
    }
    
    
    //MARK:  ----- notification handling
    
    func refreshLastSeenLabel() {
        
        if onlineStatus == true{
            lastSeenLabel.text = "online"
            return
        }
        
        if lastSeenDate == nil {
            lastSeenLabel.text = ""
            return
        }
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.doesRelativeDateFormatting = true
        dateFormatter.locale = NSLocale.current
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .short
        
        let timestamp = dateFormatter.string(from: lastSeenDate ?? Date())
        
        if (timestamp == "Today") {
            
            let seconds = Int(Date().timeIntervalSince(lastSeenDate ?? Date()))
            
            if seconds < 60 {
                lastSeenLabel.text = "Last seen few seconds ago"
            } else if seconds < 3600 {
                
                if seconds >= 60 && seconds < 120 {
                    lastSeenLabel.text = "Last seen a minute ago"
                } else {
                    lastSeenLabel.text = String(format: "Last seen %zd minutes ago", seconds / 60)
                }
            } else if seconds < 9000 {
                
                if seconds >= 3600 && seconds < 7200 {
                    lastSeenLabel.text = "Last seen an hour ago"
                } else {
                    lastSeenLabel.text = String(format: "Last seen %zd hours ago", seconds / 3600)
                }
            } else {
                dateFormatter.dateStyle = .none
                dateFormatter.timeStyle = .short
                lastSeenLabel.text = "Last seen at \(dateFormatter.string(from: lastSeenDate ?? Date()))"
            }
        }
        if (timestamp == "Yesterday") {
            lastSeenLabel.text = "Last seen Yesterday"
        } else {
            lastSeenLabel.text = "Last seen on \(timestamp)"
        }
        
    }
    
    @objc func handleChatNotification(notification : NSNotification){
        if notification.name.rawValue.elementsEqual("ChatNotification") {
            refreshHistoryInfo()
        }
    }
    @objc func handleDeliveryNotification(notification : NSNotification){
        if notification.name.rawValue.elementsEqual("ChatDeliveryNotification") {
            refreshHistoryInfo()
        }
    }
    @objc func handlePresenceNotification(notification : NSNotification){
        
        //TBD check if current chat
        if (notification.name.rawValue == "PresenceNotification") {
            
            let presenceResponse = notification.userInfo
            
            if let dict_presenceResponse = presenceResponse{
                if let number = dict_presenceResponse[kARRemoteNumber] as? String{
                    if number.elementsEqual(self.remoteNumber){
                        return
                    }
                }
                if let lastseendateTemp = dict_presenceResponse[kARTimestamp] as? Date{
                    lastSeenDate = lastseendateTemp
                }
                if let presenceStatus = dict_presenceResponse[kARPresenceStatus] as? String{
                    if presenceStatus.elementsEqual("ONLINE"){
                        lastSeenLabel.text = "online"
                        onlineStatus = true
                    }
                    else{
                        onlineStatus = false
                        refreshLastSeenLabel()
                    }
                }
            }
        }
    }
    @objc func handleDownloadNotification(notification : NSNotification){
        if notification.name.rawValue.elementsEqual("DownloadNotification") {
            refreshHistoryInfo()
        }
    }
    @objc func handleProgressNotification(notification : NSNotification){
        if notification.name.rawValue.elementsEqual("FTProgressNotification") {
            refreshHistoryInfo()
        }
    }
    @objc func handleThumbnailDownloadNotification(notification : NSNotification){
        if notification.name.rawValue.elementsEqual("ThumbnailDownloadNotification") {
            refreshHistoryInfo()
        }
    }
    @objc func handleAppEnterBackground(notification : NSNotification){
        
    }
    @objc func handleAppEnterForeground(notification : NSNotification){
         NotificationCenter.default.addObserver(self, selector: #selector(handleChatNotification(notification:)), name: NSNotification.Name("ChatNotification"), object: nil)
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

extension AVAsset {
    
    func generateThumbnail(completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global().async {
            let imageGenerator = AVAssetImageGenerator(asset: self)
            let time = CMTime(seconds: 0.0, preferredTimescale: 600)
            let times = [NSValue(time: time)]
            imageGenerator.generateCGImagesAsynchronously(forTimes: times, completionHandler: { _, image, _, _, _ in
                if let image = image {
                    completion(UIImage(cgImage: image))
                } else {
                    completion(nil)
                }
            })
        }
    }
}
