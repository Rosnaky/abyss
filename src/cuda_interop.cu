#pragma once
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <cuda_runtime.h>
#include <cuda_gl_interop.h>
#include <iostream>
#include "render_kernel.cuh"
#include "camera.cuh"

static cudaGraphicsResource* cudaTexResource = nullptr;

void initCudaInterop(unsigned int glTexture) {
    cudaError_t err = cudaGraphicsGLRegisterImage(
        &cudaTexResource,
        glTexture,
        GL_TEXTURE_2D,
        cudaGraphicsRegisterFlagsSurfaceLoadStore
    );

    if (err != cudaSuccess) {
        std::cerr << "cudaGraphicsGLRegisterImage failed" << std::endl;
    }
}

void renderFrame(int width, int height, float time) {
    cudaGraphicsMapResources(1, &cudaTexResource, 0);

    cudaArray* cudaArr = nullptr;
    cudaGraphicsSubResourceGetMappedArray(&cudaArr, cudaTexResource, 0, 0);

    cudaResourceDesc resDesc = {};
    resDesc.resType = cudaResourceTypeArray;
    resDesc.res.array.array = cudaArr;

    cudaSurfaceObject_t surface = 0;
    cudaCreateSurfaceObject(&surface, &resDesc);

    // Orbit around black hole
    Camera cam;
    float angle = time * 0.1f;
    float camDist = 15.0f;
    float3 target = make_float3(0.0f, 0.0f, 0.0f);
    float3 worldUp = make_float3(0.0f, 1.0f, 0.0f);

    cam.position = make_float3(camDist * cosf(angle), 3.0f, camDist * sinf(angle));
    cam.forward = normalize(target - cam.position);
    cam.right = normalize(cross(cam.forward, worldUp));
    cam.up = cross(cam.right, cam.forward);

    cam.fov = 80.0f * 3.14f / 180.0f;

    dim3 block(16, 16);
    dim3 grid((width + block.x - 1) / block.x, (height + block.y - 1) / block.y);
    renderKernel<<<grid, block>>>(surface, width, height, cam, time);

    cudaDeviceSynchronize();
    cudaDestroySurfaceObject(surface);
    cudaGraphicsUnmapResources(1, &cudaTexResource, 0);
}

void cleanupCudaInterop() {
    if (cudaTexResource) {
        cudaGraphicsUnregisterResource(cudaTexResource);
        cudaTexResource = nullptr;
    }
}
