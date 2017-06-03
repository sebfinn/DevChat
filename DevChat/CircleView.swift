//
//  CircleView.swift
//  DevChat
//
//  Created by Sebastian DiPirro on 5/29/17.
//  Copyright © 2017 Sebastian DiPirro. All rights reserved.
//

import UIKit

class CircleView: UIImageView {

    override func layoutSubviews() {
        layer.cornerRadius = self.frame.width / 2
        clipsToBounds = true
            
    }
}



