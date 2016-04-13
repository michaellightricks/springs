// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "SystemState.h"
#import "CPUVerletIntegrator.h"
#import "Definitions.h"

NS_ASSUME_NONNULL_BEGIN

@interface CPUVerletIntegrator() {
  positionType _G;
}

@property (nonatomic) float D;

@end

@implementation CPUVerletIntegrator

- (instancetype)initWithDamping:(float)damping {
  if (self = [super init]) {
    self.D = damping;
    _G = {0, -9.8, 0, 0};
  }
  
  return self;
}

- (void)integrateState:(SystemState *)state timeStep:(float)dt to:(positionType *)newPosition{
  float squareDT = dt * dt;
  
  float sqLengthMax = 0;
  for (int i = 0; i < state.verticesCount; ++i) {
    positionType pos = [state getPositionAtIndex:i];
    positionType prevPos = [state getPrevPositionAtIndex:i];
    positionType force = [state getForceAtIndex:i] + _G;

    float sqLength = simd::length_squared(force);
    if (sqLength > sqLengthMax && sqLength > 100) {
      sqLengthMax = sqLength;
    }
    
    newPosition[i] = (2 - self.D) * pos - (1 - self.D) * prevPos + squareDT * force;
  }
  
  if (sqLengthMax > 100) {
    NSLog(@"%f", sqLengthMax);
  }
}

@end

NS_ASSUME_NONNULL_END
