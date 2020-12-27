#include "heat.h"
#include <mpi.h>


#define min(a,b) ( ((a) < (b)) ? (a) : (b) )
#define NB 8
/*
 * Blocked Jacobi solver: one iteration step
 */
/* double relax_jacobi (double *u, double *utmp, unsigned sizex, unsigned sizey) */
/* { */
/*     double diff, sum=0.0; */
/*     int nbx, bx, nby, by; */
  
/*     nbx = NB; */
/*     bx = sizex/nbx; */
/*     nby = NB; */
/*     by = sizey/nby; */
/*     for (int ii=0; ii<nbx; ii++) */
/*         for (int jj=0; jj<nby; jj++) */ 
/*             for (int i=1+ii*bx; i<=min((ii+1)*bx, sizex-2); i++) */ 
/*                 for (int j=1+jj*by; j<=min((jj+1)*by, sizey-2); j++) { */
/* 	            utmp[i*sizey+j]= 0.25 * (u[ i*sizey     + (j-1) ]+  // left */
/* 					     u[ i*sizey     + (j+1) ]+  // right */
/* 				             u[ (i-1)*sizey + j     ]+  // top */
/* 				             u[ (i+1)*sizey + j     ]); // bottom */
/* 	            diff = utmp[i*sizey+j] - u[i*sizey + j]; */
/* 	            sum += diff * diff; */ 
/* 	        } */

    /* return sum; */
/* } */

double relax_jacobi (double *u, double *utmp, unsigned sizex, unsigned sizey, int mpi_id, int mpi_size)
{
    double diff, sum=0.0;
    for( int i=1; i<sizex-1; i++ ) {
        for( int j=1; j<sizey-1; j++ ) {
            utmp[i*sizey + j] = 0.25 * (
                    u[ i*sizey     + (j-1) ]+  // left
                    u[ i*sizey     + (j+1) ]+  // right
                    u[ (i-1)*sizey + j     ]+  // top
                    u[ (i+1)*sizey + j     ]); // bottom

            diff = utmp[i*sizey + j] - u[i*sizey + j];
            sum += diff * diff;
        }
    }

    /* fprintf(stdout, "id: %d\n", mpi_id); */
    // mpi sharing rows for next iteration

    MPI_Request row_send_req[2];
    MPI_Request row_recv_req[2];

    // send/recv dependencies of the bottom part, all except for the last worker
    if (mpi_id < (mpi_size - 1)) {
        MPI_Isend(&utmp[(sizex - 2) * sizey], sizey, MPI_DOUBLE, mpi_id + 1, 3, MPI_COMM_WORLD, &row_send_req[1]);
        MPI_Irecv(&utmp[(sizex - 1) * sizey], sizey, MPI_DOUBLE, mpi_id + 1, 2, MPI_COMM_WORLD, &row_recv_req[1]);
    }
    // send/recv dependencies of the top part, all except for the first worker
    if (mpi_id) {
        MPI_Irecv(&utmp[0], sizey, MPI_DOUBLE, mpi_id - 1, 3, MPI_COMM_WORLD, &row_recv_req[0]);
        MPI_Isend(&utmp[1*sizey], sizey, MPI_DOUBLE, mpi_id - 1, 2, MPI_COMM_WORLD, &row_send_req[0]);
    }

    if (mpi_id < mpi_size - 1) {
        MPI_Wait(&row_send_req[1], MPI_STATUS_IGNORE);
        MPI_Wait(&row_recv_req[1], MPI_STATUS_IGNORE);
    }
    if (mpi_id) {
        MPI_Wait(&row_send_req[0], MPI_STATUS_IGNORE);
        MPI_Wait(&row_recv_req[0], MPI_STATUS_IGNORE);
    }
    // mpi sharing sum result to decide if to continue computing

    double sum_reduced = sum;
    MPI_Allreduce(&sum, &sum_reduced, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);

    return sum_reduced;
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
    for (int ii=0; ii<nbx; ii++) {
        lsw = ii%2;
        for (int jj=lsw; jj<nby; jj=jj+2) 
            for (int i=1+ii*bx; i<=min((ii+1)*bx, sizex-2); i++) 
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

    // Computing "Black" blocks
    for (int ii=0; ii<nbx; ii++) {
        lsw = (ii+1)%2;
        for (int jj=lsw; jj<nby; jj=jj+2) 
            for (int i=1+ii*bx; i<=min((ii+1)*bx, sizex-2); i++) 
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

    return sum;
}

/*
 * Blocked Gauss-Seidel solver: one iteration step
 */
/* double relax_gauss (double *u, unsigned sizex, unsigned sizey, */ 
double relax_gauss (double *u, unsigned sizex, unsigned sizey, int mpi_id, int mpi_size)
{
    double unew, diff, sum=0.0;
    int nbx, bx, nby, by;

    nbx = NB;
    bx = sizex/nbx;
    nby = NB;
    by = sizey/nby;

    MPI_Request send_req, recv_req;

    for (int ii=0; ii<nbx; ii++) {
        for (int jj=0; jj<nby; jj++) {
//
// MPI code recv
//

            // receive the top part at the first iteration of ii (top row), all workers except the first one
            if (mpi_id && !ii) {
                /* if (mpi_id==1) */
                /* fprintf(stdout, "proc %d ready to recv %d\n", mpi_id, ii*sizey + jj*by+1); */
                MPI_Recv(&u[0 + jj*by/*+1*/], by, MPI_DOUBLE, mpi_id - 1, 7, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                /* if (mpi_id==1) */
                /* fprintf(stdout, "proc %d recv %d\n", mpi_id, ii*sizey + jj*by+1); */
            }

            
            for (int i=1+ii*bx; i<=min((ii+1)*bx, sizex-2); i++) {
                for (int j=1+jj*by; j<=min((jj+1)*by, sizey-2); j++) {
	            unew= 0.25 * (    u[ i*sizey	+ (j-1) ]+  // left
				      u[ i*sizey	+ (j+1) ]+  // right
				      u[ (i-1)*sizey	+ j     ]+  // top
				      u[ (i+1)*sizey	+ j     ]); // bottom
	            diff = unew - u[i*sizey+ j];
	            sum += diff * diff; 
	            u[i*sizey+j]=unew;
                /* if (mpi_id==0 && (ii== nbx-1) && (i==min((ii+1)*bx, sizex-2)) && (j==min((jj+1)*by, sizey-2))) */
                /* fprintf(stdout, "proc %d element %d\n", mpi_id, i*sizey + j); */
                }
            }
// MPI code send
//
// send the bottom part at the last iteration of ii (bottom row), all workers except the last one
            if ((mpi_id < mpi_size - 1) && (ii == nbx - 1)) {
                /* if (mpi_id==0) */
                /* fprintf(stdout, "proc %d ready to send %d\n", mpi_id, (sizex - 2 )*sizey + jj*by+1); */
                /* fprintf(stdout, "proc %d ready to send %d\n", mpi_id, ((ii+1)*bx - 2 )*sizey + jj*by+1); */
                MPI_Send(&u[(sizex - 2)*sizey + jj*by/*+1*/], by, MPI_DOUBLE, mpi_id + 1, 7, MPI_COMM_WORLD);
                /* if (mpi_id==1) */
                /* fprintf(stdout, "proc %d sent %d\n", mpi_id, ii*sizey + jj*by+1); */
            }

        }
    }

    if ((mpi_id < mpi_size - 1)) {
        MPI_Recv(&u[(sizex-1) * sizey], sizey, MPI_DOUBLE, mpi_id + 1, 8, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    }
    if (mpi_id) {
        MPI_Send(&u[1*sizey], sizey, MPI_DOUBLE, mpi_id - 1, 8, MPI_COMM_WORLD);
    }

    // mpi sharing sum result to decide if continue computing

    double sum_reduced = sum;
    MPI_Allreduce(&sum, &sum_reduced, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);
                /* if (mpi_id==1) */
                /* fprintf(stdout, "proc %d reduce %f\n", mpi_id, sum); */

    return sum_reduced;
}

