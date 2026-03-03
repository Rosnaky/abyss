#pragma once
#include <cuda_runtime.h>

struct Camera {
    float3 position;
    float3 forward;
    float3 right;
    float3 up;
    float fov;
};

__device__ inline float3 operator+(float3 a, float3 b) {
    return make_float3(a.x + b.x, a.y + b.y, a.z + b.z);
}
__device__ inline float3 operator-(float3 a, float3 b) {
    return make_float3(a.x - b.x, a.y - b.y, a.z - b.z);
}
__device__ inline float3 operator*(float3 a, float s) {
    return make_float3(a.x * s, a.y * s, a.z * s);
}
__device__ inline float3 operator*(float s, float3 a) {
    return a * s;
}
__device__ inline float dot(float3 a, float3 b) {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}
__device__ inline float3 cross(float3 a, float3 b) {
    return make_float3(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    );
}
__device__ inline float length(float3 a) {
    return sqrtf(dot(a, a));
}
__device__ inline float3 normalize(float3 a) {
    return a * (1.0f / length(a));
}

__device__ void generateRay(
    const Camera& cam,
    int x, int y,
    int width, int height,
    float3& rayOrigin,
    float3& rayDir
);