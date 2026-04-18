#include "camera.cuh"

__device__ void generateRay(
    const Camera& cam,
    int x, int y,
    int width, int height,
    float3& rayOrigin,
    float3& rayDir
) {
    float aspect = (float)width / (float)height;
    float scale = tanf(cam.fov * 0.5f);

    float u = (2.0f * ((float)x + 0.5f) / (float)width  - 1.0f) * aspect * scale;
    float v = (2.0f * ((float)y + 0.5f) / (float)height - 1.0f) * scale;

    rayOrigin = cam.position;
    rayDir = normalize(cam.forward + cam.right * u + cam.up * v);
}
