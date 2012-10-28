//
//  NSManagedObjectModel+CDHAdditions.m
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSManagedObjectModel+CDHAdditions.h"
#import "DCAFetchRequestModel.h"
#import "NSManagedObject+DCAAdditions.h"
#import "CoreDataHelp.h"
@implementation NSManagedObjectModel (CDHAdditions)
+ (NSManagedObjectModel *)defaultModel {
    return [NSManagedObjectModel mergedModelFromBundles:nil];
}

+ (NSManagedObjectModel *)cachingModel {
    NSManagedObjectModel *defaultModel = [[NSManagedObjectModel defaultModel] copy];
    //hack in additional models
    NSArray *models = defaultModel.entities;
    
    
    NSMutableArray *newModels = [NSMutableArray array];
    for (NSEntityDescription *model in models) {
        NSEntityDescription *newModel = [[NSEntityDescription alloc] init];
        newModel.name = model.name;
        NSAttributeDescription *uniqueId = [[NSAttributeDescription alloc] init];
        uniqueId.attributeType = NSStringAttributeType;
        uniqueId.name = INTERNAL_CACHING_KEY;
        NSMutableArray *newProperties = [NSMutableArray arrayWithCapacity:model.properties.count];
        for (NSPropertyDescription *propertyDescription in model.properties) {
            [newProperties addObject:[propertyDescription copy]];
        }
        [newProperties addObject:uniqueId];
        newModel.properties = newProperties;
        [newModels addObject:newModel];
    }
    NSEntityDescription *DCAFetchRequestModelDescription = [[NSEntityDescription alloc] init];
    DCAFetchRequestModelDescription.name = [DCAFetchRequestModel entityName];
    DCAFetchRequestModelDescription.managedObjectClassName = [DCAFetchRequestModel entityName];
    NSAttributeDescription  *DCAFetchRequestModelInceptionAttribute = [[NSAttributeDescription alloc] init];
    DCAFetchRequestModelInceptionAttribute.name = @"fetchRequest";
    DCAFetchRequestModelInceptionAttribute.attributeValueClassName = NSStringFromClass([DCAFetchRequest class]);
    DCAFetchRequestModelDescription.properties = [NSArray arrayWithObject:DCAFetchRequestModelInceptionAttribute];
    [newModels addObject:DCAFetchRequestModelDescription];
    defaultModel.entities = newModels;
    return defaultModel;
}

+ (NSManagedObjectModel *)modelWithFilenameOmitExtension:(NSString *)fileName inBundle:(NSBundle *)bundle {
    NSString *path = [bundle pathForResource:fileName ofType:@"momd"];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:path];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:fileURL];
    NSAssert(model,@"Could not load model from path %@",fileURL);
    return model;
}
@end
