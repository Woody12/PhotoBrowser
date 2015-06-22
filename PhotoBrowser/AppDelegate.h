//
//  AppDelegate.h
//  PhotoBrowser
//
//  Created by Woody Lee on 6/20/15.
//  Copyright (c) 2015 Woody Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

extern NSString const* kFlickrKey;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;


@end

