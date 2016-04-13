// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "PhysicalSystem.h"

NS_ASSUME_NONNULL_BEGIN

@interface PhysicalSystem()

@property (strong, nonatomic) id<Integrator> integrator;
@property (strong, nonatomic) id<Collider> collider;
@property (strong, nonatomic) NSMutableArray<id<ForceSource> > *forces;
@property (nonatomic) float dT;
@property (nonatomic) float dTSQ;

@end

@implementation PhysicalSystem

- (instancetype)initWithState:(SystemState *)state integrator:(id<Integrator>)integrator
                     collider:(id<Collider>)collider{
  if (self = [super init]) {
    _integrator = integrator;
    _collider = collider;
    _dT = 0.03;
    _dTSQ = _dT * _dT;
    
    self.state = state;
    self.forces = [[NSMutableArray alloc] init];
  }
  
  return self;
}

- (void)addForcesSource:(id<ForceSource>)source {
  [self.forces addObject:source];
}

- (void)integrateTimeStep {
  [self.state zeroForces];
  
  for (id<ForceSource> source in self.forces) {
    [source addForces:self.state to:(positionType *)[self.state.forces contents]];
  }

  positionType *tempPositions = (positionType *)[[self.state tempPositions] contents];
  [self.integrator integrateState:self.state timeStep:self.dT to:tempPositions];
  
  [self.collider collide:self.state intermidiatePositions:tempPositions];
  
  [self.state rollPositions];
}

@end

NS_ASSUME_NONNULL_END
