// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import <Foundation/Foundation.h>

#import "SystemState.h"

NS_ASSUME_NONNULL_BEGIN

@protocol Integrator <NSObject>

/// Sets new positions to tempPositions of state.
- (void)integrateState:(SystemState *)state timeStep:(float)dt;

@end

@protocol ForceSource <NSObject>

- (void)addForces:(SystemState *)state to:(positionType *)forces;

@end

@protocol Collider <NSObject>

/// Sets new positions to tempPositions of state.
- (void)collide:(SystemState *)state;

@end


NS_ASSUME_NONNULL_END
