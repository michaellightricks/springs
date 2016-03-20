// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import <Foundation/Foundation.h>

#import "PhysicalSystem.h"

NS_ASSUME_NONNULL_BEGIN

@interface CPUSpringPhysicalSystem : PhysicalSystem

- (instancetype)initWithDevice:(id<MTLDevice>)device mesh:(MTKMesh *)mesh;

@property (readonly, nonatomic) MTKMesh *mesh;

@end

NS_ASSUME_NONNULL_END
