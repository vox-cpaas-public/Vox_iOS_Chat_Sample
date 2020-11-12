//
//  ShareContactViewController.swift
//  ChatSample
//
//  Created by Srikanth Reddy on 31/05/19.
//  Copyright © 2019 Voxvalley technologies. All rights reserved.
//

import UIKit

class ShareContactViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var record:CSHistory?
    var contact:NSDictionary?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.tableFooterView = UIView(frame:CGRect.zero)//CGRect.zero
    }
    

    
  //  #pragma mark - TableView Handling
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        else if section == 1 {
            let array = self.contact?["numbers"] as! NSArray
            return array.count
        }else {
           return 1
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        if indexPath.section == 0 {
            guard let cell =  tableView.dequeueReusableCell(withIdentifier: "SharedContactCell") else {
                return UITableViewCell()
            }
            let contactName = cell.contentView.viewWithTag(102) as! UILabel
            
            contactName.text = self.contact?["name"] as? String
           
            return cell
        }else if indexPath.section == 1 {
            guard let cell =  tableView.dequeueReusableCell(withIdentifier: "SharedContactNumberCell") else {
                return UITableViewCell()
            }
            let optionLabel = cell.contentView.viewWithTag(103) as! UILabel
            let numberLbel = cell.contentView.viewWithTag(104) as! UILabel
            let lblArray = self.contact?["labels"] as! NSArray
            
            if(lblArray.count > indexPath.row){
                optionLabel.text = lblArray.firstObject as? String
            }else{
                optionLabel.text = "phone"
            }
           
            let array = self.contact?["numbers"] as! NSArray
            numberLbel.text = array.firstObject as? String
            return cell
            
           
        }else {
            guard let cell =  tableView.dequeueReusableCell(withIdentifier: "SharedContactOptionCell") else {
                return UITableViewCell()
            }
            let optionLabel = cell.contentView.viewWithTag(103) as! UILabel
            optionLabel.text = "Save Contact" //lblArray[indexPath.row] as? String
            return cell
         }
    
      }
        
        

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
   
      return 64.0
        
    }
    
    
    @IBAction func backBtnAction(_ sender: Any) {
        self.navigationController?.popViewController(animated:true)
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
