// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

@import Foundation;
@import Metal;
@import MetalKit;

#import "Protocols.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct SpringElementType {
  size_t idx1;
  size_t idx2;
  float k;
} SpringElement;

@interface CPUSpringForcesSource : NSObject<ForceSource>

- (instancetype)initWithElements:(SpringElement *)elements count:(NSUInteger)count;

@end

NS_ASSUME_NONNULL_END
