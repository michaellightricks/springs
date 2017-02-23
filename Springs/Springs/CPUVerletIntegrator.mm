// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "SystemState.h"
#import "CPUVerletIntegrator.h"
#import "Definitions.h"

#import <CoreMotion/CoreMotion.h>

NS_ASSUME_NONNULL_BEGIN

@interface CPUVerletIntegrator() {
  positionType _G;
}

@property (nonatomic) float D;
@property (strong, nonatomic) CMMotionManager *motionManager;

@end

@implementation CPUVerletIntegrator

- (instancetype)initWithDamping:(float)damping {
  if (self = [super init]) {
    self.D = damping;
    _motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 0.1;
    [self.motionManager
      startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue]
      withHandler:^(CMAccelerometerData * _Nullable accelerometerData,
                                         NSError * _Nullable error) {
        self->_G.x = 9.8 * accelerometerData.acceleration.x;
        self->_G.y = 9.8 * accelerometerData.acceleration.y;
        self->_G.z = -9.8 * accelerometerData.acceleration.z;
    }];
  }
  
  return self;
}

- (void)integrateState:(SystemState *)state timeStep:(float)dt to:(positionType *)newPosition{
  float squareDT = dt * dt;
  
  float sqLengthMax = 0;
  for (int i = 0; i < state.verticesCount; ++i) {
    //if ([state vertexPinned:i]) {
    if (i == 0) {
      continue;
    }

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
