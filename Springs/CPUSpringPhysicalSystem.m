// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "CPUSpringPhysicalSystem.h"

#import "CPUSpringForcesSource.h"
#import "CPUVerletIntegrator.h"
#import "TriangleMeshAdapter.h"
#import "MTKMeshAdapter.h"

NS_ASSUME_NONNULL_BEGIN


@interface CPUSpringPhysicalSystem()

@property (strong, nonatomic) MTKMeshAdapter *adapter;

@end

@implementation CPUSpringPhysicalSystem

- (instancetype)initWithDevice:(id<MTLDevice>)device mesh:(MTKMesh *)mesh{
  SystemState *state = [[SystemState alloc] initWithPositionsBuffer:mesh.vertexBuffers[0].buffer
                                                      verticesCount:mesh.vertexCount
                                                             device:device];
  
  CPUVerletIntegrator *integrator = [[CPUVerletIntegrator alloc] initWithDamping:0.3];
  
  if (self = [super initWithState:state integrator:integrator]) {
   
    self.adapter = [[MTKMeshAdapter alloc] initWithMesh:mesh device:device];
    
    SpringElement *springs = [self.adapter springsPtr];
    
    CPUSpringForcesSource *forcesSource =
    [[CPUSpringForcesSource alloc] initWithElements:springs count:self.adapter.springsCount];

    [self addForcesSource:forcesSource];
  }
  
  return self;
}

@end

NS_ASSUME_NONNULL_END
