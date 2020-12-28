#include "heat.h"

#define NB 8

#define min(a,b) ( ((a) < (b)) ? (a) : (b) )

/*
 * Blocked Jacobi solver: one iteration step
 */
double relax_jacobi (double *u, double *utmp, unsigned sizex, unsigned sizey)
{
    double diff, sum=0.0;
    int nbx, bx, nby, by;

    nbx = NB;
    bx = sizex/nbx;
    nby = NB;
    by = sizey/nby;
    
    /* #pragma omp parallel for reduction(+:sum) collapse(2) private(diff) */
    for (int ii = 0; ii < nbx; ii++) {
        for (int jj = 0; jj < nby; jj++) { 
            for (int i = 1 + ii * bx; i <= min((ii + 1) * bx, sizex - 2); i++) {
#pragma omp parallel for reduction(+:sum) private(diff) // version 1
                for (int j = 1 + jj * by; j <= min((jj + 1) * by, sizey - 2); j++) {
                    utmp[i * sizey + j]= 0.25 * (
                            u[ i *      sizey + (j - 1)] +      // left
                            u[ i *      sizey + (j + 1)] +      // right
                            u[(i - 1) * sizey + j      ] +      // top
                            u[(i + 1) * sizey + j      ]);      // bottom
                    diff = utmp[i * sizey + j] - u[i * sizey + j];
                    sum += diff * diff; 
                }
            }
        }
    }

    return sum;
}

/*
 * Blocked Red-Black solver: one iteration step
 */
double relax_redblack (double *u, unsigned sizex, unsigned sizey)
{
    double unew, diff, sum=0.0;
    int nbx, bx, nby, by;
    int lsw;

    nbx = NB;
    bx = sizex/nbx;
    nby = NB;
    by = sizey/nby;
    // Computing "Red" blocks
#pragma omp parallel
{
#pragma omp for reduction(+:sum) private(unew, diff)
    for (int ii=0; ii<nbx; ii++) {
        lsw = ii%2;
        for (int jj=lsw; jj<nby; jj=jj+2) {
            for (int i=1+ii*bx; i<=min((ii+1)*bx, sizex-2); i++) {
                for (int j=1+jj*by; j<=min((jj+1)*by, sizey-2); j++) {
                    unew= 0.25 * (    u[ i*sizey	+ (j-1) ]+  // left
                            u[ i*sizey	+ (j+1) ]+  // right
                            u[ (i-1)*sizey	+ j     ]+  // top
                            u[ (i+1)*sizey	+ j     ]); // bottom
                    diff = unew - u[i*sizey+ j];
                    sum += diff * diff; 
                    u[i*sizey+j]=unew;
                }
            }
        }
    }
#pragma omp taskwait
    // Computing "Black" blocks
#pragma omp for reduction(+:sum) private(unew, diff)
    for (int ii=0; ii<nbx; ii++) {
        lsw = (ii+1)%2;
        for (int jj=lsw; jj<nby; jj=jj+2) {
            for (int i=1+ii*bx; i<=min((ii+1)*bx, sizex-2); i++) {
                for (int j=1+jj*by; j<=min((jj+1)*by, sizey-2); j++) {
                    unew= 0.25 * (    u[ i*sizey	+ (j-1) ]+  // left
                            u[ i*sizey	+ (j+1) ]+  // right
                            u[ (i-1)*sizey	+ j     ]+  // top
                            u[ (i+1)*sizey	+ j     ]); // bottom
                    diff = unew - u[i*sizey+ j];
                    sum += diff * diff; 
                    u[i*sizey+j]=unew;
                }
            }
        }
    }
}
    return sum;
}

/*
 * Blocked Gauss-Seidel solver: one iteration step
 */
double relax_gauss (double *u, unsigned sizex, unsigned sizey)
{
    double unew, diff, local_sum = 0.0, sum=0.0;
    int nbx, bx, nby, by;

    nbx = NB;
    bx = sizex/nbx;
    nby = NB;
    by = sizey/nby;

#pragma omp parallel reduction(+:sum)
    {
#pragma omp single
        {
    for (int ii=0; ii<nbx; ii++)
        for (int jj=0; jj<nby; jj++) { 
            // tareas por cada bloque
            /* int end_top  = ii * bx * sizey + (jj + 1) * by - sizey - 1; // depend in, top block */
            /* int end_left = ((ii + 1) * bx - 1) * sizey + jj * by - 1; // depen in, left block */ 
            /* int end_me   = ((ii + 1) * bx - 1) * sizey + (jj - 1) * by; // depend out, myself */
            int end_top = (ii * bx )*sizey + (jj + 1)*by; // depend in, tp block
            int end_left = ((ii + 1)*bx)*sizey + jj*by; // depend in, left block
            int end_me = ((ii + 1)*bx)*sizey + (jj + 1) * by;
            printf("ii %d, jj %d, end_top %d, end_left %d, end_me %d\n", ii, jj, end_top, end_left, end_me);
#pragma omp task  private(diff, unew) firstprivate(end_top, end_left, end_me, local_sum,jj, ii) depend(in:u[end_top], u[end_left]) depend(out:u[end_me]) if(ii&&jj)// entrada de borde izq y superior, salida de borde derecho e inferior
            {
                local_sum = 0.0;
            printf("2nd for, it %d, thread %d\n", jj, omp_get_thread_num());
            printf("ii %d, jj %d, end_top %d, end_left %d, end_me %d\n", ii, jj, end_top, end_left, end_me);
            for (int i=1+ii*bx; i<=min((ii+1)*bx, sizex-2); i++) 
                for (int j=1+jj*by; j<=min((jj+1)*by, sizey-2); j++) {
                    unew= 0.25 * (u[ i*sizey	+ (j-1) ]+  // left
                            u[ i*sizey	+ (j+1) ]+  // right
                            u[ (i-1)*sizey	+ j     ]+  // top
                            u[ (i+1)*sizey	+ j     ]); // bottom
                    diff = unew - u[i*sizey+ j];
                    local_sum += diff * diff; 
                    u[i*sizey+j]=unew;
                }
#pragma omp atomic update
            sum += local_sum;
        }
        }

        }
    }
    return sum;
}

