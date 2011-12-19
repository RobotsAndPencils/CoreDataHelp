//
//  CoreDataHelp.m
//  SRecovery
//
//  Created by Drew Crawford on 7/20/10.
//  Copyright 2010 DrewCrawfordApps LLC. All rights reserved.
//  May have been transferred or licensed to another party under the
//  terms of a copyright release, if applicable.////

#import "CoreDataHelp.h"
@interface CoreDataHelp() {
    BOOL unit_test_mode;
}



@end


@implementation CoreDataHelp
@synthesize managedObjectContext;
static CoreDataHelp *myCoreDataHelp;

+(CoreDataHelp*)shared
{
	if (myCoreDataHelp)
		return myCoreDataHelp;
	
	myCoreDataHelp = [[CoreDataHelp alloc] init];
	return myCoreDataHelp;
}
+ (void)enable_unit_test_mode {
    NSLog(@"Unit test mode enabled.");
    [CoreDataHelp shared]->unit_test_mode = YES;
}
- (void) private_write {
	NSError *error = nil;
        if (![managedObjectContext hasChanges])
        {
            NSLog(@"No changes... bailing out");
            return;
        }
        if (![managedObjectContext save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    NSLog(@"Saved succesfully!");
	
}

- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    if (unit_test_mode) {
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:[NSBundle bundleForClass:[CoreDataHelp class]]]];  
    }

    else {
        managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil] ;  
    }
    return managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    
    
    
    
    
    NSError *error = nil;
    
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    if (unit_test_mode) {
        [persistentStoreCoordinator addPersistentStoreWithType: NSInMemoryStoreType
                                                 configuration: nil
                                                           URL: nil
                                                       options: nil 
                                                         error: &error];
        return persistentStoreCoordinator;
    }
    else {
        NSString *bundle_id = [[NSBundle mainBundle]objectForInfoDictionaryKey:@"CFBundleIdentifier"];
        NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: bundle_id]];
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }    
        
    }
    
    return persistentStoreCoordinator;
}

- (NSManagedObjectContext *) managedObjectContext {
    
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}
/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */


+ (void) write
{
	[[self shared] private_write];
}
+(NSManagedObjectContext*) moc
{
	return [[self shared] managedObjectContext];
}


+ (id)createObjectWithClass:(Class)c {
    NSString *className = NSStringFromClass(c);

    return [NSEntityDescription insertNewObjectForEntityForName:className inManagedObjectContext:[self moc]];
}


+ (NSFetchRequest*) fetchRequestWithClass:(Class) c {
    NSString *className = NSStringFromClass(c);
    return [NSFetchRequest fetchRequestWithEntityName:className];
}

+ (NSArray*) executeFetchRequest:(NSFetchRequest*) fetchRequest error:(NSError**) e {
    return [[self moc] executeFetchRequest:fetchRequest error:e];
}

+ (NSArray*) fetchAllObjectsWithClass:(Class) c error:(NSError**) e {
    NSFetchRequest *request = [self fetchRequestWithClass:c];
    return [self executeFetchRequest:request error:e];
}

+ (id)getObjectWithClass:(Class)c error:(NSError *__autoreleasing *)e {
    NSArray *arr = [self fetchAllObjectsWithClass:c error:e];
    if (arr.count==0) return nil;
    return [arr objectAtIndex:0];
}



@end
