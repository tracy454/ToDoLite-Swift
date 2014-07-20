//
//  List.h
//  ToDo Lite
//
//  Created by Jens Alfke on 8/22/13.
//
//

#import "Titled.h"
@class Task, Profile;

/** A list of Tasks. (See Titled for inherited properties!) */
@interface List : Titled

/** Returns a query for all the lists in a database. */
+ (CBLQuery*) queryListsInDatabase: (CBLDatabase*)db;

/** Run before first sync to tag existing local lists as belonging to the current user. */
+ (void) updateAllListsInDatabase: (CBLDatabase*)database withOwner: (Profile*)owner error: (NSError**)e ;


/** Returns a query for this list's tasks, in reverse chronological order. */
- (CBLQuery*) queryTasks;

/** Creates a new task. */
- (Task*) addTaskWithTitle: (NSString*)title withImage: (NSData*)image withImageContentType: (NSString*)contentType;

@property (readwrite) Profile* owner;

@property (readwrite) NSArray* members;

@end
