// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "CPUSpringPhysicalSystem.h"

#import "CPUSpringForcesSource.h"
#import "CPUVerletIntegrator.h"
#import "TriangleMeshAdapter.h"
#import "MTKMeshAdapter.h"

NS_ASSUME_NONNULL_BEGIN

uint indices[6] = {0, 1, 2, 0, 3, 2};
float vertices[12] = {0.0f, 0.0f, 10.0f,
                      0.0f, 1.0f, 10.0f,
                      1.0f, 1.0f, 10.0f,
                      1.0f, 0.0f, 10.0f};

@implementation CPUSpringPhysicalSystem

- (instancetype)initWithDevice:(id<MTLDevice>)device mesh:(MTKMesh *)mesh{
  SystemState *state = [[SystemState alloc] initWithPositionsBuffer:mesh.vertexBuffers[0].buffer
                                                      verticesCount:mesh.vertexCount
                                                             device:device];
  
  CPUVerletIntegrator *integrator = [[CPUVerletIntegrator alloc] initWithDamping:0.3];
  
  if (self = [super initWithState:state integrator:integrator]) {
   
    MTKMeshAdapter *adapter = [[MTKMeshAdapter alloc] initWithMesh:mesh device:device];
    
    SpringElement *springs = [adapter springsPtr];
    
    CPUSpringForcesSource *forcesSource =
    [[CPUSpringForcesSource alloc] initWithElements:springs count:adapter.springsCount];

    [self addForcesSource:forcesSource];
  }
  
  return self;
}

@end

NS_ASSUME_NONNULL_END
