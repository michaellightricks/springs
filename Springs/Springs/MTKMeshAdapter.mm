// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "MTKMeshAdapter.h"
#import "Definitions.h"

#include <vector>

NS_ASSUME_NONNULL_BEGIN

typedef struct VertexType {
  std::vector<SpringElement> springs;
  positionType pos;
} Vertex;

@interface MTKMeshAdapter() {
  std::vector<SpringElement> springs;
  std::vector<Vertex> vertices;
  std::vector<TriangleElement> triangles;
  
  size_t maxSpringsCount;
}

@property (nonatomic) float K;
@property (strong, nonatomic) MTKMesh *mesh;

@end

BOOL hasSpring(Vertex& v, SpringElement& elem) {
  for (int i = 0; i < v.springs.size(); ++i) {
    SpringElement& vElem = v.springs[i];
    if ((vElem.idx1 == elem.idx1 &&
        vElem.idx2 == elem.idx2) ||
       (vElem.idx1 == elem.idx2 &&
        vElem.idx2 == elem.idx1)) {
      return YES;
    }
  }
  
  return NO;
}


@implementation MTKMeshAdapter

- (instancetype) initWithMesh:(MTKMesh *)mesh device:(id<MTLDevice>)device {
  if (self = [super init]) {
    self.mesh = mesh;
    self.K = 500;
    vertices.resize(mesh.vertexCount + 1);
    MTKSubmesh *submesh = mesh.submeshes[0];

    assert(submesh.indexType == MTLIndexTypeUInt16);

    self.positionsBuffer = [self createPositionsBuffer:device];
    
    [self addSpringsFromTriangles:submesh];
    [self addSpringsToCentroid:submesh];

    _springsCount = springs.size();
    _verticesCount = vertices.size();
    
    self.trianglesBuffer = submesh.indexBuffer.buffer;
    self.springsBuffer = [self createSpringElementsBuffer:device];
  }
  
  return self;
}

- (SpringElement *)springsPtr {
  return &springs.front();
}

- (void)addSpringsToCentroid:(MTKSubmesh *)submesh {
  for (int i = 0; i < submesh.mesh.vertexCount; ++i) {
    SpringElement element = [self getSpringElementFromIdx1:i idx2:(submesh.mesh.vertexCount)
                                                         k:(self.K * 2)];
    [self addSpring:element];
  }
}

- (void)addSpringsFromTriangles:(MTKSubmesh *)submesh {
  Byte *tempPtr = (Byte *)submesh.indexBuffer.map.bytes;
  indexType *ptr = (indexType *)(tempPtr + submesh.indexBuffer.offset);

  for (int i = 0; i < submesh.indexCount / 3; ++i) {
    TriangleElement triangle;
    triangle.idx1 = *(ptr++);
    triangle.idx2 = *(ptr++);
    triangle.idx3 = *(ptr++);
    
    triangles.push_back(triangle);
    
    SpringElement elements[3];
    
    elements[0] = [self getSpringElementFromIdx1:triangle.idx1 idx2:triangle.idx2 k:self.K];
    elements[1] = [self getSpringElementFromIdx1:triangle.idx1 idx2:triangle.idx3 k:self.K];
    elements[2] = [self getSpringElementFromIdx1:triangle.idx2 idx2:triangle.idx3 k:self.K];
    
    for (int elem = 0; elem < 3; ++elem) {
      SpringElement& spring = elements[elem];
      [self addSpring:spring];
    }
  }
}

- (void)addSpring:(SpringElement)spring {
  Vertex& v1 = vertices[spring.idx1];
  Vertex& v2 = vertices[spring.idx2];
  
  if (!hasSpring(v1, spring) && !hasSpring(v2, spring)) {
    v1.springs.push_back(spring);
    SpringElement opposite = spring;
    uint idx = opposite.idx1;
    opposite.idx1 = opposite.idx2;
    opposite.idx2 = idx;
    
    v2.springs.push_back(opposite);
    springs.push_back(spring);
    
    size_t maxSize = MAX(v1.springs.size(), v2.springs.size());
    maxSpringsCount = MAX(maxSpringsCount, maxSize);
  }
}

- (SpringElement)getSpringElementFromIdx1:(uint)idx1 idx2:(uint)idx2 k:(float)k {
  SpringElement elem;
  elem.idx1 = idx1;
  elem.idx2 = idx2;
  elem.k = k;
  
  positionType p1 = [self getPositionAtIndex:idx1];
  
  positionType p2 = [self getPositionAtIndex:idx2];
  
  elem.restLength = simd::distance(p1, p2);
  
  return elem;
}

- (positionType)getPositionAtIndex:(indexType)idx {
  Byte *ptr = (Byte *)[self.positionsBuffer contents];
  
  positionType *posPtr = (positionType *)(ptr + sizeof(positionType) * idx);
  return *posPtr;
}

- (id<MTLBuffer>)createPositionsBuffer:(id<MTLDevice>)device {
  id<MTLBuffer> buffer = [device newBufferWithLength:sizeof(positionType) * self.mesh.vertexCount options:0];

  MDLVertexAttribute *attr = [self.mesh.vertexDescriptor attributeNamed:MDLVertexAttributePosition];
  
  NSUInteger stride = self.mesh.vertexDescriptor.layouts[attr.bufferIndex].stride;
  MTKMeshBuffer *meshBuffer = self.mesh.vertexBuffers[attr.bufferIndex];
  
  Byte *ptr = (Byte *)[meshBuffer.buffer contents] + meshBuffer.offset;
  positionType *target = (positionType *)[buffer contents];
  
  NSUInteger idx = 0;
  positionType centroid = {0.0, 0.0, 0.0, 0.0};
  
  while (idx < self.mesh.vertexCount) {
    positionType *source = (positionType *)(ptr + stride * idx++);
    positionType pos = *source;
    pos.w = 1;
    
    centroid += pos;
    
    *(target++) = pos;
  }
  centroid = centroid / self.mesh.vertexCount;
  centroid.w = 1;
  
  *target = centroid;
  
  return buffer;
}

- (id<MTLBuffer>)createSpringElementsBuffer:(id<MTLDevice>)device {
  // springs buffer layout is vertices.size X (maxSpringsCount + 1) matrix
  // first row is springs count for each vector
  
  size_t height = (maxSpringsCount + 1);
  
  id<MTLBuffer> buffer =
  [device newBufferWithLength:height * vertices.size() * sizeof(indexType) options:0];
  
  indexType *bufPtr = (indexType *)[buffer contents];
  
  for (int i = 0; i < vertices.size(); ++i) {
    Vertex& v = vertices[i];
    
    bufPtr[i] = v.springs.size();
    
    for (int j = 1; j < height; ++j) {
      if (j < height) {
        bufPtr[j * vertices.size() + i] = v.springs[j].idx2;
      }
    }
  }
  
  return buffer;
}

- (id<MTLBuffer>)createSpringKBuffer:(id<MTLDevice>)device {
  // K buffer is maxSpringsCount * vertices.size() matrix
  // so for each vertex and for each its spring we store its K value
  
  size_t height = maxSpringsCount;
  
  id<MTLBuffer> buffer =
  [device newBufferWithLength:height * vertices.size() * sizeof(indexType) options:0];
  
  indexType *bufPtr = (indexType *)[buffer contents];
  
  for (int i = 0; i < vertices.size(); ++i) {
    Vertex& v = vertices[i];
    
    for (int j = 0; j < height; ++j) {
      if (j < height) {
        bufPtr[j * vertices.size() + i] = v.springs[j].k;
      }
    }
  }
  
  return buffer;
}

@end

NS_ASSUME_NONNULL_END
