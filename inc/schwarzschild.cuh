#pragma once
#include "metric.cuh"
#include "camera.cuh"
#include "metrics.cuh"

namespace schwarzschild {
    __device__ inline float rs(float M);
    __device__ inline float3 geodesicAccel(float3 pos, float3 vel, float M);
    __device__ inline TraceResult trace(
        float3 rayPos,
        float3 rayDir,
        float M,
        float diskInner,
        float diskOuter,
        int maxSteps,
        float dt
    );
    __device__ inline float3 getBlackbodyColor(float tempKelvin);
}
