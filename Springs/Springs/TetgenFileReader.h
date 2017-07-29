// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <ModelIO/ModelIO.h>
#import <vector>
#import "Definitions.h"

NS_ASSUME_NONNULL_BEGIN

@class SystemState;

@interface TetgenFileReader : NSObject

- (instancetype)initWithFilePathPrefix:(NSString *)prefix device:(id<MTLDevice>)device;

@property (readonly, nonatomic) MTKMesh *mesh;

@property (readonly, nonatomic) std::vector<SpringElement> &springs;

@property (readonly, nonatomic) SystemState *state;

@end

NS_ASSUME_NONNULL_END
