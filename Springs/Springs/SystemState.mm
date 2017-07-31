// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "SystemState.h"

NS_ASSUME_NONNULL_BEGIN

@interface SystemState()

@end

@implementation SystemState

- (instancetype)initWithPositions:(id<MTLBuffer>)positionsBuffer
                           offset:(NSUInteger)offset stride:(NSUInteger)stride
                           device:(id<MTLDevice>)device
                      vertexCount:(NSUInteger)count {
  if (self = [super init]) {
    _verticesCount = count ;
    self.positionsOffset = offset;
    self.positions = positionsBuffer;
    self.stride = stride;
    
    void *ptr = [positionsBuffer contents];
    
    self.prevPositions =
        [device newBufferWithBytes:ptr length:positionsBuffer.length options:0];
    self.tempPositions =
        [device newBufferWithBytes:ptr length:positionsBuffer.length options:0];
    
    self.forces = [device newBufferWithLength:sizeof(positionType) * _verticesCount  options:0];
    self.pinned = [device newBufferWithLength:(sizeof(BOOL) * _verticesCount) options:0];
    memset([self.pinned contents], sizeof(BOOL) * _verticesCount, 0);
  }
  
  return self;
}

- (void)pinVertexAtIndex:(NSUInteger)index atPosition:(positionType)newPosition {
  BOOL *buffer = (BOOL *)[self.pinned contents];
  
  buffer[index] = YES;

  positionType *position = [self getPositionFrom:self.positions atIndex:index
                                          stride:self.stride
                                          offset:self.positionsOffset];
  *position = newPosition;
  
  positionType *prevPosition = [self getPositionFrom:self.prevPositions atIndex:index
                                              stride:self.stride
                                              offset:self.positionsOffset];
  *prevPosition = newPosition;
}

- (void)rollPositions {
  id<MTLBuffer> temp = self.prevPositions;

  self.prevPositions = self.positions;
  self.positions = self.tempPositions;
  self.tempPositions = temp;
}

- (void)zeroForces {
  memset([self.forces contents], 0, sizeof(positionType) * self.verticesCount);
}

- (void)unpinVertexAtIndex:(NSUInteger)index {
  BOOL *buffer = (BOOL *)[self.pinned contents];
  buffer[index] = NO;
}

- (BOOL)vertexPinned:(NSUInteger)index {
  BOOL *buffer = (BOOL *)[self.pinned contents];
  return buffer[index];
}

- (positionType)getPositionAtIndex:(NSUInteger)index {
  return *[self getPositionFrom:self.positions atIndex:index stride:self.stride
                         offset:self.positionsOffset];
}

- (positionType)getPrevPositionAtIndex:(NSUInteger)index {
  return *[self getPositionFrom:self.prevPositions atIndex:index stride:self.stride
                         offset:self.positionsOffset];
}

- (void)setTempPosition:(positionType)position AtIndex:(NSUInteger)index {
  *[self getPositionFrom:self.tempPositions atIndex:index stride:self.stride
                  offset:self.positionsOffset] = position;
}

- (positionType)getTempPositionAtIndex:(NSUInteger)index {
  return *[self getPositionFrom:self.tempPositions atIndex:index stride:self.stride
                         offset:self.positionsOffset];
}

- (positionType)getForceAtIndex:(NSUInteger)index {
  return *[self getPositionFrom:self.forces atIndex:index stride:sizeof(positionType) offset:0];
}

- (positionType *)getPositionFrom:(id<MTLBuffer>)buffer atIndex:(NSUInteger)index
                           stride:(NSUInteger)stride
                           offset:(NSUInteger)offset{
  uint8_t *ptr = (uint8_t *)[buffer contents];
  ptr = ptr + offset + index * stride;

  return (positionType *) (ptr);
}

@end

NS_ASSUME_NONNULL_END
