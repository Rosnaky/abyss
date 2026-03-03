#pragma once
#include <cuda_runtime.h>

struct TraceResult {
    float3 color;
    bool hitHorizon;
    bool hitDisk;
    float diskTemperature;
};

struct GeodesicState {
    float3 pos;
    float3 val; 
};
