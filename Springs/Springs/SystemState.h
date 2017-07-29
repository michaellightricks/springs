// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#import "Definitions.h"

NS_ASSUME_NONNULL_BEGIN

@interface SystemState : NSObject

- (instancetype)initWithPositions:(id<MTLBuffer>)positionsBuffer
                           offset:(NSUInteger)offset stride:(NSUInteger)stride
                           device:(id<MTLDevice>)device
                      vertexCount:(NSUInteger)count;

- (positionType)getPositionAtIndex:(NSUInteger)index;

- (positionType)getPrevPositionAtIndex:(NSUInteger)index;

- (positionType)getTempPositionAtIndex:(NSUInteger)index;

- (void)setTempPosition:(positionType)position AtIndex:(NSUInteger)index;

- (positionType)getForceAtIndex:(NSUInteger)index;

- (void)pinVertexAtIndex:(NSUInteger)index atPosition:(positionType)position;

- (void)unpinVertexAtIndex:(NSUInteger)index;

- (BOOL)vertexPinned:(NSUInteger)index;

- (void)rollPositions;

- (void)zeroForces;

@property (nonatomic) NSUInteger positionsOffset;
@property (nonatomic) NSUInteger stride;
@property (nonatomic) NSUInteger verticesCount;
@property (strong, nonatomic) id<MTLBuffer> positions;
@property (strong, nonatomic) id<MTLBuffer> prevPositions;
@property (strong, nonatomic) id<MTLBuffer> tempPositions;
@property (strong, nonatomic) id<MTLBuffer> forces;
@property (strong, nonatomic) id<MTLBuffer> pinned;

@end


NS_ASSUME_NONNULL_END
