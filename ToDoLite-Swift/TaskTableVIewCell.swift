//
//  TaskTableVIewCell.swift
//  ToDoLite-Swift
//
//  Created by Mark Tracy on 7/18/14.
//  Copyright (c) 2014 Mark Tracy Special Engineering. All rights reserved.
//
//  Ported from CouchbaseLite demo app ToDoLite for iOS
//  TaskTableViewCell.h and TaskTableViewCell.m
//  Created by Pasin Suriyentrakorn on 4/8/14.
//  Copyright (c) 2014 Chris Anderson. All rights reserved.

import Foundation

protocol TaskTableViewCellDelegate {
    func didSelectImageButton(imageButton: UIButton, ofTask task: Task) -> Void
}

class TaskTableViewCell: UITableViewCell {
    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var name: UILabel!
    // As of Swift beta 4, delegates don't work the way I expect
    // There seems to be no way of specifying an arbitrary object conforming to a protocol as an IBOutlet
    // trying to use @IBOutlet or weak with a protocol type is forbidden
    // The docs recomment the type as NSWindowDelegate?, but that is unrecognized in iOS
    @IBOutlet weak var delegate: DetailViewController?
    
    @IBAction func imageButtonAction(sender: AnyObject?) {
        if !task {
            return
        }
        delegate?.didSelectImageButton(sender as UIButton, ofTask: task!)
    }
    
    var task: Task? {
    didSet {
        name.text = task?.title
        let checked = task?.checked
        
        if checked {
            self.accessoryType = UITableViewCellAccessoryType.Checkmark
            name.textColor = UIColor.grayColor()
        } else {
            self.accessoryType = UITableViewCellAccessoryType.None
            name.textColor = UIColor.blackColor()
        }
        
        var attachments = task?.attachmentNames
        if attachments?.count > 0 {
            let attachment: CBLAttachment = attachments![0] as CBLAttachment
            let attachedImage = UIImage(data: attachment.content)
            self.imageButton.setImage(attachedImage, forState: UIControlState.Normal)
        } else {
            self.imageButton.setImage(UIImage(named: "Camera-Light"), forState: UIControlState.Normal)
        }
    }
    }
    // internals
    
    init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    override func awakeFromNib() {
        
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}