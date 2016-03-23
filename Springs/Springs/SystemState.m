// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "SystemState.h"

NS_ASSUME_NONNULL_BEGIN

@interface SystemState()

@end

@implementation SystemState

- (instancetype)initWithPositions:(id<MTLBuffer>)positionsBuffer length:(NSUInteger)length
                           offset:(NSUInteger)offset device:(id<MTLDevice>)device
                      vertexCount:(NSUInteger)count {
  if (self = [super init]) {
    _verticesCount = count ;
    self.positionsOffset = offset;
    self.positions = positionsBuffer;
    
    void *ptr = [positionsBuffer contents];
    
    self.prevPositions =
        [device newBufferWithBytes:ptr length:length options:0];
    self.tempPositions =
        [device newBufferWithBytes:ptr length:length options:0];
    
    self.forces = [device newBufferWithLength:sizeof(positionType) * _verticesCount  options:0];
    self.pinned = [device newBufferWithLength:(sizeof(BOOL) * _verticesCount) options:0];
  }
  
  return self;
}

- (instancetype)initWithPositionsBuffer:(id<MTLBuffer>)buffer verticesCount:(NSUInteger)count
                                 device:(id<MTLDevice>)device {
  if (self = [super init]) {
    _verticesCount = count;
    
    self.positions = buffer;
    self.prevPositions =
        [device newBufferWithBytes:[buffer contents] length:buffer.length options:0];
    
    self.forces = [device newBufferWithLength:(sizeof(positionType) * _verticesCount)  options:0];
    self.pinned = [device newBufferWithLength:(sizeof(BOOL) * _verticesCount) options:0];
  }
  
  return self;

}

- (void)pinVertexAtIndex:(NSUInteger)index atPosition:(positionType)newPosition {
  BOOL *buffer = (BOOL *)[self.pinned contents];
  
  buffer[index] = YES;

  positionType *position = [self getPositionFrom:self.positions atIndex:index
                                          offset:self.positionsOffset];
  *position = newPosition;
  
  positionType *prevPosition = [self getPositionFrom:self.prevPositions atIndex:index
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
  return *[self getPositionFrom:self.positions atIndex:index offset:self.positionsOffset];
}

- (positionType)getPrevPositionAtIndex:(NSUInteger)index {
  return *[self getPositionFrom:self.prevPositions atIndex:index offset:self.positionsOffset];
}

- (positionType)getForceAtIndex:(NSUInteger)index {
  return *[self getPositionFrom:self.forces atIndex:index offset:0];
}

- (positionType *)getPositionFrom:(id<MTLBuffer>)buffer atIndex:(NSUInteger)index
                           offset:(NSUInteger)offset{
  void *ptr = [buffer contents];
 
  positionType *posPtr = (positionType *) (ptr + offset);
  return posPtr + index;
}

@end

NS_ASSUME_NONNULL_END
