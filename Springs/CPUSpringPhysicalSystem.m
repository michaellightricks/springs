// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "CPUSpringPhysicalSystem.h"

#import "CPUSpringForcesSource.h"
#import "CPUVerletIntegrator.h"
#import "TriangleMeshAdapter.h"
#import "MTKMeshAdapter.h"
#import "PlaneCollider.h"

NS_ASSUME_NONNULL_BEGIN


@interface CPUSpringPhysicalSystem()

@property (strong, nonatomic) MTKMeshAdapter *adapter;

@end

@implementation CPUSpringPhysicalSystem

- (instancetype)initWithDevice:(id<MTLDevice>)device mesh:(MTKMesh *)mesh{
  MTKMeshAdapter *adapter = [[MTKMeshAdapter alloc] initWithMesh:mesh device:device];
  
  SystemState *state = [[SystemState alloc] initWithPositions:adapter.positionsBuffer
                                                       length:mesh.vertexBuffers[0].length
                                                       offset:mesh.vertexBuffers[0].offset
                                                       device:device vertexCount:adapter.verticesCount];

  CPUVerletIntegrator *integrator = [[CPUVerletIntegrator alloc] initWithDamping:0.3];
  positionType origin;
  origin.x = origin.y = origin.z = 0.0;
  origin.w = 1.0;
  
  positionType dim;
  dim.x = dim.y = dim.z = 2.0;
  dim.w = 0.0;
  
  PlaneCollider *collider = [[PlaneCollider alloc] initWithBoxOrigin:origin
                                                          dimensions:dim];

  if (self = [super initWithState:state integrator:integrator collider:collider]) {
    self.adapter = adapter;
    SpringElement *springs = [self.adapter springsPtr];
    
    CPUSpringForcesSource *forcesSource =
    [[CPUSpringForcesSource alloc] initWithElements:springs count:self.adapter.springsCount];

    [self addForcesSource:forcesSource];
  }
  
  return self;
}

@end

NS_ASSUME_NONNULL_END
