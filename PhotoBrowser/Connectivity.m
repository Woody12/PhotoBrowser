//
//  Connectivity.m
//  PhotoBrowser
//
//  Created by Woody Lee on 6/21/15.
//  Copyright (c) 2015 Woody Lee. All rights reserved.
//

#import "Connectivity.h"
#import "Reachability.h"

@implementation Connectivity

+ (BOOL) checkConnectivity {
	
	Reachability *internetReachability;
	
	//Change the host name here to change the server you want to monitor.
	internetReachability = [Reachability reachabilityForInternetConnection];
	[internetReachability startNotifier];
	if (![self isReachAbility:internetReachability]) {
		
		return false;
		
	}
	
	// No problem
	return true;
	
}

+ (BOOL) reachabilityChanged:(NSNotification *)note {
	
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
	
	return [self isReachAbility:curReach];
	
}

+ (BOOL)isReachAbility:(Reachability *)reachability {
	
	NetworkStatus netStatus = [reachability currentReachabilityStatus];
	BOOL connectionRequired = [reachability connectionRequired];
	
	if ((netStatus == NotReachable) || (connectionRequired)) {
		
		return false;
		
	}
	
	else
		return true;
	
}

@end
