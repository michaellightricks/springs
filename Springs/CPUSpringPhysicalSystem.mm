// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "CPUSpringPhysicalSystem.h"

#import "CPUSpringForcesSource.h"
#import "CPUVerletIntegrator.h"
#import "MTKMeshAdapter.h"
#import "PlaneCollider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CPUSpringPhysicalSystem

- (instancetype)initWithState:(SystemState *)state
                      springs:(const std::vector<SpringElement> &)springs {
  CPUVerletIntegrator *integrator = [[CPUVerletIntegrator alloc] initWithDamping:0.15];
  positionType origin;
  origin.x = origin.y = origin.z = 0.0;
  origin.w = 1.0;
  
  positionType dim;
  dim.x = dim.y = dim.z = 2.0;
  dim.w = 0.0;
  
  PlaneCollider *collider = [[PlaneCollider alloc] initWithBoxOrigin:origin
                                                          dimensions:dim];

  if (self = [super initWithState:state integrator:integrator collider:collider]) {
    CPUSpringForcesSource *forcesSource =
        [[CPUSpringForcesSource alloc] initWithElements:&springs.front() count:springs.size()];

    [self addForcesSource:forcesSource];
  }
  
  return self;
}

@end

NS_ASSUME_NONNULL_END
