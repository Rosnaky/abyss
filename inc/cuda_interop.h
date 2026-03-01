#pragma once

void initCudaInterop(unsigned int glTexture);
void renderFrame(int width, int height, float time);
void cleanupCudaInterop();
