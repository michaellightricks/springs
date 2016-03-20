// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#ifndef Springs_VectorAlgebra_h
#define Springs_VectorAlgebra_h

#import <simd/simd.h>

typedef vector_float3 positionType;
typedef UInt16 indexType;

typedef struct SpringElementType {
  indexType idx1;
  indexType idx2;
  float restLength;
  float k;
} SpringElement;

typedef struct ThetraElementType {
  indexType idx1;
  indexType idx2;
  indexType idx3;
  indexType idx4;
} ThetraElement;

typedef struct TriangleElementType {
  indexType idx1;
  indexType idx2;
  indexType idx3;
} TriangleElement;

#endif
