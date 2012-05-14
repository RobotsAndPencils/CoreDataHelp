//
//  DCACacheable.h
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/**Indicates that an object is cacheable.*/
@protocol DCACacheable <NSObject>

/**This is a key that can identify an object across the whole stack (network, disk, memory).  As distinct from a Core
 Data key that may be unique only to a particular store. */
@property (readonly) NSString *uniqueID;

@property (readonly) NSString *uniqueIDKeyPath;

/**This is a datestamp that indicates when the object was created, modified, or known to be valid. */
//@property (strong,nonatomic) NSDate *modifiedTime;
 

@end
