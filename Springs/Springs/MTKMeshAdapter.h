// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <ModelIO/ModelIO.h>
#import "Definitions.h"
#import <vector>

NS_ASSUME_NONNULL_BEGIN

@interface MTKMeshAdapter : NSObject {
@public
  std::vector<SpringElement> springs;
}

- (instancetype)initWithMesh:(MTKMesh *)mesh device:(id<MTLDevice>)device;

- (SpringElement *)springsPtr;

@property (readonly, nonatomic) NSUInteger verticesCount;
@property (readonly, nonatomic) NSUInteger springsCount;

@property (strong, nonatomic) id<MTLBuffer> positionsBuffer;
@property (strong, nonatomic) id<MTLBuffer> springsBuffer;
@property (strong, nonatomic) id<MTLBuffer> trianglesBuffer;



@end

NS_ASSUME_NONNULL_END
