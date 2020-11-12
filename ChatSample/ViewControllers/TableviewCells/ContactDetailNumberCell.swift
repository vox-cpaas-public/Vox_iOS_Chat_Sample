//
//  ContactDetailNumberCell.swift
//  ChatSample
//
//  Created by Murali Sai Tummala on 03/05/19.
//  Copyright © 2019 Voxvalley technologies. All rights reserved.
//

import UIKit

class ContactDetailNumberCell: UITableViewCell {

    
    
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var number: UILabel!
    @IBOutlet weak var chatButton: UIButton!
    
    
    @IBAction func chatButtonAction(_ sender: UIButton) {
        
        
        
        
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
