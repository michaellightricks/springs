// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import "Protocols.h"

NS_ASSUME_NONNULL_BEGIN

@interface CPUVerletIntegrator : NSObject<Integrator>

- (instancetype)initWithDamping:(float)damping;

@end

NS_ASSUME_NONNULL_END
