//
//  HistoryCell.swift
//  ChatSample
//
//  Created by Murali Sai Tummala on 06/05/19.
//  Copyright © 2019 Voxvalley technologies. All rights reserved.
//

import UIKit

class HistoryCell: UITableViewCell {

    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var contactName: UILabel!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var contactImage: UIImageView!
    @IBOutlet weak var defaultContact: UIImageView!
    @IBOutlet weak var unreadCount: UILabel!

    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
