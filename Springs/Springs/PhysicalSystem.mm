// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "PhysicalSystem.h"

NS_ASSUME_NONNULL_BEGIN

@interface PhysicalSystem()

@property (strong, nonatomic) id<Integrator> integrator;
@property (strong, nonatomic) NSArray<id<ForceSource> > *forces;
@property (nonatomic) float dT;
@property (nonatomic) float dTSQ;
@property (nonatomic, nullable) positionType * tempPositions;

@end

@implementation PhysicalSystem

- (instancetype)initWithState:(SystemState *)state integrator:(id<Integrator>)integrator
                       forces:(NSArray<id<ForceSource> > *)forces {
  if (self = [super init]) {
    _integrator = integrator;
    _forces = [forces copy];
    _dT = 0.2;
    _dTSQ = _dT * _dT;
    
    self.tempPositions = (positionType *)malloc(state.verticesCount * sizeof(positionType));
  }
  
  return self;
}

- (void)integrateTimeStep {
  for (id<ForceSource> source in self.forces) {
    [source addForces:self.state to:(positionType *)[self.state.forces contents]];
  }
  
  [self.integrator integrateState:self.state timeStep:self.dT to:self.tempPositions];
}

@end

NS_ASSUME_NONNULL_END
