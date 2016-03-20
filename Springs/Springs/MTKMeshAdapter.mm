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

@end

BOOL hasSpring(Vertex& v, SpringElement& elem) {
  for (int i = 0; i < v.springs.size(); ++i) {
    SpringElement& vElem = v.springs[i];
    if (vElem.idx1 == elem.idx1 &&
        vElem.idx2 == elem.idx2) {
      return YES;
    }
  }
  
  return NO;
}

SpringElement getSpringElement(uint idx1, uint idx2, float k) {
  SpringElement elem;
  elem.idx1 = idx1;
  elem.idx2 = idx2;
  elem.k = k;
  
  return elem;
}

@implementation MTKMeshAdapter

- (instancetype) initWithMesh:(MTKMesh *)mesh device:(id<MTLDevice>)device {

  if (self = [super init]) {
    vertices.resize(mesh.vertexCount);
    MTKSubmesh *submesh = mesh.submeshes[0];

    assert(submesh.indexType == MTLIndexTypeUInt16);
    [self addSpringsFromTriangles:submesh];
    
    self.trianglesBuffer = submesh.indexBuffer.buffer;
    self.springsBuffer = [self createSpringElementsBuffer:device];
    self.positionsBuffer = mesh.vertexBuffers[0].buffer;
    
    _verticesCount = mesh.vertexCount;
  }
  
  return self;
}

- (SpringElement *)springsPtr {
  return &springs.front();
}

-(void)addSpringsFromTriangles:(MTKSubmesh *)submesh {
  for (int i = 0; i < submesh.indexCount; ++i) {
    indexType *ptr = (indexType *)[submesh.indexBuffer.buffer contents];
    ptr = ptr + i;
    TriangleElement triangle;
    triangle.idx1 = *(ptr++);
    triangle.idx2 = *(ptr++);
    triangle.idx3 = *(ptr++);
    
    triangles.push_back(triangle);
    
    SpringElement elements[3];
    
    elements[0] = getSpringElement(triangle.idx1, triangle.idx2, self.K);
    elements[1] = getSpringElement(triangle.idx1, triangle.idx3, self.K);
    elements[2] = getSpringElement(triangle.idx2, triangle.idx3, self.K);
    
    for (int elem = 0; elem < 3; ++elem) {
      SpringElement& spring = elements[elem];
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
  }
  
  _springsCount = springs.size();
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
