//
//  DetailViewController.swift
//  ToDoLite-Swift
//
//  Created by Mark Tracy on 7/8/14.
//  Copyright (c) 2014 Mark Tracy Special Engineering. All rights reserved.
//
//  Ported from CouchbaseLite demo app ToDoLite for iOS
//  DetailViewController.h and DetailViewController.m
//  Created by Chris Anderson on 11/14/13.
//  Copyright (c) 2013 Chris Anderson. All rights reserved.

import UIKit

let ImageDataContentType = "image/jpg"

class DetailViewController: UIViewController,
    UISplitViewControllerDelegate,
    UITableViewDelegate,
    UITextFieldDelegate,
    CBLUITableDelegate,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    TaskTableViewCellDelegate,
    UIScrollViewDelegate,
    UIActionSheetDelegate {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dataSource: CBLUITableSource!
    @IBOutlet weak var addItemTextField: UITextField!
    @IBOutlet weak var addImageButton: UIButton!
    var masterPopoverController: UIPopoverController? = nil
    
    var app: AppDelegate!
    var taskToAddImageTo: Task?
    var imageForNewTask: UIImage?
    var imagePickerPopover: UIPopoverController?

    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()

            if self.masterPopoverController != nil {
                self.masterPopoverController!.dismissPopoverAnimated(true)
            }
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let detail: AnyObject = self.detailItem {
            if let label = self.detailDescriptionLabel {
                label.text = detail.description
            }
            
            title = detail.title
            assert(addItemTextField != nil, "addItemTextField cannot be nil")
            addItemTextField.enabled = true
            addImageButton.enabled = true
            
            navigationItem.rightBarButtonItem!.title = "Share"
            
            assert(dataSource != nil, "detail.dataSource not connected")
            dataSource!.labelProperty = "title"
            dataSource!.query = detail.queryTasks().asLiveQuery()
        } else {
            title = nil
            addImageButton.enabled = false
            addItemTextField.enabled = false
        }
    }
    
    // customize table view cell
    func couchTableSource(source: CBLUITableSource, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "Task"
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? TaskTableViewCell
        if !(cell != nil) {
            cell = TaskTableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: cellIdentifier)
        }
        assert(cell != nil, "Can't make a TaskTableCell")
        
        let row = source.rowAtIndex(UInt(indexPath.row))
        let newTask = Task(forDocument: row!.document!)
        cell!.task = newTask
        cell!.delegate = self
        
        // For some reason, this needed to be made explicit
        // the original did this implicitly
        if newTask.checked {
            cell!.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else {
            cell!.accessoryType = UITableViewCellAccessoryType.None
        }
        
        return cell!
    }

    override func viewDidLoad() {
        app = UIApplication.sharedApplication().delegate as? AppDelegate
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: navigation
    @IBAction func shareButtonAction(sender: AnyObject?) {
        app.loginAndSync({
            self.performSegueWithIdentifier("setupSharing", sender: self)
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "setupSharing" {
            var svc = segue.destinationViewController as! ShareViewController
            svc.list = detailItem as? List
        }
    }

    //MARK: Split view

    func splitViewController(splitController: UISplitViewController, willHideViewController viewController: UIViewController, withBarButtonItem barButtonItem: UIBarButtonItem, forPopoverController popoverController: UIPopoverController) {
        barButtonItem.title = NSLocalizedString("To-do Lists", comment:"To-do Lists")
        self.navigationItem.setLeftBarButtonItem(barButtonItem, animated: true)
        self.masterPopoverController = popoverController
    }

    func splitViewController(splitController: UISplitViewController, willShowViewController viewController: UIViewController, invalidatingBarButtonItem barButtonItem: UIBarButtonItem) {
        // Called when the view is shown again in the split view, invalidating the button and popover controller.
        self.navigationItem.setLeftBarButtonItem(nil, animated: true)
        self.masterPopoverController = nil
    }
    func splitViewController(splitController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return true
    }
    
    //MARK: Add item
    
    
    // called when an item is selected. Toggles the checkmark
    func tableView(UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) -> Void {
        let row = dataSource.rowAtIndex(UInt(indexPath.row))
        var task = Task(forDocument: row!.document!)
        let checked = task.checked
        task.checked = !checked
        var error: NSError?
        if !task.save(&error) {
            println("Error saving checked")
            // error alert
        }
    }
    
    // text field delegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let title = addItemTextField.text
        if title.isEmpty {
            return false
        }
        addItemTextField.text = nil
        assert(detailItem != nil, "must have a list before adding to it")
        
        // Is a picture ready and waiting?
        var image: NSData? = (imageForNewTask != nil) ? dataForImage(imageForNewTask!) : nil

        let list = detailItem as? List
        let task = list?.addTaskWithTitle(title, withImage: image, withImageContentType: ImageDataContentType)
        var error: NSError?
        if (task?.save(&error) != nil) {
            imageForNewTask = nil  // clean up
            updateAddImageButton(nil)
        } else {
            // error alert
            println("failed to add task")
        }
        
        return true
    }
    
    //MARK: taking a picture
    func hasCamera() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)
    }
    
    func displayAddImageActionSheetFor(sender: UIView, forTask task: Task?) {
        taskToAddImageTo = task
        var actionSheet = UIActionSheet()
        
        if hasCamera() {
            actionSheet.addButtonWithTitle("Take Photo")
        }
        actionSheet.addButtonWithTitle("Choose Existing")
        if (imageForNewTask != nil) {
            actionSheet.addButtonWithTitle("Delete")
        }
        actionSheet.addButtonWithTitle("Cancel")
        
        actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1
        actionSheet.delegate = self
        actionSheet.showFromRect(sender.frame, inView: sender.superview, animated: true)
    }
    
    func dataForImage(image: UIImage) -> NSData {
        return UIImageJPEGRepresentation(image, 0.5)
    }
    
    func displayImagePickerForSourceType(sourceType: UIImagePickerControllerSourceType) {
        var picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = true
        picker.delegate = self
        
        imagePickerPopover = nil
        
        let isPad = (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad)
        if isPad && sourceType == UIImagePickerControllerSourceType.PhotoLibrary {
            imagePickerPopover = UIPopoverController(contentViewController: picker)
            imagePickerPopover?.presentPopoverFromRect(self.view.bounds, inView: self.view, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
        } else {
            presentViewController(picker, animated: true, completion: nil )
        }
    }
    
    //MARK: UIActionSheetDelegate
    func actionSheet(actionSheet: UIActionSheet!, clickedButtonAtIndex buttonIndex: Int) {
        // Cancel button
        if buttonIndex == actionSheet.cancelButtonIndex {
            return
        }
        
        // Delete button
        if (imageForNewTask != nil && buttonIndex == actionSheet.cancelButtonIndex - 1) {
            updateAddImageButton(nil )
            imageForNewTask = nil
            return
        }
        
        //
        let sourceType = (hasCamera() && buttonIndex == 0) ? UIImagePickerControllerSourceType.Camera : UIImagePickerControllerSourceType.PhotoLibrary
        displayImagePickerForSourceType(sourceType)
    }
    
    // addImageButton
    func updateAddImageButton(image: UIImage?) {
        if (image != nil) {
            addImageButton.setImage(image, forState: UIControlState.Normal)
        } else {
            addImageButton.setImage(UIImage(named: "Camera"), forState: UIControlState.Normal)
        }
    }
    
    @IBAction func addImageButtonAction(sender: UIButton) {
        displayAddImageActionSheetFor(sender, forTask: nil )
    }
    
    //MARK: TaskTableCellDelegate
    func didSelectImageButton(imageButton: UIButton, ofTask task: Task) {
        let attachment = task.attachmentNamed("image")
        if (attachment != nil) {
            var imageViewController = self.storyboard!.instantiateViewControllerWithIdentifier("ImageVIewController") as! ImageViewController
            imageViewController.image = UIImage(data: attachment!.content!)
            imageViewController.modalPresentationStyle = UIModalPresentationStyle.FullScreen
            presentViewController(imageViewController, animated: false, completion: nil )
        } else {
            displayAddImageActionSheetFor(imageButton, forTask: task)
        }
    }
    
    // UIScrollViewDelegate
    func scrollViewDidScroll(scrollView: UIScrollView!) {
        addItemTextField.resignFirstResponder()
    }
}

