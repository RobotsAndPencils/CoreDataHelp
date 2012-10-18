//
//  NSManagedObjectModel+CDHAdditions.h
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectModel (CDHAdditions)
+ (NSManagedObjectModel*) defaultModel;
+(NSManagedObjectModel*) cachingModel;
@end
