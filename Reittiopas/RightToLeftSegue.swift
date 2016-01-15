//
//  RightToLeftSegue.swift
//  Campfir
//
//  Created by Jesse Sipola on 16.12.2015.
//  Copyright © 2015 Campfir Oy. All rights reserved.
//

import UIKit

class RightToLeftSegue: UIStoryboardSegue {
    override func perform() {
        // Assign the source and destination views to local variables.
        let firstVCView = self.sourceViewController.view as UIView!
        let secondVCView = self.destinationViewController.view as UIView!
        
        // Get the screen width and height.
        let screenWidth = UIScreen.mainScreen().bounds.size.width
        let screenHeight = firstVCView.frame.height
        
        // Specify the initial position of the destination view.
        secondVCView.frame = CGRectMake(screenWidth, firstVCView.frame.origin.y, screenWidth, screenHeight)
        
        // Access the app's key window and insert the destination view above the current (source) one.
        let window = UIApplication.sharedApplication().keyWindow
        window?.insertSubview(secondVCView, aboveSubview: firstVCView)
        
        // Animate the transition.
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            secondVCView.frame = CGRectOffset(secondVCView.frame, -screenWidth, 0.0)
            
            }) { (Finished) -> Void in
                self.sourceViewController.presentViewController(self.destinationViewController as UIViewController,
                    animated: false,
                    completion: nil)
        }
        
    }
}
