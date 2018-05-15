//
//  MessageCell.swift
//  Ripple Go
//
//  Created by Dennis Kwok on 14/5/18.
//  Copyright © 2018 Dennis Kwok. All rights reserved.
//

import Foundation
import UIKit

class MessageCell: UITableViewCell {
    
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var messages: UILabel!
    @IBOutlet weak var saveBtn: UIButton!
    
    var index:Int!
    var saved:Bool! = false
    
    var messageCellDelegate:MessageCellDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()
        
}
    
    @IBAction func saveBtnTapped(_ sender: Any) {
        messageCellDelegate?.didPressButton(index,saved: saved)
    }
    
    
    
}

protocol MessageCellDelegate : class {
    func didPressButton(_ tag: Int, saved:Bool)
}
