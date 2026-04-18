#pragma once
#include "camera.cuh"
#include "metrics.cuh"

namespace schwarzschild {
    __device__ float rs(float M);
    __device__ float3 geodesicAccel(float3 pos, float3 vel, float M);
    __device__ TraceResult trace(
        float3 rayPos,
        float3 rayDir,
        float M,
        float diskInner,
        float diskOuter,
        int maxSteps,
        float dt
    );
    __device__ float3 getBlackbodyColor(float tempKelvin);
}
