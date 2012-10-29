//
//  NSManagedObject+DCAAdditions.h
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "DCAFetchRequest.h"
@interface NSManagedObject (DCAAdditions)

+(DCAFetchRequest*) dcaFetchRequest;
+(NSString*) entityName;

+ (id) prototype;
-(void) assertThreading;

/**Turns the object into a fault.
 @param areYouPositivethereAreNoChanges - we can perform certain optimizations if you can guarantee that neither attributes nor relationships (including inverses of other relationships) have changed. */
-(void) fault:(BOOL) areYouPositiveThereAreNoChanges;
@end
