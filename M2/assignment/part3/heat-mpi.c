/*
 * Iterative solver for heat distribution
 */

#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include "heat.h"

void usage( char *s )
{
    fprintf(stderr, 
	    "Usage: %s <input file> [result file]\n\n", s);
}

int distribute_rows (int mpi_id, int mpi_ranks, int rows) { 
    return (rows/mpi_ranks) + ((rows % mpi_ranks) > mpi_id);
}

int main( int argc, char *argv[] )
{
    unsigned iter;
    FILE *infile, *resfile;
    char *resfilename;
    int myid, numprocs;
    MPI_Status status;

    MPI_Init(&argc, &argv);
    MPI_Comm_size(MPI_COMM_WORLD, &numprocs);
    MPI_Comm_rank(MPI_COMM_WORLD, &myid);

    if (myid == 0) {
      printf("I am the master (%d) and going to distribute work to %d additional workers ...\n", myid, numprocs-1);

    // algorithmic parameters
    algoparam_t param;
    int np;

    double runtime, flop;
    double residual=0.0;

    // check arguments
    if( argc < 2 )
    {
	usage( argv[0] );
	return 1;
    }

    // check input file
    if( !(infile=fopen(argv[1], "r"))  ) 
    {
	fprintf(stderr, 
		"\nError: Cannot open \"%s\" for reading.\n\n", argv[1]);
      
	usage(argv[0]);
	return 1;
    }

    // check result file
    resfilename= (argc>=3) ? argv[2]:"heat.ppm";

    if( !(resfile=fopen(resfilename, "w")) )
    {
	fprintf(stderr, 
		"\nError: Cannot open \"%s\" for writing.\n\n", 
		resfilename);
	usage(argv[0]);
	return 1;
    }

    // check input
    if( !read_input(infile, &param) )
    {
	fprintf(stderr, "\nError: Error parsing input file.\n\n");
	usage(argv[0]);
	return 1;
    }
    print_params(&param);

    // set the visualization resolution
    
    param.u     = 0;
    param.uhelp = 0;
    param.uvis  = 0;
    param.visres = param.resolution;
   
    if( !initialize(&param) )
	{
	    fprintf(stderr, "Error in Solver initialization.\n\n");
	    usage(argv[0]);
            return 1;
	}

    // full size (param.resolution are only the inner points)
    np = param.resolution + 2;
    int local_rows= distribute_rows(0, numprocs, param.resolution) + 2;
    
    // starting time
    runtime = wtime();

    // send to workers the necessary data to perform computation
    for (int i=1; i < numprocs; i++) {
        int sent_rows = distribute_rows(i, numprocs, param.resolution) + 2;
        MPI_Send(&param.maxiter, 1, MPI_INT, i, 0, MPI_COMM_WORLD);
        MPI_Send(&np, 1, MPI_INT, i, 0, MPI_COMM_WORLD); // columns
        MPI_Send(&sent_rows, 1, MPI_INT, i, 0, MPI_COMM_WORLD);
        MPI_Send(&param.algorithm, 1, MPI_INT, i, 0, MPI_COMM_WORLD);
        MPI_Send(&param.u[i * (sent_rows - 2) * np], (sent_rows)*(np), MPI_DOUBLE, i, 0, MPI_COMM_WORLD);
        MPI_Send(&param.uhelp[i * (sent_rows - 2) * np], (sent_rows)*(np), MPI_DOUBLE, i, 0, MPI_COMM_WORLD);
    }

    iter = 0;
    while(1) {
	switch( param.algorithm ) {
	    case 0: // JACOBI
	            residual = relax_jacobi(param.u, param.uhelp, local_rows, np, myid, numprocs);
		    // Copy uhelp into u
                    double * tmp = param.u;
                    param.u = param.uhelp;
                    param.uhelp = tmp;
		    /* for (int i=0; i<local_rows; i++) */
    		        /* for (int j=0; j<np; j++) */
	    		    /* param.u[ i*np+j ] = param.uhelp[ i*np+j ]; */
		    break;
	    case 1: // RED-BLACK
		    residual = relax_redblack(param.u, np, np);
		    break;
	    case 2: // GAUSS
		    residual = relax_gauss(param.u, local_rows, np, myid, numprocs);
		    break;
	    }

        iter++;

        // solution good enough ?
        if (residual < 0.000050) break;

        // max. iteration reached ? (no limit with maxiter=0)
        if (param.maxiter>0 && iter>=param.maxiter) break;
    }

    for (int i = 1; i < numprocs; i++) {
        int sent_rows = distribute_rows(i, numprocs, param.resolution);

        MPI_Recv(&param.u[i * sent_rows * np], sent_rows * np, MPI_DOUBLE, i, 1, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    }
    // Flop count after iter iterations
    flop = iter * 11.0 * param.resolution * param.resolution;
    // stopping time
    runtime = wtime() - runtime;

    fprintf(stdout, "Time: %04.3f ", runtime);
    fprintf(stdout, "(%3.3f GFlop => %6.2f MFlop/s)\n", 
	    flop/1000000000.0,
	    flop/runtime/1000000);
    fprintf(stdout, "Convergence to residual=%f: %d iterations\n", residual, iter);

    // for plot...
    coarsen( param.u, np, np,
	     param.uvis, param.visres+2, param.visres+2 );
  
    write_image( resfile, param.uvis,  
		 param.visres+2, 
		 param.visres+2 );

    finalize( &param );

    fprintf(stdout, "Process %d finished computing with residual value = %f\n", myid, residual);

    MPI_Finalize();

    return 0;

} else {

    printf("I am worker %d and ready to receive work to do ...\n", myid);

    // receive information from master to perform computation locally

    int columns, rows, np, resolution;
    int iter, maxiter;
    int algorithm;
    double residual;

    MPI_Recv(&maxiter, 1, MPI_INT, 0, 0, MPI_COMM_WORLD, &status);
    MPI_Recv(&np, 1, MPI_INT, 0, 0, MPI_COMM_WORLD, &status);
    MPI_Recv(&rows, 1, MPI_INT, 0, 0, MPI_COMM_WORLD, &status);
    MPI_Recv(&algorithm, 1, MPI_INT, 0, 0, MPI_COMM_WORLD, &status);

    resolution = np - 2;

    // allocate memory for worker
    double * u = calloc( sizeof(double),(rows)*(np) );
    double * uhelp = calloc( sizeof(double),(rows)*(np) );
    if( (!u) || (!uhelp) )
    {
        fprintf(stderr, "Error: Cannot allocate memory\n");
        return 0;
    }
    
    // fill initial values for matrix with values received from master
    MPI_Recv(&u[0], (rows)*(np), MPI_DOUBLE, 0, 0, MPI_COMM_WORLD, &status);
    MPI_Recv(&uhelp[0], (rows)*(np), MPI_DOUBLE, 0, 0, MPI_COMM_WORLD, &status);

    iter = 0;
    while(1) {
	switch ( algorithm ) {
	    case 0: // JACOBI
	            residual = relax_jacobi(u, uhelp, rows, np, myid, numprocs);
		    // Copy uhelp into u
                    double * tmp = u;
                    u = uhelp;
                    uhelp = tmp;
		    /* for (int i=0; i<rows; i++) */
    		        /* for (int j=0; j<np; j++) */
	    		    /* u[ i*np+j ] = uhelp[ i*np+j ]; */
		    break;
	    case 1: // RED-BLACK
		    residual = relax_redblack(u, np, np);
		    break;
	    case 2: // GAUSS
		    residual = relax_gauss(u, rows, np, myid, numprocs);
		    break;
	    }

        iter++;

        // solution good enough ?
        if (residual < 0.000050) break;

        // max. iteration reached ? (no limit with maxiter=0)
        if (maxiter>0 && iter>=maxiter) break;
    }

    MPI_Send(&u[1*np], (rows-2)*np, MPI_DOUBLE, 0, 1, MPI_COMM_WORLD);

    if( u ) free(u); if( uhelp ) free(uhelp);

    fprintf(stdout, "Process %d finished computing %d iterations with residual value = %f\n", myid, iter, residual);

    MPI_Finalize();
    exit(0);
  }
}
