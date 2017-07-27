//
//  GameViewController.m
//  Springs
//
//  Created by Michael Kupchick on 3/6/16.
//  Copyright © 2016 Michael Kupchick. All rights reserved.
//

#import "GameViewController.h"
#import "SharedStructures.h"
#import <GLKit/GLKit.h>
#import <SceneKit/SceneKit.h>
#import <SceneKit/ModelIO.h>


#import "CPUSpringPhysicalSystem.h"

@import simd;
@import ModelIO;

// The max number of command buffers in flight
static const NSUInteger kMaxInflightBuffers = 3;

// Max API memory buffer size.
static const size_t kMaxBytesPerFrame = 1024*1024;

@implementation GameViewController
{
  // view
  MTKView *_view;
  
  // controller
  dispatch_semaphore_t _inflight_semaphore;
  id <MTLBuffer> _dynamicConstantBuffer;
  uint8_t _constantDataBufferIndex;
  
  // renderer
  id <MTLDevice> _device;
  id <MTLCommandQueue> _commandQueue;
  id <MTLLibrary> _defaultLibrary;
  id <MTLRenderPipelineState> _pipelineState;
  id <MTLComputePipelineState> _computePipelineState;
  id <MTLDepthStencilState> _depthState;
  
  // uniforms
  matrix_float4x4 _projectionMatrix;
  matrix_float4x4 _viewMatrix;
  uniforms_t _uniform_buffer;
  float _rotation;
  
  // meshes
  MTKMesh *_boxMesh;
  
  CPUSpringPhysicalSystem *_physicalSystem;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  _constantDataBufferIndex = 0;
  _inflight_semaphore = dispatch_semaphore_create(3);
  
  [self _setupMetal];
  if(_device)
  {
      [self _setupView];
      [self _loadAssets];
      [self _initPhysicalSystem];
      [self _initPipelineDescriptor];
      [self _reshape];
  }
  else // Fallback to a blank UIView, an application could also fallback to OpenGL ES here.
  {
      NSLog(@"Metal is not supported on this device");
      self.view = [[UIView alloc] initWithFrame:self.view.frame];
  }
  
  UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
  [self.view addGestureRecognizer:panRecognizer];
}

- (void)_setupView
{
  _view = (MTKView *)self.view;
  _view.device = _device;
  _view.delegate = self;
  
  // Setup the render target, choose values based on your app
  _view.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
}

- (void)_setupMetal
{
  // Set the view to use the default device
  _device = MTLCreateSystemDefaultDevice();
  
  // Create a new command queue
  _commandQueue = [_device newCommandQueue];
  
  // Load all the shader files with a metal file extension in the project
  _defaultLibrary = [_device newDefaultLibrary];
  
  // Allocate one region of memory for the uniform buffer
  _dynamicConstantBuffer = [_device newBufferWithLength:kMaxBytesPerFrame options:0];
  _dynamicConstantBuffer.label = @"UniformBuffer";
}

- (void)_initPhysicalSystem {
  MTKMeshAdapter *adapter = [[MTKMeshAdapter alloc] initWithMesh:mesh device:device];

  SystemState *state = [[SystemState alloc] initWithPositions:adapter.positionsBuffer
                                                       length:mesh.vertexBuffers[0].length
                                                       offset:mesh.vertexBuffers[0].offset
                                                       device:device
                                                  vertexCount:adapter.verticesCount];

  _physicalSystem = [[CPUSpringPhysicalSystem alloc] initWithState:state
                                                           springs:adapter.springs];
}

- (void)_loadAssets
{
  // Generate meshes
  MDLMesh *mdl = [MDLMesh newIcosahedronWithRadius:0.5 inwardNormals:NO
                                         allocator:[[MTKMeshBufferAllocator alloc] initWithDevice:_device]];

  NSError *error;
  _boxMesh = [[MTKMesh alloc] initWithMesh:mdl device:_device error:&error];

  MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
  depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
  depthStateDesc.depthWriteEnabled = YES;
  _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

  id<MTLFunction> kernelFunction = [_defaultLibrary newFunctionWithName:@"kernel_function"];

  _computePipelineState = [_device newComputePipelineStateWithFunction:kernelFunction error:&error];
}

- (void)_initPipelineDescriptor {

  // Load the fragment program into the library
  id <MTLFunction> fragmentProgram = [_defaultLibrary newFunctionWithName:@"lighting_fragment"];
  
  // Load the vertex program into the library
  id <MTLFunction> vertexProgram = [_defaultLibrary newFunctionWithName:@"lighting_vertex"];

  MTLVertexDescriptor *vertexDescriptor = [self createDescriptor];
  
  // Create a reusable pipeline state
  MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
  pipelineStateDescriptor.label = @"MyPipeline";
  pipelineStateDescriptor.sampleCount = _view.sampleCount;
  pipelineStateDescriptor.vertexFunction = vertexProgram;
  pipelineStateDescriptor.fragmentFunction = fragmentProgram;
  pipelineStateDescriptor.vertexDescriptor = vertexDescriptor;
  pipelineStateDescriptor.colorAttachments[0].pixelFormat = _view.colorPixelFormat;
  pipelineStateDescriptor.depthAttachmentPixelFormat = _view.depthStencilPixelFormat;
  pipelineStateDescriptor.stencilAttachmentPixelFormat = _view.depthStencilPixelFormat;
  
  NSError *error = NULL;
  _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                           error:&error];
  if (!_pipelineState) {
    NSLog(@"Failed to created pipeline state, error %@", error);
  }
}

- (MTLVertexDescriptor *)createDescriptor {
  MTLVertexDescriptor *result = [[MTLVertexDescriptor alloc] init];
  
  // layout we will have 2 separate buffers
  // buffer for positions - dynamically updated each frame
  // buffer for normals and texture coordinates - static
  MTLVertexBufferLayoutDescriptor *posLayout = [[MTLVertexBufferLayoutDescriptor alloc] init];
  posLayout.stride = sizeof(positionType);
  posLayout.stepRate = 1;
  posLayout.stepFunction = MTLVertexStepFunctionPerVertex;

  [result.layouts setObject:posLayout atIndexedSubscript:0];
  
  MTLVertexBufferLayoutDescriptor *normalsLayout = [[MTLVertexBufferLayoutDescriptor alloc] init];
  normalsLayout.stride = sizeof(float) * 6 + sizeof(vector_float2);
  normalsLayout.stepRate = 1;
  normalsLayout.stepFunction = MTLVertexStepFunctionPerVertex;
  
  [result.layouts setObject:normalsLayout atIndexedSubscript:1];

  // positions
  MTLVertexAttributeDescriptor *posAttrDesc = [[MTLVertexAttributeDescriptor alloc] init];
  posAttrDesc.bufferIndex = 0;
  posAttrDesc.offset = 0;
  posAttrDesc.format = MTLVertexFormatFloat4;
  
  [result.attributes setObject:posAttrDesc  atIndexedSubscript:0];
  
  // normals
  MTLVertexAttributeDescriptor *normalsAttrDesc = [[MTLVertexAttributeDescriptor alloc] init];
  normalsAttrDesc.bufferIndex = 1;
  normalsAttrDesc.offset = sizeof(float) * 3;
  normalsAttrDesc.format = MTLVertexFormatFloat3;
  
  
  [result.attributes setObject:normalsAttrDesc  atIndexedSubscript:1];
  
  return result;
}

- (void)_render
{
  dispatch_semaphore_wait(_inflight_semaphore, DISPATCH_TIME_FOREVER);
  
  [self _update];

  [self _compute];
  
  // Create a new command buffer for each renderpass to the current drawable
  id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  commandBuffer.label = @"MyCommand";

  // Call the view's completion handler which is required by the view since it will signal its semaphore and set up the next buffer
  __block dispatch_semaphore_t block_sema = _inflight_semaphore;
  [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
      dispatch_semaphore_signal(block_sema);
  }];

  // Obtain a renderPassDescriptor generated from the view's drawable textures
  MTLRenderPassDescriptor* renderPassDescriptor = _view.currentRenderPassDescriptor;

  if(renderPassDescriptor != nil) // If we have a valid drawable, begin the commands to render into it
  {
      // Create a render command encoder so we can render into something
      id <MTLRenderCommandEncoder> renderEncoder =
          [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
      renderEncoder.label = @"MyRenderEncoder";
      [renderEncoder setDepthStencilState:_depthState];
      
      // Set context state
      [renderEncoder pushDebugGroup:@"DrawCube"];
      [renderEncoder setRenderPipelineState:_pipelineState];
      [renderEncoder setVertexBuffer:_physicalSystem.state.positions
                              offset:_physicalSystem.state.positionsOffset atIndex:0 ];
      [renderEncoder setVertexBuffer:_boxMesh.vertexBuffers[0].buffer
                              offset:_boxMesh.vertexBuffers[0].offset atIndex:1 ];
      [renderEncoder setVertexBuffer:_dynamicConstantBuffer
                              offset:(sizeof(uniforms_t) * _constantDataBufferIndex) atIndex:2 ];
      
      MTKSubmesh* submesh = _boxMesh.submeshes[0];
      // Tell the render context we want to draw our primitives
      [renderEncoder drawIndexedPrimitives:submesh.primitiveType indexCount:submesh.indexCount
                                 indexType:submesh.indexType indexBuffer:submesh.indexBuffer.buffer
                         indexBufferOffset:submesh.indexBuffer.offset];

      [renderEncoder popDebugGroup];
      
      // We're done encoding commands
      [renderEncoder endEncoding];
      
      // Schedule a present once the framebuffer is complete using the current drawable
      [commandBuffer presentDrawable:_view.currentDrawable];
  }

  // The render assumes it can now increment the buffer index and that the previous index won't be touched until we cycle back around to the same index
  _constantDataBufferIndex = (_constantDataBufferIndex + 1) % kMaxInflightBuffers;

  // Finalize rendering here & push the command buffer to the GPU
  [commandBuffer commit];
}

- (void)_compute
{
  [_physicalSystem integrateTimeStep];
}

- (void)_reshape
{
  // When reshape is called, update the view and projection matricies since this means the view orientation or size changed
  float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
  _projectionMatrix = matrix_from_perspective_fov_aspectLH(65.0f * (M_PI / 180.0f), aspect, 0.1f, 100.0f);
  
  _viewMatrix = matrix_identity_float4x4;
}

- (void)_update
{
  matrix_float4x4 base_model = matrix_multiply(matrix_from_translation(0.0f, 0.0f, 5.0f),
                                               matrix_from_rotation(_rotation, 0.0f, 1.0f, 0.0f));
  matrix_float4x4 base_mv = matrix_multiply(_viewMatrix, base_model);
  matrix_float4x4 modelViewMatrix = matrix_multiply(base_mv, matrix_identity_float4x4);//matrix_from_rotation(_rotation, 1.0f, 1.0f, 1.0f));
  
  
  // Load constant buffer data into appropriate buffer at current index
  uniforms_t *uniforms = &((uniforms_t *)[_dynamicConstantBuffer contents])[_constantDataBufferIndex];

  uniforms->normal_matrix = matrix_invert(matrix_transpose(modelViewMatrix));
  uniforms->modelview_projection_matrix = matrix_multiply(_projectionMatrix, modelViewMatrix);    
 
}

- (GLKQuaternion) rotateQuaternionWithVector:(CGPoint)delta
{
  GLKQuaternion quarternion =  GLKQuaternionMake(0.f, 0.f, 0.f, 1.f);
  GLKVector3 up = GLKVector3Make(0.f, 1.f, 0.f);
  GLKVector3 right = GLKVector3Make(-1.f, 0.f, 0.f);
  
  up = GLKQuaternionRotateVector3( GLKQuaternionInvert(quarternion), up );
  quarternion = GLKQuaternionMultiply(quarternion, GLKQuaternionMakeWithAngleAndVector3Axis(delta.x * 3.14f, up));
  
  right = GLKQuaternionRotateVector3( GLKQuaternionInvert(quarternion), right );
  quarternion = GLKQuaternionMultiply(quarternion, GLKQuaternionMakeWithAngleAndVector3Axis(delta.y * 3.14f, right));
  
  return quarternion;
}

-(void)onPan:(UIGestureRecognizer*)gestureRecognizer {
  UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)gestureRecognizer;
  CGPoint p = [pan translationInView:self.view];
  _rotation = p.x * 3.14 / 200.0;
}

// Called whenever view changes orientation or layout is changed
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
  [self _reshape];
}


// Called whenever the view needs to render
- (void)drawInMTKView:(nonnull MTKView *)view
{
  @autoreleasepool {
    [self _compute];
    [self _render];
  }
}

#pragma mark Utilities

static matrix_float4x4 matrix_from_perspective_fov_aspectLH(const float fovY, const float aspect, const float nearZ, const float farZ)
{
  float yscale = 1.0f / tanf(fovY * 0.5f); // 1 / tan == cot
  float xscale = yscale / aspect;
  float q = farZ / (farZ - nearZ);
  
  matrix_float4x4 m = {
      .columns[0] = { xscale, 0.0f, 0.0f, 0.0f },
      .columns[1] = { 0.0f, yscale, 0.0f, 0.0f },
      .columns[2] = { 0.0f, 0.0f, q, 1.0f },
      .columns[3] = { 0.0f, 0.0f, q * -nearZ, 0.0f }
  };
  
  return m;
}

static matrix_float4x4 matrix_from_translation(float x, float y, float z)
{
  matrix_float4x4 m = matrix_identity_float4x4;
  m.columns[3] = (vector_float4) { x, y, z, 1.0 };
  return m;
}

static matrix_float4x4 matrix_from_rotation(float radians, float x, float y, float z)
{
  vector_float3 v = vector_normalize(((vector_float3){x, y, z}));
  float cos = cosf(radians);
  float cosp = 1.0f - cos;
  float sin = sinf(radians);
  
  matrix_float4x4 m = {
      .columns[0] = {
          cos + cosp * v.x * v.x,
          cosp * v.x * v.y + v.z * sin,
          cosp * v.x * v.z - v.y * sin,
          0.0f,
      },
      
      .columns[1] = {
          cosp * v.x * v.y - v.z * sin,
          cos + cosp * v.y * v.y,
          cosp * v.y * v.z + v.x * sin,
          0.0f,
      },
      
      .columns[2] = {
          cosp * v.x * v.z + v.y * sin,
          cosp * v.y * v.z - v.x * sin,
          cos + cosp * v.z * v.z,
          0.0f,
      },
      
      .columns[3] = { 0.0f, 0.0f, 0.0f, 1.0f
      }
  };
  return m;
}

@end

