// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import "Protocols.h"
#import "SystemState.h"

NS_ASSUME_NONNULL_BEGIN

@interface PhysicalSystem : NSObject

- (instancetype)initWithState:(SystemState *)state integrator:(id<Integrator>)integrator
                     collider:(id<Collider>)collider;

- (void)addForcesSource:(id<ForceSource>)source;

- (void)integrateTimeStep;

@property (strong, nonatomic) SystemState *state;

@end

NS_ASSUME_NONNULL_END
