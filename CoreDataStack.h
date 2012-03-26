//
//  CoreDataStack.h
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreDataHelp/DCAFetchRequest.h>
@interface CoreDataStack : NSObject
+ (CoreDataStack*) inMemoryStack;
+ (CoreDataStack*) incrementalStoreStack:(Class) autoInstallableIncrementalStore;

- (id) executeFetchRequest:(NSFetchRequest*) fetchRequest err:(NSError * __autoreleasing *) err;
- (id) insertNewObjectOfClass:(Class) c;
- (BOOL) save:(NSError *__autoreleasing*) error;

//internal use only!!!!!
- (NSPersistentStore*) persistentStore;
+ (CoreDataStack*) cachingStack;
+ (CoreDataStack*) inMemoryStack_caching;
- (void) queryServed:(NSFetchRequest*) fetchRequest;
- (DCAFetchRequest*) portFetchRequest:(DCAFetchRequest*) fetchRequest;
@end
