// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#import "Definitions.h"

NS_ASSUME_NONNULL_BEGIN

@interface SystemState : NSObject

- (instancetype)initWithPositions:(id<MTLBuffer>)positionsBuffer length:(NSUInteger)length
                           offset:(NSUInteger)offset device:(id<MTLDevice>)device
                      vertexCount:(NSUInteger)count;

- (positionType)getPositionAtIndex:(NSUInteger)index;

- (positionType)getPrevPositionAtIndex:(NSUInteger)index;

- (positionType)getForceAtIndex:(NSUInteger)index;

- (void)pinVertexAtIndex:(NSUInteger)index atPosition:(positionType)position;

- (void)unpinVertexAtIndex:(NSUInteger)index;

- (BOOL)vertexPinned:(NSUInteger)index;

- (void)rollPositions;

- (void)zeroForces;

@property (nonatomic) NSUInteger positionsOffset;
@property (nonatomic) NSUInteger verticesCount;
@property (strong, nonatomic) id<MTLBuffer> positions;
@property (strong, nonatomic) id<MTLBuffer> prevPositions;
@property (strong, nonatomic) id<MTLBuffer> tempPositions;
@property (strong, nonatomic) id<MTLBuffer> forces;
@property (strong, nonatomic) id<MTLBuffer> pinned;

@end


NS_ASSUME_NONNULL_END
