//
//  NSIncrementalStore+CDHAdditions.h
//  CoreDataHelp
//
//  Created by Andrew Crawford on 5/8/12.
//  Copyright (c) 2012 Andrew Crawford. All rights reserved.
//

#import <CoreData/CoreData.h>
@class CoreDataStack;
@interface NSIncrementalStore (CDHAdditions)

///Wraps the foreign objects for inception-style serving as native objects of the current context.
-(NSArray*) portForeignObjects:(NSArray*) foreign toContext:(NSManagedObjectContext*) context;
- (NSIncrementalStoreNode *)inceptionNodeForObjectID:(NSManagedObjectID *)oid withInceptionStack:(CoreDataStack*) stack;
@end
