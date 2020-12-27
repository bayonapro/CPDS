#include <math.h>
#include <float.h>
#include <cuda.h>

__global__ void gpu_Heat (float *h, float *g, int N) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;

    bool fr = threadIdx.x == 0 && blockIdx.x == 0;
    bool fc = threadIdx.y == 0 && blockIdx.y == 0;

    if (i < N - 1 && j < N - 1 && !fr && !fc) {
        int k = i * N + j;
        //               left        top       right     bottom
        g[k] = 0.25 * (h[k - 1] + h[k - N] + h[k + 1] + h[k + N]);
    }
}

#if REDUCTION
__global__ void gpu_residual (float *h, float *g, float *r, int N) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;

    bool fr = threadIdx.x == 0 && blockIdx.x == 0;
    bool fc = threadIdx.y == 0 && blockIdx.y == 0;

    float diff;

    if (i < N - 1 && j < N - 1 && !fr && !fc) {
        int k = i * N + j;
        diff = g[k] - h[h];
        r[k] = diff * diff;
    }
}
#endif

#if REDUCTION == 1
__global__ void reduce0 (int *g_in, int *g_out) {
    extern __shared__ int sdata[];

    unsigned int tid = threadIdx.x;
    unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;

    sdata[tid] = i < N ? g_in[i] : 0.0;
    __syncthreads();

    for (unsigned int s = 1; s < blockDim.x; s *= 2) {
        if (tid % (2 * s) == 0) {
            sdata[tid] += sdata[tid + s]
        }
        __syncthreads();
    }

    if (tid == 0) g_out[blockIdx.x] = sdata[0];
}
#endif
