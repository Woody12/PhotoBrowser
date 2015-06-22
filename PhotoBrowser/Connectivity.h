//
//  Connectivity.h
//  PhotoBrowser
//
//  Created by Woody Lee on 6/21/15.
//  Copyright (c) 2015 Woody Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Connectivity : NSObject

+ (BOOL) checkConnectivity;
+ (BOOL) reachabilityChanged:(NSNotification *)note;

@end
