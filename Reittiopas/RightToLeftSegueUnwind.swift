//
//  RightToLeftSegueUnwind.swift
//  Campfir
//
//  Created by Jesse Sipola on 16.12.2015.
//  Copyright © 2015 Campfir Oy. All rights reserved.
//

import UIKit

class RightToLeftSegueUnwind: UIStoryboardSegue {
    override func perform() {
        // Assign the source and destination views to local variables.
        let window = UIApplication.sharedApplication().keyWindow
        
        let secondVCView = self.sourceViewController.view as UIView!
        let firstVCView = self.destinationViewController.view as UIView!
        
        let screenWidth = UIScreen.mainScreen().bounds.size.width
        let screenHeight = secondVCView.frame.height

        let origin = window?.convertPoint(secondVCView.frame.origin, fromView: secondVCView)
        
        firstVCView.frame = CGRectMake(-screenWidth, origin!.y ?? 0, screenWidth, screenHeight)

        window?.insertSubview(firstVCView, aboveSubview: secondVCView)
        
        // Animate the transition.
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            firstVCView.frame = CGRectOffset(firstVCView.frame, screenWidth, 0.0)
            secondVCView.frame = CGRectOffset(secondVCView.frame, screenWidth, 0.0)
            
            }) { (Finished) -> Void in
                window?.insertSubview(firstVCView, aboveSubview: secondVCView)
                self.sourceViewController.dismissViewControllerAnimated(false, completion: nil)
        }
    }
}
