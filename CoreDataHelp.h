//
//  CoreDataHelp.h
//  SRecovery
//
//  Created by Drew Crawford on 7/20/10.
//  Copyright 2010 DrewCrawfordApps LLC. All rights reserved.
//  May have been transferred or licensed to another party under the
//  terms of a copyright release, if applicable.////

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>


@interface CoreDataHelp : NSObject {
	NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;

}
@property (readonly) NSManagedObjectContext *managedObjectContext;

+(NSManagedObjectContext*) moc;
+ (void) write;
+ (id) createObjectWithClass:(Class) c;
+ (void)enable_unit_test_mode;

//fetching objects from the database
//high-level methods
+ (NSArray*) fetchAllObjectsWithClass:(Class) c error:(NSError**) e;
//returns a single object
+ (id) getObjectWithClass:(Class) c error:(NSError**) e;

//low-level methods
//returns a fetch request which can define more powerful queries
+ (NSFetchRequest*) fetchRequestWithClass:(Class) c;
//executes a fetch request
+ (NSArray*) executeFetchRequest:(NSFetchRequest*) fetchRequest error:(NSError**) e;



#if !(defined (DCA_RELEASE)) && !(defined(DCA_DEBUG)) && !defined(DCA_UNITTEST)
#error You are need to define one or more of the following symbols to compile LogBuddy:  RELEASE, DEBUG, UNITTEST
#endif


#if (defined(DCA_RELEASE) && defined(DCA_DEBUG)) || (defined(DCA_RELEASE) && defined(DCA_UNITTEST)) || (defined(DCA_DEBUG) && defined(DCA_UNITTEST))
#error Too many symbols!
#endif

//use this macro to start CoreDataHelp

#ifdef DCA_DEBUG
#define COREDATAHELP_START
#endif
#ifdef DCA_RELEASE
#define COREDATAHELP_START
#endif
#ifdef DCA_UNITTEST
#define COREDATAHELP_START [CoreDataHelp enable_unit_test_mode]
#endif
@end
