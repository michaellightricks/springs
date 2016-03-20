// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#import "Definitions.h"

NS_ASSUME_NONNULL_BEGIN

@interface SystemState : NSObject

- (instancetype)initWithPositions:(positionType *)points length:(NSUInteger)length
                           device:(id<MTLDevice>)device;

- (instancetype)initWithPositionsBuffer:(id<MTLBuffer>)buffer verticesCount:(NSUInteger)count
                                 device:(id<MTLDevice>)device;

- (positionType)getPositionAtIndex:(NSUInteger)index;

- (positionType)getPrevPositionAtIndex:(NSUInteger)index;

- (positionType)getForceAtIndex:(NSUInteger)index;

- (void)pinVertexAtIndex:(NSUInteger)index atPosition:(positionType)position;

- (void)unpinVertexAtIndex:(NSUInteger)index;

- (BOOL)vertexPinned:(NSUInteger)index;

@property (nonatomic) NSUInteger verticesCount;
@property (strong, nonatomic) id<MTLBuffer> positions;
@property (strong, nonatomic) id<MTLBuffer> prevPositions;
@property (strong, nonatomic) id<MTLBuffer> forces;
@property (strong, nonatomic) id<MTLBuffer> pinned;

@end


NS_ASSUME_NONNULL_END
