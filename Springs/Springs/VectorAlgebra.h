// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#ifndef Springs_VectorAlgebra_h
#define Springs_VectorAlgebra_h

typedef struct point3DType {
  union {
    struct {
      float x;
      float y;
      float z;
    };
    
    float v[3];
  };
} Point3D;

#endif
