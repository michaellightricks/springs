// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "TetgenFileReader.h"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import "DDFileReader.h"
#import "SystemState.h"

NS_ASSUME_NONNULL_BEGIN

NSCharacterSet *kCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" \t"];

@interface TetgenFileReader () {
  std::vector<SpringElement> _springs;
}

@property (readonly, nonatomic) id<MTLDevice> device;

@property (readonly, nonatomic) NSString *prefix;

@property (readonly, nonatomic) NSUInteger positionsNumber;

@end

@implementation TetgenFileReader

@synthesize mesh = _mesh;
//@synthesize vertexBuffer = _vertexBuffer;
//@synthesize submesh = _submesh;
@synthesize state = _state;

- (instancetype)initWithFilePathPrefix:(NSString *)prefix device:(id<MTLDevice>)device {
  if (self = [super init]) {
    _device = device;
    _prefix = prefix;
  }

  return self;
}

- (MTKMesh *)mesh {
  if (_mesh == nil) {
    MDLMesh *mdlMesh = [self loadMesh:self.prefix device:self.device];
    NSError *error;
    _mesh = [[MTKMesh alloc] initWithMesh:mdlMesh device:self.device error:&error];
  }
  return _mesh;
}

//- (id<MTLBuffer>)vertexBuffer {
//  if (!_vertexBuffer) {
//  NSString *node = [NSString stringWithFormat:@"%@.node", self.prefix];
//  DDFileReader *reader = [[DDFileReader alloc] initWithFilePath:node];
//  NSString *header = [reader readLine];
//  _positionsNumber = [[header componentsSeparatedByCharactersInSet:kCharacterSet][0]
//                      integerValue];
//  MTKMeshBufferAllocator *allocator = [[MTKMeshBufferAllocator alloc] initWithDevice:self.device];
//  _vertexBuffer = [self loadPositionsWithReader:reader
//                                positionsNumber:self.positionsNumber
//                                      allocator:allocator];
//  }
//  return _vertexBuffer;
//}

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
  [descriptor setPackedStrides];
  [descriptor setPackedOffsets];

  NSString *node = [NSString stringWithFormat:@"%@.node", fileNamePattern];
  DDFileReader *reader = [[DDFileReader alloc] initWithFilePath:node];
  NSString *header = [reader readLine];
  _positionsNumber = [[header componentsSeparatedByCharactersInSet:kCharacterSet][0]
                      integerValue];
  MTKMeshBufferAllocator *allocator = [[MTKMeshBufferAllocator alloc] initWithDevice:device];
  id<MDLMeshBuffer> vertexBuffer = [self loadPositionsWithReader:reader
                                                 positionsNumber:self.positionsNumber
                                                       allocator:allocator];

  NSString *face = [NSString stringWithFormat:@"%@.face", fileNamePattern];
  DDFileReader *faceReader = [[DDFileReader alloc] initWithFilePath:face];
  MDLSubmesh *submesh = [self loadFacesWithReader:faceReader allocator:allocator];
  MDLMesh *mdlMesh = [[MDLMesh alloc] initWithVertexBuffer:vertexBuffer
                                               vertexCount:self.positionsNumber
                                                descriptor:descriptor submeshes:@[submesh]];

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
    ptr[i * 7 + 4] = 1;
    ptr[i * 7 + 5] = 1;
    ptr[i * 7 + 6] = 1;
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
  MDLSubmesh *submesh = [[MDLSubmesh alloc] initWithIndexBuffer:meshBuffer
                                                     indexCount:facesNumber * 3
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

- (std::vector<SpringElement> &)springs {
  if (_springs.size() == 0) {
    [self fillSprings:_springs];
  }

  return _springs;
}

- (void)fillSprings:(std::vector<SpringElement> &)springs {
  NSString *fileName = [NSString stringWithFormat:@"%@.edge", self.prefix];
  DDFileReader *reader = [[DDFileReader alloc] initWithFilePath:fileName];
  NSArray<NSString *> *components = [self componentsFromString:[reader readLine]];
  NSUInteger springsNumber = [components[0] integerValue];
  springs.reserve(springsNumber);

  MTKMeshBuffer *vertexBuffer = self.mesh.vertexBuffers[0];
  uint8_t *ptr = (uint8_t *)[vertexBuffer.buffer contents] + vertexBuffer.offset;
  float *positions = (float *)ptr;
  for (int i = 0; i < springsNumber; ++i) {
    NSArray<NSString *> *springComponents = [self componentsFromString:[reader readLine]];
    NSUInteger idx1 = [springComponents[1] integerValue];
    NSUInteger idx2 = [springComponents[2] integerValue];

    simd::float4 position1 = *(simd::float4 *)(positions + idx1 * 7);
    simd::float4 position2 = *(simd::float4 *)(positions + idx2 * 7);

    float restLength = simd::distance(position1, position2);

    SpringElement element;
    element.idx1 = idx1;
    element.idx2 = idx2;
    element.restLength = restLength;
    element.k = 500;
    springs.push_back(element);
  }
}

- (SystemState *)state {
  if (!_state) {
    _state = [[SystemState alloc] initWithPositions:self.mesh.vertexBuffers[0].buffer
                                             offset:0 stride:sizeof(float) * 7
                                             device:self.device
                                        vertexCount:self.positionsNumber];
  }

  return _state;
}

@end

NS_ASSUME_NONNULL_END
