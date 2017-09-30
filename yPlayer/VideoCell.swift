//
//  VideoCell.swift
//  yPlayer
//
//  Created by SmartNet-MacBookPro on 9/30/17.
//  Copyright © 2017 Manoj. All rights reserved.
//

import UIKit

class VideoCell: UITableViewCell {

    @IBOutlet weak var imgViewThumbnail: UIImageView!
    
    @IBOutlet weak var detailView: UIView!
    
    @IBOutlet weak var imgViewChannel: UIImageView!
    
    @IBOutlet weak var lblVideoTitle: UILabel!
    
    @IBOutlet weak var lblDesc: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
