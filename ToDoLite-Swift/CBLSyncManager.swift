//
//  CBLSyncManager.swift
//  ToDoLite-Swift
//
//  Created by Mark Tracy on 7/8/14.
//  Copyright (c) 2014 Mark Tracy Special Engineering. All rights reserved.
//
//  Ported from CouchbaseLite demo app ToDoLite for iOS
//  CBLSyncManager.h and CBLSyncManager.m
//  Created by Chris Anderson on 11/16/13.
//  Copyright (c) 2013 Chris Anderson. All rights reserved.


import Foundation

let kCBLPrefKeyUserID = "CBLFBUserID"

@objc class CBLSyncManager: NSObject {
    
    var database: CBLDatabase
    var remoteURL: NSURL
    var userID: String?
    
    var pull: CBLReplication?
    var push: CBLReplication?
    var beforeSyncBlocks: Array<(userID: String, userData: Dictionary<String, AnyObject>, outError: NSErrorPointer?) -> Void>
    var onSyncStartedBlocks: Array<() -> Void>
    var lastAuthError: NSError?
    
    var authenticator: CBLSyncAuthenticator? {
    didSet {
        if var auth = self.authenticator? {
            auth.syncManager = self
        }
        if self.lastAuthError {
            self.runAuthenticator()
        }
    }
    }
    
    init(forDatabase: CBLDatabase, withURL remoteURL: NSURL, asUser userID: String?){
        self.database = forDatabase
        self.remoteURL = remoteURL
        self.userID = userID
        self.beforeSyncBlocks = []
        self.onSyncStartedBlocks = []
        super.init()
    }
    
    convenience init(forDatabase: CBLDatabase, withURL remoteURL: NSURL) {
        let defaultID: String? = NSUserDefaults.standardUserDefaults().objectForKey(kCBLPrefKeyUserID) as? String
        self.init(forDatabase: forDatabase, withURL: remoteURL, asUser: defaultID)
    }
    
    convenience init(syncForDatabase database: CBLDatabase, withURL remoteURL: NSURL) {
        let defaultID: String? = NSUserDefaults.standardUserDefaults().objectForKey(kCBLPrefKeyUserID) as? String
        self.init(forDatabase: database, withURL: remoteURL, asUser: defaultID)
    }
    
    // New user
    
    func setupNewUser(complete: () -> ()) {
        assert(self.userID == nil, "userID already exists")
        authenticator?.getCredentials({ userID, userData in
            println("Retrieved userID from authenticator: \(userID)")
            if self.userID {  // already set up this userID
                return
            }
            self.userID = userID
            // do the setup callbacks
            let error: NSError? = self.runBeforeSyncStartWithUserID(userID!, userData: userData!)
            if error {
                // handle it
            } else {
                complete()
            }
        })
    }
    
    func runBeforeSyncStartWithUserID(userID: String, userData: Dictionary<String, AnyObject>) -> NSError? {
        var block: (userID: String, userData: Dictionary<String, AnyObject>, outError: NSErrorPointer?) -> Void?
        var error: NSError?
        for block in beforeSyncBlocks {
            if error {
                return error
            }
            block(userID: userID, userData: userData, outError: &error)
        }
        return error
    }
    
    // public interface API
    
    func start() {
        if !userID {
            setupNewUser({ self.launchSync() })
        } else {
            launchSync()
        }
    }
    
    func beforeFirstSync(block: (userID: String, userData: Dictionary<String, AnyObject>, outError: NSErrorPointer?) -> Void) {
        beforeSyncBlocks.append(block)
    }
    
    func onSyncConnected(block: () -> Void) {
        onSyncStartedBlocks.append(block)
    }
    
    
    func launchSync() {
        defineSync()
        
        if lastAuthError {  // this could be set by defineSync()
            //assert(authenticator, "Authenticator not defined")
            runAuthenticator()
        } else {
            restartSync()
        }
    }
    
    func runAuthenticator() {
        authenticator?.getCredentials({ newUserID, userData in
            assert(newUserID? == self.userID, "Changing userID is forbidden")
            self.restartSync()
            })
    }
    
    func defineSync() {
        var replications: Array<CBLReplication> = []
        
        pull = database.createPullReplication(remoteURL)
        if pull {
            pull!.continuous = true
            listenForReplicationEvents(pull!)
            replications.append(pull!)
        }
        
        push = database.createPushReplication(remoteURL)
        if push {
            push!.continuous = true
            listenForReplicationEvents(push!)
            replications.append(push!)
        }
        
        authenticator?.registerCredentialsWithReplications(replications)
    }
    
    //MARK: Progress monitoring
    
    func listenForReplicationEvents(repl: CBLReplication) {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "replicationProgress:",
            name: kCBLReplicationChangeNotification,
            object: repl)
    }
    
    // we watch these variables in the notification handler
    var _active: Bool = false
    var _completed = UInt32(0)
    var _total = UInt32(0)
    var _status = CBLReplicationStatus.Stopped
    var _error: NSError?
    
    var progress = 0.0
    
    func replicationProgress(nCenter: NSNotificationCenter) {
        // N.B. CBLReplicationStatus in CBLReplication.h needed to be changed
        // for Swift compatibility:
        //   Use the NS_ENUM(NSInteger, CBLReplicationStatus) macro so Swift imports it
        //   Explicitly assign kCBLReplicationStopped = 0 to permit numerical comparisons
        // Having done those, remember Swift name-mangles C-enums, and it is
        // more clever than you expect.
        // All in all, rather too much work.
        
        // local versions of state
        var active: Bool = false
        var completed = UInt32(0)
        var total = UInt32(0)
        var status = CBLReplicationStatus.Stopped
        var error: NSError?
        
        for repl in [pull, push] {
            let maxStatus = max(status.toRaw(), repl!.status.toRaw())
            status = CBLReplicationStatus.fromRaw(maxStatus)!
            
            if !error {
                error = repl!.lastError
            }
            if repl!.status == .Active {
                active = true
                completed += repl!.completedChangesCount
                total += repl!.changesCount
            }
        }
        
        // did we have an error?
        if error != _error && error?.code == 401 {
            // need (re-)authentication
            if !authenticator {
                // try again after sync has triggered
                lastAuthError = error
                return
            } else {
                runAuthenticator()
            }
        }
        
        // update the global state and notify the progress bar
        if active != _active || completed != _completed || total != _total || status != _status || error != _error {
            _active = active
            _completed = completed
            _total = total
            _status = status
            _error = error
            progress = Double(completed) / Double(max(1, total))
            
            // At this point, the original demo code stopped with an incomplete implementation
            // Should implement the progress bar whenever a sync is happening
        }
        
    }
    
    func restartSync() {
        println("Restarting sync")
        pull?.stop()
        pull?.start()
        push?.stop()
        push?.start()
    }
    
}

protocol CBLSyncAuthenticator {
    // Since SBLSyncManager has an authenticator, we need this weak
    weak var syncManager: CBLSyncManager! {get set}
    func getCredentials(complete: (userID: String?, userData: Dictionary<String, AnyObject>?) -> ())
    func registerCredentialsWithReplications(repls: Array<CBLReplication>)
}


class CBLFacebookAuthenticator: NSObject, CBLSyncAuthenticator {
    weak var syncManager: CBLSyncManager!
    var facebookAppID: String
    
    init(appID: String){
        self.facebookAppID = appID
        super.init()
    }
    
    func getCredentials(complete: (userID: String?, userData: Dictionary<String, AnyObject>?) -> ()) {
        getFacebookAccessToken({accessToken, fbAccount in
            self.getFacebookUserInfo(accessToken: accessToken, facebookAccount: fbAccount, onCompletion: {userData in
                let id: AnyObject? = userData!["email"]
                let userID = id as String?
                let access_token = self.accessTokenKey(forUserID: userID)
                // save token in defaults
                NSUserDefaults.standardUserDefaults().setObject(accessToken, forKey: access_token)
                
                // user-defined completion
                complete(userID: userID, userData: userData)
                    })
            })
    }
    
    func registerCredentialsWithReplications(repls: Array<CBLReplication>) {
        
    }
    
    //Facebook API
    
    func getFacebookUserInfo(#accessToken: String?,
        facebookAccount fbAccount: ACAccount?,
        onCompletion complete: (userData: Dictionary<String, AnyObject>?) -> ()) {
            let fbLoginURL = NSURL(string: "http://graph.facebook.com/me")
            let request = SLRequest(forServiceType: SLServiceTypeFacebook, requestMethod: SLRequestMethod.GET, URL: fbLoginURL, parameters: nil)
            request.account = fbAccount
            func reqHandler(data: NSData?, response: NSHTTPURLResponse?, error: NSError?) {
                let status: Int?  = response ? response!.statusCode : nil
                if !error && status? == 200 {
                    var deserializationError: NSError?
                    let JSONObj : AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &deserializationError)
                    let userData = JSONObj as Dictionary<String, AnyObject>?
                    if userData && !deserializationError {
                        complete(userData: userData)
                    }
                }
            }
            request.performRequestWithHandler(reqHandler)
    }
    
    func accessTokenKey(forUserID userID: String?) -> String {
        return "CBLFBAT-\(userID)"
    }
    
    func getFacebookAccessToken(compl: (accessToken: String?, fbAccount: ACAccount?) -> ()){
        var accountStore = ACAccountStore()
        var fbAccountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierFacebook)
        var permissions: Array<String> = ["email"]
        var dictFB: Dictionary<String, AnyObject> = [ACFacebookAppIdKey: facebookAppID,
            ACFacebookPermissionsKey: permissions]
        
        accountStore.requestAccessToAccountsWithType(fbAccountType,
            options: dictFB,
            completion: { granted, error in
                if granted {
                    let accounts: Array = accountStore.accountsWithAccountType(fbAccountType)
                    let last = accounts.count - 1
                    let fbAccount = accounts[last] as ACAccount
                    let fbCredential = fbAccount.credential
                    let accessToken = fbCredential.oauthToken
                    compl(accessToken: accessToken, fbAccount: fbAccount)  // pass it along
                } else {
                    // general error message
                    var title = "Account Error"
                    var msg = "There is no Facebook account configured. You can configure an account in Settings."
                    if error.domain == "NSURLErrorDomain" {
                        title = "No connection"
                        msg = "Please go online to login and cync."
                    }
                    dispatch_async(dispatch_get_main_queue(), {
                        let alert = UIAlertView(title: title, message: msg, delegate: nil, cancelButtonTitle: "OK")
                        alert.show()
                        })
                }
            })
        
    }
}
