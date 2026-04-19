#include "camera.cuh"
#include "schwarzschild.cuh"
#include "render_kernel.cuh"

__global__ void renderKernel(
    cudaSurfaceObject_t surface,
    int width,
    int height,
    Camera cam,
    float time
) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    float3 rayOrigin, rayDir;
    generateRay(cam, x, y, width, height, rayOrigin, rayDir);

    float M = 1.0f;
    float diskInner = 3.0f * schwarzschild::rs(M);
    float diskOuter = 4.0f * schwarzschild::rs(M);
    int maxSteps = 1000;
    float dt = 0.05f;

    TraceResult result = schwarzschild::trace(
        rayOrigin, rayDir, M, diskInner, diskOuter, maxSteps, dt
    );

    float4 color = make_float4(result.color.x, result.color.y, result.color.z, 1.0);
    surf2Dwrite(color, surface, x * sizeof(float4), y);
}
