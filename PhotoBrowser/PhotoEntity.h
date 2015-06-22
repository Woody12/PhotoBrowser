//
//  PhotoEntity.h
//  
//
//  Created by Woody Lee on 6/21/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PhotoEntity : NSManagedObject

@property (nonatomic, retain) NSNumber * farm;
@property (nonatomic, retain) NSString * fullImageURL;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSNumber * photoID;
@property (nonatomic, retain) NSString * secret;
@property (nonatomic, retain) NSNumber * server;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSString * title;

@end
