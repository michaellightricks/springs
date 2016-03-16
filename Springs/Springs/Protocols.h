// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import <Foundation/Foundation.h>

#import "SystemState.h"

NS_ASSUME_NONNULL_BEGIN

@protocol Integrator <NSObject>

- (void)integrateState:(SystemState *)state timeStep:(float)dt to:(positionType *)newPosition;

@end

@protocol ForceSource <NSObject>

- (void)addForces:(SystemState *)state to:(positionType *)forces;

@end


NS_ASSUME_NONNULL_END
