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
    NSMutableArray *newModels = [NSMutableArray arrayWithArray:models];
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
@end
