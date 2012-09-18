//
//  NSManagedObject+Parse.h
//  CarAccidentHelp
//
//  Created by Drew Crawford on 12/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (Parse)
+ (BOOL) syncAll;
@end
