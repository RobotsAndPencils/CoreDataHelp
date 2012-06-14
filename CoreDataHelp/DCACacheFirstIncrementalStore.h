//
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "NSIncrementalStoreAutoInstall.h"
#import "DCACachingPolicy.h"
#import "CoreDataStack.h"
/**Status: caching does not currently work, but the below is documented for future */

/**We have a core problem with NSIncrementalStore:
 
 1) It often queries separate things separately.  For example, property fetches come in on <newValuesForObjectWithID:withContext:error:>, but object keys come in on <executeRequest:withContext:error:>
 2) In pratice, APIs are not designed for our access pattern.  Data does not always come in where it would be most convenient for NSIncrementalStore.  For example, you may call an API like www.example.com/objects that gets all the objects, with their properties.  Then you must somehow field hundreds of calls to <newValuesForObjectWithID:withContext:error:> from this data.
 
 This class is an NSIncrementalStore that tries cache first.  The basic pattern is:
 
 1) Field a callback, checking the caching policy and the cache to determine if the request can be served from cache.  We first try to find a caching policy that is request-specific, and failing that, we fall back to the default cahching policy for the store.
 2) If the caching policy indicates that we can use the data, we return the data, never bothering the subclass
 3) If the caching policy fails, we call the method prefixed with DCA (e.g. DCAexecuteRequest...) to fetch the data. */

static const NSString *cacheIsCorrectNow = @"CacheIsCorrectNow";

@interface DCACacheFirstIncrementalStore : NSIncrementalStore <NSIncrementalStoreAutoInstall>

+(NSString *)storeType;
+(NSString *) storeUUID;


@property (strong,nonatomic) DCACachingPolicy *defaultCachingPolicy;
@property (strong,nonatomic) CoreDataStack *cacheStack;

-(id)dcaExecuteRequest:(NSPersistentStoreRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error;

- (BOOL)multipleObjectsMatchingCacheable:(NSManagedObject<DCACacheable> *)cacheable;


@end
