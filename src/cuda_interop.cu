#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <cuda_runtime.h>
#include <cuda_gl_interop.h>
#include <iostream>

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

__global__ void testKernel(cudaSurfaceObject_t surface, int width, int height, float time) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= width || y >= height) return;

    float u = (float)x / (float)width;
    float v = (float)y / (float)height;

    float4 color = make_float4(u, v, sinf(time) * 0.5f, 1.0f);
    surf2Dwrite(color, surface, x * sizeof(float4), y);
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

    dim3 block(16, 16);
    dim3 grid((width + block.x - 1) / block.x, (height + block.y - 1) / block.y);
    testKernel<<<grid, block>>>(surface, width, height, time);

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
