#include <math.h>
#include <float.h>
#include <cuda.h>
#include <stdio.h>

__global__ void gpu_Heat (float *h, float *g, float *r, int N) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;

    bool fr = threadIdx.x == 0 && blockIdx.x == 0;
    bool fc = threadIdx.y == 0 && blockIdx.y == 0;

    /* if (i < N - 1 && j < N - 1 && !border_right && !border_top) { */
    float diff;
    int k = i * N + j;
    if (i < N - 1 && j < N - 1 && !fr && !fc) {
        //               left        top       right     bottom
        g[k] = 0.25 * (h[k - 1] + h[k - N] + h[k + 1] + h[k + N]);
        diff = g[k] - h[k];
        r[k] = diff * diff;
    }
    else
        r[k] = 0.0;
}

/* __global__ void gpu_residual (float *h, float *g, float *r, int N) { */
/*     int i = blockIdx.x * blockDim.x + threadIdx.x; */
/*     int j = blockIdx.y * blockDim.y + threadIdx.y; */

/*     bool fr = threadIdx.x == 0 && blockIdx.x == 0; // top line from the grid */
/*     bool fc = threadIdx.y == 0 && blockIdx.y == 0; // leftest line from the grid */

/*     float diff; */

/*     int k = i * N + j; */
/*     if (i < N - 1 && j < N - 1 && !fr && !fc) { */
/*         diff = g[k] - h[k]; */
/*         r[k] = diff * diff; */
/*     } */
/*     else */
/*         r[k] = 0.0; */
/*     /1* if(i == 1 && j == 1) printf("k %d, g %f, h %f, r %f, n %d \n",k, g[k], h[k], r[k], N); *1/ */
/* } */

__global__ void reduce0 (float *g_in, float *g_out/*, int np*/, unsigned int N) {
    extern __shared__ float sdata[];

    unsigned int tid = threadIdx.x;
    unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;

    sdata[tid] = i < N ? g_in[i] : 0.0;
    __syncthreads();


    for (unsigned int s = 1; s < blockDim.x; s *= 2) {
        if (tid % (2 * s) == 0) {
            sdata[tid] += sdata[tid + s];
        }
        __syncthreads();
    }

    if (tid == 0) 
        g_out[blockIdx.x] = sdata[0];
    /* if (i == (0)) printf("reduce: k %d, residual reduced %f, g_in %f, n %d \n", 0, sdata[0], g_in[0], N); */
}

__global__ void reduce1 (float *g_in, float *g_out, unsigned int N) {
    extern __shared__ float sdata[];

    unsigned int tid = threadIdx.x;
    unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;

    sdata[tid] = i < N ? g_in[i] : 0.0;
    __syncthreads();

    for (unsigned int s = 1; s < blockDim.x; s *= 2) {
        /* if (tid % (2 * s) == 0) { */
        int index = 2 * s * tid;
        if (index < blockDim.x) {
            sdata[tid] += sdata[tid + s];
        }
        __syncthreads();
    }

    if (tid == 0) 
        g_out[blockIdx.x] = sdata[0];
}
