// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "TetgenFileReader.h"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import "DDFileReader.h"

NS_ASSUME_NONNULL_BEGIN

NSCharacterSet *kCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" \t"];

@implementation TetgenFileReader

- (MTKMesh *)meshFromFiles:(NSString *)fileNamePattern device:(id<MTLDevice>)device {
  MDLMesh *mdlMesh = [self loadMesh:fileNamePattern device:device];
  NSError *error;
  MTKMesh *mesh = [[MTKMesh alloc] initWithMesh:mdlMesh device:device error:&error];
  return mesh;
}

- (MDLMesh *)loadMesh:(NSString *)fileNamePattern device:(id<MTLDevice>)device {
  MDLVertexDescriptor *descriptor = [[MDLVertexDescriptor alloc] init];
  [descriptor reset];
  [descriptor.attributes removeAllObjects];
  [descriptor.layouts removeAllObjects];
  MDLVertexAttribute *positionsAttr = [[MDLVertexAttribute alloc]
                                       initWithName:MDLVertexAttributePosition
                                       format:MDLVertexFormatFloat4 offset:0 bufferIndex:0];
  [descriptor addOrReplaceAttribute:positionsAttr];
  MDLVertexAttribute *normalsAttr = [[MDLVertexAttribute alloc]
                                     initWithName:MDLVertexAttributeNormal
                                     format:MDLVertexFormatFloat3
                                     offset:sizeof(float) * 4 bufferIndex:0];
  [descriptor addOrReplaceAttribute:normalsAttr];
//  MDLVertexAttribute *textureAttr = [[MDLVertexAttribute alloc]
//                                     initWithName:MDLVertexAttributeTextureCoordinate
//                                     format:MDLVertexFormatFloat2
//                                     offset:sizeof(float) * 7 bufferIndex:0];
//  [descriptor addOrReplaceAttribute:textureAttr];
//[descriptor.layouts addObject:[[MDLVertexBufferLayout alloc] initWithStride:sizeof(float) * 7]];
  [descriptor setPackedStrides];
  [descriptor setPackedOffsets];

  NSString *node = [NSString stringWithFormat:@"%@.node", fileNamePattern];
  DDFileReader *reader = [[DDFileReader alloc] initWithFilePath:node];
  NSString *header = [reader readLine];
  NSUInteger positionsNumber = [[header componentsSeparatedByCharactersInSet:kCharacterSet][0]
                                integerValue];
  MTKMeshBufferAllocator *allocator = [[MTKMeshBufferAllocator alloc] initWithDevice:device];
  id<MDLMeshBuffer> vertexBuffer = [self loadPositionsWithReader:reader
                                                 positionsNumber:positionsNumber
                                                       allocator:allocator];

  NSString *face = [NSString stringWithFormat:@"%@.face", fileNamePattern];
  DDFileReader *faceReader = [[DDFileReader alloc] initWithFilePath:face];
  MDLSubmesh *submesh = [self loadFacesWithReader:faceReader allocator:allocator];
  MDLMesh *mdlMesh = [[MDLMesh alloc] initWithVertexBuffer:vertexBuffer vertexCount:positionsNumber
                                                descriptor:descriptor submeshes:@[submesh]];
  [mdlMesh addNormalsWithAttributeNamed:MDLVertexAttributeNormal
                        creaseThreshold:1.0];

  return mdlMesh;
}

- (id<MDLMeshBuffer>)loadPositionsWithReader:(DDFileReader *)reader
                             positionsNumber:(NSUInteger)positionsNumber
                                   allocator:(MTKMeshBufferAllocator *)allocator {
  id<MDLMeshBuffer> vertexBuffer = [allocator
                                    newBuffer:sizeof(float) * 7 * positionsNumber
                                    type:MDLMeshBufferTypeVertex];
  float *ptr = new float[7 * positionsNumber];

  for (NSUInteger i = 0; i < positionsNumber; ++i) {
    NSString *line = [reader readLine];
    NSArray<NSString *> *components = [self componentsFromString:line];
    float x = [components[1] floatValue];
    ptr[i * 7] = 10 * x;
    float y = [components[2] floatValue];
    ptr[i * 7 + 1] = 10 * y;
    float z = [components[3] floatValue];
    ptr[i * 7 + 2] = 10 * z;
    ptr[i * 7 + 3] = 1;
    ptr[i * 7 + 4] = 0;
    ptr[i * 7 + 5] = 0;
    ptr[i * 7 + 6] = 0;
  }

  [vertexBuffer fillData:[NSData dataWithBytes:ptr
                                        length:sizeof(float) * 7 * positionsNumber]
                  offset:0];
  delete [] ptr;

  return vertexBuffer;
}

- (NSArray<NSString *> *)componentsFromString:(NSString *)string {
  NSMutableArray<NSString *> *components =
      [[string componentsSeparatedByCharactersInSet:kCharacterSet] mutableCopy];
  [components removeObject:@""];
  return components;
}

- (MDLSubmesh *)loadFacesWithReader:(DDFileReader *)reader
                          allocator:(MTKMeshBufferAllocator *)allocator {
  NSUInteger facesNumber = [[self componentsFromString:[reader readLine]][0] integerValue];

  id<MDLMeshBuffer> meshBuffer = [allocator
                                  newBuffer:sizeof(uint32_t) * 3 * facesNumber
                                  type:MDLMeshBufferTypeIndex];
  MDLSubmesh *submesh = [[MDLSubmesh alloc] initWithIndexBuffer:meshBuffer indexCount:facesNumber * 3
                                                      indexType:MDLIndexBitDepthUInt32
                                                   geometryType:MDLGeometryTypeTriangles
                                                       material:nil];
  uint32_t *indices = new uint32_t[facesNumber * 3];
  for (NSUInteger i = 0; i < facesNumber; ++i) {
    NSArray<NSString *> *components = [self componentsFromString:[reader readLine]];
    uint32_t i1 = (uint32_t)[components[1] intValue];
    indices[i * 3] = i1;
    uint32_t i2 = (uint32_t)[components[2] intValue];
    indices[i * 3 + 1] = i2;
    uint32_t i3 = (uint32_t)[components[3] intValue];
    indices[i * 3 + 2] = i3;
  }
  NSData *data = [NSData dataWithBytes:indices length:sizeof(uint32_t) * 3 * facesNumber];
  [meshBuffer fillData:data offset:0];

  delete [] indices;
  return submesh;
}

@end

NS_ASSUME_NONNULL_END
