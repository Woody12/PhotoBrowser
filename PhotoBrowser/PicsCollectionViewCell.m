//
//  PicsCollectionViewCell.m
//  PicPal
//
//  Created by Lee, Woody on 12/9/14.
//  Copyright (c) 2014 iNVASIVECODE, Inc. All rights reserved.
//

#import "PicsCollectionViewCell.h"

@implementation PicsCollectionViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame])) return nil;
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectInset(CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame)), 5, 5)];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.contentView addSubview:self.imageView];
    
    self.backgroundColor = [UIColor whiteColor];
    
    return self;
}

-(void)prepareForReuse
{
	[super prepareForReuse];
    [self setImage:nil];
	
}

-(void)setImage:(UIImage *)image
{
    self.imageView.image = image;
}


@end
