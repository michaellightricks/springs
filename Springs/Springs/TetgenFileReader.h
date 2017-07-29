// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <ModelIO/ModelIO.h>
#import "Definitions.h"

NS_ASSUME_NONNULL_BEGIN

@interface TetgenFileReader : NSObject

- (MTKMesh *)meshFromFiles:(NSString *)fileNamePattern device:(id<MTLDevice>)device;

@end

NS_ASSUME_NONNULL_END
