//
//  AppDelegate.swift
//  ToDoLite-Swift
//
//  Created by Mark Tracy on 7/8/14.
//  Copyright (c) 2014 Mark Tracy Special Engineering. All rights reserved.
//
//  Ported from CouchbaseLite demo app ToDoLite for iOS
//  AppDelegate.h and AppDelegate.m
//  Created by Chris Anderson on 11/14/13.
//  Copyright (c) 2013 Chris Anderson. All rights reserved.

import UIKit

let kSyncUrl = "sync.couchbasecloud.com:4984/todos4"
// let kSyncUrl = "http://localhost:4985/todos"
let kFBAppId = "501518809925546"

@UIApplicationMain
@objc class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?
    var database: CBLDatabase!
    var cblSync: CBLSyncManager!


    func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {
        // Override point for customization after application launch.
        let splitViewController = self.window!.rootViewController as UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as UINavigationController
        splitViewController.delegate = navigationController.topViewController as DetailViewController
        
        // CouchbaseLite setup
        let manager = CBLManager.sharedInstance()
        var error: NSError?
        database = manager.databaseNamed("todos", error: &error)
        if !database {
            println("Failed to get a database: \(error ? error!.localizedDescription : nil)")
            exit(-1)
        }
        
        database.modelFactory?.registerClass(List.self, forDocumentType: "list")
        database.modelFactory?.registerClass(Task.self, forDocumentType: "item")
        
        setupCBLSync()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication!) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication!) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication!) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication!) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication!) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // #pragma mark - Sync
    
    func updateMyLists(userID: String, userData: Dictionary<String, AnyObject>, outError: NSErrorPointer?) {
        let name: AnyObject? = userData["name"]
        //let myProfile = Profile(inDatabase: database, name: name as String, userID: userID)
        let myProfile = Profile(currentUserProfileInDatabase: database, withName: name as String, andUserID: userID)
        //var error = List.updateAllListsInDatabase(database, withOwner: myProfile)
        var error: NSError?
        List.updateAllListsInDatabase(database, withOwner: myProfile, error: outError!)
        let success = myProfile.save(&error)
        if success == false {
            NSLog("Error while updating lists: \(outError?.memory?.localizedDescription)")
        }
    }
    
    func setupCBLSync() {
        cblSync = CBLSyncManager(forDatabase: database, withURL: NSURL(string: kSyncUrl))
        
        // We are using Facebook login for the demo
        cblSync.authenticator = CBLFacebookAuthenticator(appID: kFBAppId)
        
        if cblSync.userID { // we are already logged in so sync up
            cblSync.start()
        } else {
            cblSync.beforeFirstSync({userID, userData, outError in
                let updateMe: () -> () = {
                    self.updateMyLists(userID, userData: userData, outError: outError)
                }
                let blockOp: NSBlockOperation = NSBlockOperation(updateMe)
                NSOperationQueue.mainQueue().addOperations([blockOp], waitUntilFinished: true)
                })
        }
    }
    
    func loginAndSync(complete: () -> Void) {
        assert(cblSync, "setupCBLSync() must succeed first")
        if cblSync.userID {
            complete()  // we are good to go
        } else {  // queue it for later
            cblSync.beforeFirstSync({ userID, userData, outError in
                complete()
                })
            cblSync.start()
        }
    }
}

