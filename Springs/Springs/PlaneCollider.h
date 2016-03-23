// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import <Foundation/Foundation.h>

#import "Protocols.h"

NS_ASSUME_NONNULL_BEGIN

@interface PlaneCollider : NSObject<Collider>

- (instancetype)initWithBoxOrigin:(positionType)origin dimensions:(positionType)dimensions;

@end

NS_ASSUME_NONNULL_END
