//
//  Constants.swift
//  MyHome
//
//  Created by Richard Seaman on 24/06/2018.
//  Copyright © 2018 RichApps. All rights reserved.
//

import Foundation
import UIKit

let colourDefault = UIColor(red: 0/255, green: 153/255, blue: 204/255, alpha: 1.0)

func returnHeader(_ sender:UIView) -> UITableViewHeaderFooterView {
    
    // Recast the view as a UITableViewHeaderFooterView
    let header: UITableViewHeaderFooterView = sender as! UITableViewHeaderFooterView
    
    // Make the text white
    header.textLabel!.textColor = UIColor.white
    
    // Make the header transparent
    header.alpha = 0.8
    
    // Set the background colour
    header.contentView.backgroundColor = colourDefault
    
    return header
}


func getNavImageView(_ orientationToDisplayImageOn:UIInterfaceOrientation) -> UIImageView {
    
    // The navigation bar is shorter in landscape than portrait.
    // Change the size of the nav bar image so that it stays within the bar.
    
    // for iPad, the same image is used for portrait and landscape
    
    var imageHeight:CGFloat = CGFloat()
    var imageWidth:CGFloat = CGFloat()
    
    switch UIDevice.current.userInterfaceIdiom {
        
    case .phone:
        // It's an iPhone
        if (orientationToDisplayImageOn == UIInterfaceOrientation.portrait) {
            imageHeight = 400/12
            imageWidth = 400/12
        }
        else {
            imageHeight = 400/16
            imageWidth = 400/16
        }
        
    case .pad:
        // It's an iPad
        imageHeight = 400/12
        imageWidth = 400/12
        
    default:
        // Uh, oh! What could it be?
        imageHeight = 400/12
        imageWidth = 400/12
        
    }
    
    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageHeight, height: imageWidth))
    imageView.contentMode = .scaleAspectFit
    let image = UIImage(named: "NavIcon")
    imageView.image = image
    
    if #available(iOS 11.0, *) {
        let widthConstraint = imageView.widthAnchor.constraint(equalToConstant: imageWidth)
        let heightConstraint = imageView.heightAnchor.constraint(equalToConstant: imageHeight)
        heightConstraint.isActive = true
        widthConstraint.isActive = true
    }
    
    return imageView
    
}
