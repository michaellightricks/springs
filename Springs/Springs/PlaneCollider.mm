// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "PlaneCollider.h"

#import <vector>

NS_ASSUME_NONNULL_BEGIN

typedef struct PlaneType {
  positionType normal;
  positionType origin;
  float d;
} Plane;

@interface PlaneCollider() {
  std::vector<Plane> planes;
}

@end

@implementation PlaneCollider

- (instancetype)initWithBoxOrigin:(positionType)origin dimensions:(positionType)dimensions {
  if (self = [super init]) {
    Plane bottom;
    bottom.normal = {0.0, 1.0, 0.0};
    bottom.d = dimensions.y;
    bottom.origin = {0.0, -bottom.d, 0.0};
    
    planes.push_back(bottom);
    
//    Plane left;
//    left.normal = {1.0, 0.0, 0.0};
//    left.d = dimensions.x;
//
//    planes.push_back(left);
//    
//    Plane right;
//    right.normal = {-1.0, 0.0, 0.0};
//    right.d = -dimensions.x;
//
//    planes.push_back(right);
  }
  
  return self;
}

- (void)collide:(SystemState *)state intermidiatePositions:(positionType *)positions {
  for (int i = 0; i < state.verticesCount; ++i) {
    positionType prevPos = [state getPositionAtIndex:i];
    positionType& pos = positions[i];
    
    for (int j = 0; j < planes.size(); ++j) {
      Plane plane = planes[j];
      
      float d = simd::dot(plane.normal, pos) + plane.d;
      
      if (d < 0.0) { // we have collision
        pos = [self intersectPlane:plane segmentStart:prevPos end:pos];
      }
    }
  }
}

- (positionType)intersectPlane:(Plane)plane segmentStart:(positionType)start end:(positionType)end {
  positionType v = end - start;
  float t = - (simd::dot(start, plane.normal) + plane.d) / simd::dot(plane.origin, v);
  
  return start + t * v;
}

@end

NS_ASSUME_NONNULL_END
