//
//  ChatDetailCell.swift
//  ChatSample
//
//  Created by Murali Sai Tummala on 07/05/19.
//  Copyright © 2019 Voxvalley technologies. All rights reserved.
//

import UIKit


@objc protocol ChatDetailCellDelegate : NSObjectProtocol {
   @objc func tableCellSelected(tableCell : ChatDetailCell)

}

class ChatDetailCell: UITableViewCell {
    
     var cellDelegate: ChatDetailCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if((self.cellDelegate) != nil)
        {
            cellDelegate?.tableCellSelected(tableCell: self);
        }
        // Configure the view for the selected state
    }
    func canBecomeFirstResponder() -> Bool {
        return true
    }
    /*
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        return action == #selector(self.copy(_:))  || action == #selector(self.forwardMenuAction(_:)) || action == #selector(self.deleteMenuAction(_:)) || action == #selector(self.shareMenuAction(_:))

    }
    
   
    
   @IBAction @objc  func forwardMenuAction(_ sender: Any) {
        
        guard   ((cellDelegate?.didTapMenuAction("Forward", withObject: sender)) != nil)
             else {
                return
        }
      
    
    }
    @IBAction @objc func  deleteMenuAction(_ sender : Any) {
        
        
    }
   @IBAction @objc func shareMenuAction(_ sender : Any) {
        
        
    }
   @IBAction @objc func copy(sender : Any) {
        guard   ((cellDelegate?.didTapMenuAction("Copy", withObject: sender)) != nil)
            else {
                return
        }
    }
    */
    /*
   
     /// this methods will be called for the cell menu items
     //-(IBAction) infoMenuAction: (id) sender {
     //
     //}
     
     -(IBAction) forwardMenuAction: (id) sender {
     if(self.cellDelegate && [self.cellDelegate respondsToSelector:@selector(didTapMenuAction:withObject:)])
     {
     [self.cellDelegate didTapMenuAction:@"Forward" withObject:sender];
     }
     }
     
     -(IBAction) deleteMenuAction: (id) sender {
     if(self.cellDelegate && [self.cellDelegate respondsToSelector:@selector(didTapMenuAction:withObject:)])
     {
     [self.cellDelegate didTapMenuAction:@"Delete" withObject:sender];
     }
     }
     -(IBAction)shareMenuAction:(id)sender {
     if(self.cellDelegate && [self.cellDelegate respondsToSelector:@selector(didTapMenuAction:withObject:)])
     {
     [self.cellDelegate didTapMenuAction:@"Share" withObject:sender];
     }
     }
     
     -(IBAction) copy:(id)sender {
     if(self.cellDelegate && [self.cellDelegate respondsToSelector:@selector(didTapMenuAction:withObject:)])
     {
     [self.cellDelegate didTapMenuAction:@"Copy" withObject:sender];
     }
     }

 
 */

}
