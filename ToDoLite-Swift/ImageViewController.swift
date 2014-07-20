//
//  ImageViewController.swift
//  ToDoLite-Swift
//
//  Created by Mark Tracy on 7/18/14.
//  Copyright (c) 2014 Mark Tracy Special Engineering. All rights reserved.
//
//  Ported from CouchbaseLite demo app ToDoLite for iOS
//  ImageViewController.h and ImageViewController.m
//  Created by Pasin Suriyentrakorn on 4/8/14.
//  Copyright (c) 2014 Chris Anderson. All rights reserved.

import UIKit

class ImageViewController: UIViewController {

    @IBOutlet var imageView: UIImageView
    var image: UIImage? {
    didSet {
        self.imageView.image = self.image
    }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "handleTap:"))
        imageView.image = self.image
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // gesture handler
    func handleTap(recognizer: UIGestureRecognizer) {
        dismissViewControllerAnimated(false, completion: nil )
    }
    
    /*
    // #pragma mark - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func closeButtonAction(sender: UIBarButtonItem) {
    }

}
