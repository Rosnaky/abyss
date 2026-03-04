#pragma once
#include "camera.cuh"

__global__ void renderKernel(
    cudaSurfaceObject_t surface,
    int width,
    int height,
    Camera cam,
    float time
);
