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
    _G = simd::float4(0);
     _motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 0.1;
    [self.motionManager
      startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue]
      withHandler:^(CMAccelerometerData * _Nullable accelerometerData,
                                         NSError * _Nullable error) {
        self->_G.x = 0;//9.8 * accelerometerData.acceleration.x;
        self->_G.y = -9.8;// * accelerometerData.acceleration.y;
        self->_G.z = 0;//-9.8 * accelerometerData.acceleration.z;
    }];
  }
  
  return self;
}

- (void)integrateState:(SystemState *)state timeStep:(float)dt {
  float squareDT = dt * dt;
  
  float sqLengthMax = 0;
  for (int i = 0; i < state.verticesCount; ++i) {
    //if ([state vertexPinned:i]) {
    if (i < 10) {
      continue;
    }

    positionType pos = [state getPositionAtIndex:i];
    positionType prevPos = [state getPrevPositionAtIndex:i];
    positionType force = [state getForceAtIndex:i] + _G;

    float sqLength = simd::length_squared(force);
    if (sqLength > sqLengthMax && sqLength > 100) {
      sqLengthMax = sqLength;
    }

    positionType newPos = (2 - self.D) * pos - (1 - self.D) * prevPos + squareDT * force;
    [state setTempPosition:newPos AtIndex:i];
  }
  
  if (sqLengthMax > 100) {
    NSLog(@"%f", sqLengthMax);
  }
}

@end

NS_ASSUME_NONNULL_END
