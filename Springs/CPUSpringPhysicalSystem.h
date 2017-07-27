// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import <Foundation/Foundation.h>

#import <vector>

#import "PhysicalSystem.h"

NS_ASSUME_NONNULL_BEGIN

@interface CPUSpringPhysicalSystem : PhysicalSystem

- (instancetype)initWithState:(SystemState *)state
                      springs:(const std::vector<SpringElement> &)springs;

@property (readonly, nonatomic) MTKMesh *mesh;

@end

NS_ASSUME_NONNULL_END
