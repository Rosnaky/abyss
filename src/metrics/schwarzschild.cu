#include "schwarzschild.cuh"

namespace schwarzschild {

    static constexpr float DISK_TEMP_INNER_K = 10000.0f;
    static constexpr float DISK_TEMP_OUTER_K = 1500.0f;


    __device__ inline float rs(float M) {
        return 2.0f * M;
    }

    // d^2r/dλ^2 = -1.5 * r_s * h^2 / r^4
    // Derived in the attic
    __device__ inline float3 geodesicAccel(float3 pos, float3 vel, float M) {
        float r2 = dot(pos, pos);
        float r = sqrtf(r2);
        float r5 = r2 * r2 * r;

        // Angular momentum
        float3 L = cross(pos, vel);
        float L2 = dot(L, L);

        // Schwarzschild geodesic force term: -1.5 * r_s * h^2 / r^4 * pos / |pos|
        float coeff = -1.5f * rs(M) * L2 / r5;
        return pos * coeff;
    }

    // TODO: Add redshift
    __device__ inline TraceResult trace(
        float3 rayPos,
        float3 rayDir,
        float M,
        float diskInner,
        float diskOuter,
        int maxSteps,
        float dt
    ) {
        TraceResult result;
        result.color = make_float3(0.0f, 0.0f, 0.0f);
        result.hitHorizon = false;
        result.hitDisk = false;
        result.diskTemperature = 0.0f;

        float3 pos = rayPos;
        float3 vel = rayDir;
        float r_s = rs(M);

        for (int i = 0; i < maxSteps; i++) {
            float3 pos_prev = pos;
            float r = length(pos);

            // Hit horizon
            if (r - r_s < 1e-3f) {
                result.hitHorizon = true;
                result.color = make_float3(0, 0, 0);
                return result;
            }

            // Hit accretion disk
            float prevY = pos.y;
            float3 accel = geodesicAccel(pos, vel, M);

            // Use RK4 integraiton for better precision and accuracy
            float3 k1v = accel;
            float3 k1x = vel;

            // Take half step
            float3 p2 = pos + k1x * (dt * 0.5f);
            float3 v2 = vel + k1v * (dt * 0.5f);
            float3 k2v = geodesicAccel(p2, v2, M);
            float3 k2x = v2;

            // Take another half step
            float3 p3 = pos + k2x * (dt * 0.5f);
            float3 v3 = vel + k2v * (dt * 0.5f);
            float3 k3v = geodesicAccel(p3, v3, M);
            float3 k3x = v3;

            // Take a full step
            float3 p4 = pos + k3x * dt;
            float3 v4 = vel + k3v * dt;
            float3 k4v = geodesicAccel(p4, v4, M);
            float3 k4x = v4;

            // Get weighted average
            pos = pos + (k1x + k2x * 2.0f + k3x * 2.0f + k4x) * (dt/6.0f);
            vel = vel + (k1v + k2v * 2.0f + k3v * 2.0f + k4v) * (dt/6.0f);

            // Disk crossing
            // Since disk is infinitely thin, if it punched through, the photon switched y axis
            float newY = pos.y;
            if (prevY * newY < 0.0f) {
                float t = fabsf(prevY) / (fabsf(prevY) + fabsf(newY));
                float3 intersectPos = pos_prev + (pos - pos_prev) * t;
                float rDisk = length(make_float3(intersectPos.x, 0, intersectPos.z)); // y is zero
                if (rDisk > diskInner && rDisk < diskOuter) {
                    result.hitDisk = true;
                    // Temperature is hotter when closer, and is more blue
                    // Blackbody temperatures https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html
                    float temp_scalar = 1.0 - (rDisk - diskInner) / (diskOuter - diskInner);
                    result.diskTemperature = temp_scalar * (DISK_TEMP_INNER_K - DISK_TEMP_OUTER_K) + DISK_TEMP_OUTER_K;
                    result.color = getBlackbodyColor(result.diskTemperature);
                    return result;
                }
            }

            // Escaped to infinity
            if (r > 50.0f) {
                float3 d = normalize(vel);
                float star = powf(fmaxf(0.0f, sinf(d.x * 50.0f) * sinf(d.y * 50.0f) * sinf(d.z * 50.0f)), 100.0f);
                result.color = make_float3(star, star, star);
                return result;
            }
        }
    }

    // Implementation: https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html
    __device__ inline float3 getBlackbodyColor(float tempKelvin) {
        float tmp = tempKelvin / 100.0f;
        float red = 0.0f;
        float green = 0.0f;
        float blue = 0.0f;

        if (tmp < 66.0f) {
            red = 255;
        }
        else {
            red = tmp - 60;
            red = 329.698727446 * powf(red, -0.1332047592);
        }

        if (tmp <= 66.0f) {
            green = 99.4708025861f * logf(tmp) - 161.1195681661f;
        } else {
            green = tmp - 60.0f;
            green = 288.1221695283f * powf(green, -0.0755148492f);
        }

        if (tmp >= 66.0f) {
            blue = 255.0f;
        } else if (tmp <= 19.0f) {
            blue = 0.0f;
        } else {
            blue = tmp - 10.0f;
            blue = 138.5177312231f * logf(blue) - 305.0447927307f;
        }

        return make_float3(
            fmaxf(0.0f, fminf(255.0f, red)) / 255.0f,
            fmaxf(0.0f, fminf(255.0f, green)) / 255.0f,
            fmaxf(0.0f, fminf(255.0f, blue)) / 255.0f
        );
    }

}

