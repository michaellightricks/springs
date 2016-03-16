// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "SystemState.h"

NS_ASSUME_NONNULL_BEGIN

@interface SystemState()

//@property (nonatomic) NSRange modifiedRange;

@end

@implementation SystemState

- (instancetype)initWithPositions:(vector_float3 *)points length:(NSUInteger)length
                           device:(id<MTLDevice>)device {
  if (self = [super init]) {
    _verticesCount = length;
    
    NSUInteger bufferLength = (sizeof(vector_float3) * _verticesCount);
    
    self.positions = [device newBufferWithBytes:points length:bufferLength options:0];
    self.prevPositions =
        [device newBufferWithBytes:points length:bufferLength options:0];
    
    self.forces = [device newBufferWithLength:bufferLength options:0];
    self.pinned = [device newBufferWithLength:(sizeof(BOOL) * _verticesCount) options:0];
  }
  
  return self;
}

- (void)pinVertexAtIndex:(NSUInteger)index atPosition:(vector_float3)newPosition {
  BOOL *buffer = (BOOL *)[self.pinned contents];
  
  buffer[index] = YES;

  vector_float3 *position = [self getPositionFrom:self.positions atIndex:index];
  *position = newPosition;
  
  vector_float3 *prevPosition = [self getPositionFrom:self.prevPositions atIndex:index];
  *prevPosition = newPosition;
  
//  self.modifiedRange = NSMakeRange(MIN(self.modifiedRange.location, index),
//                                   MAX(self.modifiedRange.length,
//                                       ABS(self.modifiedRange.location - index)));
}

- (void)unpinVertexAtIndex:(NSUInteger)index {
  BOOL *buffer = (BOOL *)[self.pinned contents];
  buffer[index] = NO;
}

- (BOOL)vertexPinned:(NSUInteger)index {
  BOOL *buffer = (BOOL *)[self.pinned contents];
  return buffer[index];
}

- (vector_float3)getPositionAtIndex:(NSUInteger)index {
  return *[self getPositionFrom:self.positions atIndex:index];
}

- (vector_float3)getPrevPositionAtIndex:(NSUInteger)index {
  return *[self getPositionFrom:self.prevPositions atIndex:index];
}

- (vector_float3)getForceAtIndex:(NSUInteger)index {
  return *[self getPositionFrom:self.forces atIndex:index];
}

- (vector_float3 *)getPositionFrom:(id<MTLBuffer>)buffer atIndex:(NSUInteger)index {
  vector_float3 *ptr = (vector_float3 *)[buffer contents];
  return ptr + index;
}

@end

NS_ASSUME_NONNULL_END
