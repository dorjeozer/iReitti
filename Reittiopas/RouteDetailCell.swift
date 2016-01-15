//
//  RouteDetailCell.swift
//  iReitti
//
//  Created by Jesse Sipola on 12.1.2016.
//  Copyright © 2016 Jesse Sipola. All rights reserved.
//

import UIKit

class RouteDetailCell: UITableViewCell {

    @IBOutlet weak var departureLabel: UILabel!
    @IBOutlet weak var travelLabel: UILabel!
    @IBOutlet weak var arrivalLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
