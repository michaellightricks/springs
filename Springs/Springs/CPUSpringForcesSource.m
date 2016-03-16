// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "CPUSpringForcesSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface CPUSpringForcesSource()

@property (nonatomic) NSUInteger elementsCount;
@property (nonatomic) SpringElement *elements;

@end

@implementation CPUSpringForcesSource

- (instancetype)initWithElements:(SpringElement *)elements count:(NSUInteger)count {
  if (self = [super init]) {
    self.elements = elements;
    self.elementsCount = count;
  }
  
  return self;
}

- (void)addForces:(SystemState *)state to:(positionType *)forces{
  
  for (size_t i = 0; i < self.elementsCount; ++i) {
    SpringElement element = self.elements[i];
    positionType pos1 = [state getPositionAtIndex:element.idx1];
    positionType pos2 = [state getPositionAtIndex:element.idx2];
    
    positionType force = (pos1 - pos2) * element.k;
    
    forces[element.idx1] += force;
    forces[element.idx2] -= force;
  }
}

@end

NS_ASSUME_NONNULL_END
