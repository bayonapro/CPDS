#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <float.h>
#include <cuda.h>

typedef struct {
    float posx;
    float posy;
    float range;
    float temp;
} heatsrc_t;

typedef struct {
    unsigned maxiter;       // maximum number of iterations
    unsigned resolution;    // spatial resolution
    int algorithm;          // 0=>Jacobi, 1=>Gauss

    unsigned visres;        // visualization resolution
  
    float *u, *uhelp;
    float *uvis;

    unsigned   numsrcs;     // number of heat sources
    heatsrc_t *heatsrcs;
} algoparam_t;

// function declarations
int read_input( FILE *infile, algoparam_t *param );
void print_params( algoparam_t *param );
int initialize( algoparam_t *param );
int finalize( algoparam_t *param );
void write_image( FILE * f, float *u,
		  unsigned sizex, unsigned sizey );
int coarsen(float *uold, unsigned oldx, unsigned oldy ,
	    float *unew, unsigned newx, unsigned newy );


__global__ void gpu_Heat (float *h, float *g, float* r, int N);

/* #if REDUCTION */
__global__ void gpu_residual (float *h, float *g, float *r, int N);
/* #endif */

__global__ void reduce0 (float *g_in, float *g_out, unsigned int N);
__global__ void reduce1 (float *g_in, float *g_out, unsigned int N);

#define NB 8
#define min(a,b) ( ((a) < (b)) ? (a) : (b) )

float cpu_residual (float* residual, unsigned sizex, unsigned sizey)
{
    float sum=0.0;
  
    for (int i=1; i<sizex-1; i++) 
        for (int j=1; j<sizey-1; j++) {
            sum += residual[i*sizey+j];
	}
    return sum;
}

float cpu_jacobi (float *u, float *utmp, unsigned sizex, unsigned sizey)
{
    float diff, sum=0.0;
    int nbx, bx, nby, by;
  
    nbx = NB;
    bx = sizex/nbx;
    nby = NB;
    by = sizey/nby;
    for (int ii=0; ii<nbx; ii++)
        for (int jj=0; jj<nby; jj++) 
            for (int i=1+ii*bx; i<=min((ii+1)*bx, sizex-2); i++) 
                for (int j=1+jj*by; j<=min((jj+1)*by, sizey-2); j++) {
	            utmp[i*sizey+j]= 0.25 * (u[ i*sizey     + (j-1) ]+  // left
					     u[ i*sizey     + (j+1) ]+  // right
				             u[ (i-1)*sizey + j     ]+  // top
				             u[ (i+1)*sizey + j     ]); // bottom
            	    diff = utmp[i*sizey+j] - u[i*sizey + j];
            	    sum += diff * diff;
	        }
    return(sum);
}

void usage( char *s )
{
    fprintf(stderr, "Usage: %s <input file> -t threads -b blocks\n", s);
    fprintf(stderr, "       -t number of threads per block in each dimension (e.g. 16)\n");
}

int main( int argc, char *argv[] ) {
    unsigned iter;
    FILE *infile, *resfile;
    char *resfilename;

    // algorithmic parameters
    algoparam_t param;
    int np;

    // check arguments
    if( argc < 4 ) {
	usage( argv[0] );
	return 1;
    }

    // check input file
    if( !(infile=fopen(argv[1], "r"))  ) {
	fprintf(stderr, 
		"\nError: Cannot open \"%s\" for reading.\n\n", argv[1]);
      
	usage(argv[0]);
	return 1;
    }

// ---------------------------------------- CPU ------------------------------
    /* // check result file */
    /* resfilename="heat-cpu.ppm"; */

    /* if( !(resfile=fopen(resfilename, "w")) ) { */
	/* fprintf(stderr, */ 
		/* "\nError: Cannot open \"%s\" for writing.\n\n", */ 
		/* resfilename); */
	/* usage(argv[0]); */
	/* return 1; */
    /* } */

    // check input
    if( !read_input(infile, &param) )
    {
	fprintf(stderr, "\nError: Error parsing input file.\n\n");
	usage(argv[0]);
	return 1;
    }

    // full size (param.resolution are only the inner points)
    np = param.resolution + 2;

    int Grid_Dim, Block_Dim;	// Grid and Block structure values
    if (strcmp(argv[2], "-t")==0) {
            Block_Dim = atoi(argv[3]);
            Grid_Dim = np/Block_Dim + ((np%Block_Dim)!=0);;
    	    if ((Block_Dim*Block_Dim) > 512) {
        	printf("Error -- too many threads in block, try again\n");
        	return 1;
    	    }
    }
    else {
    	    fprintf(stderr, "Usage: %s <input file> -t threads -b blocks\n", argv[0]);
            fprintf(stderr, "       -t number of threads per block in each dimension (e.g. 16)\n");
            return 0;
       	    }

    /* fprintf(stderr, "\nSolving Heat equation on the CPU and the GPU\n"); */
    /* fprintf(stderr, "--------------------------------------------\n"); */
    /* print_params(&param); */

    /* fprintf(stdout, "\nExecution on CPU (sequential)\n-----------------------------\n"); */
    /* if( !initialize(&param) ) */
	/* { */
	    /* fprintf(stderr, "Error in Solver initialization.\n\n"); */
    /*         return 1; */
	/* } */

    // starting time
    float elapsed_time_ms;       	// which is applicable for asynchronous code also
    cudaEvent_t start, stop;     	// using cuda events to measure time
    cudaEventCreate( &start );     // instrument code to measure start time
    cudaEventCreate( &stop );

    /* cudaEventRecord( start, 0 ); */
    /* cudaEventSynchronize( start ); */

    /* iter = 0; */
    float residual = 0.0;
    /* while(1) { */
	/* residual = cpu_jacobi(param.u, param.uhelp, np, np); */
	/* float * tmp = param.u; */
	/* param.u = param.uhelp; */
	/* param.uhelp = tmp; */

    /*     iter++; */

    /*     // solution good enough ? */
    /*     if (residual < 0.00005) break; */

    /*     // max. iteration reached ? (no limit with maxiter=0) */
    /*     if (iter>=param.maxiter) break; */
    /* } */

    /* cudaEventRecord( stop, 0 );     // instrument code to measue end time */
    /* cudaEventSynchronize( stop ); */
    /* cudaEventElapsedTime( &elapsed_time_ms, start, stop ); */

    /* // Flop count after iter iterations */
    /* float flop = iter * 11.0 * param.resolution * param.resolution; */

    /* fprintf(stdout, "Time on CPU in ms.= %f ", elapsed_time_ms); */
    /* fprintf(stdout, "(%3.3f GFlop => %6.2f MFlop/s)\n", */ 
	    /* flop/1000000000.0, */
	    /* flop/elapsed_time_ms/1000); */
    /* fprintf(stdout, "Convergence to residual=%f: %d iterations\n", residual, iter); */

    /* // for plot... */
    /* coarsen( param.u, np, np, */
	     /* param.uvis, param.visres+2, param.visres+2 ); */
  
    /* write_image( resfile, param.uvis, */  
		 /* param.visres+2, */ 
		 /* param.visres+2 ); */

    /* finalize( &param ); */

//---------------------------------------- GPU -------------------------------

    fprintf(stdout, "\nExecution on GPU\n----------------\n");
    fprintf(stderr, "Number of threads per block in each dimension = %d\n", Block_Dim);
    fprintf(stderr, "Number of blocks per grid in each dimension   = %d\n", Grid_Dim);

    resfilename="heat-gpu.ppm";

    if( !(resfile=fopen(resfilename, "w")) ) {
	fprintf(stderr, 
		"\nError: Cannot open \"%s\" for writing.\n\n", 
		resfilename);
	usage(argv[0]);
	return 1;
    }

    if( !initialize(&param) )
	{
	    fprintf(stderr, "Error in Solver initialization.\n\n");
            return 1;
	}

    dim3 Grid(Grid_Dim, Grid_Dim);
    dim3 Block(Block_Dim, Block_Dim);
    
    // starting time
    cudaEventRecord( start, 0 );
    cudaEventSynchronize( start );

    float *dev_u, *dev_uhelp, *dev_residual;

    // TODO: Allocation on GPU for matrices u and uhelp
    size_t size = np * np * sizeof(float);
    cudaMalloc(&dev_u, size);
    cudaMalloc(&dev_uhelp, size);
    cudaMalloc(&dev_residual, size);

    // TODO: Copy initial values in u and uhelp from host to GPU
    cudaMemcpy(dev_u, param.u, size, cudaMemcpyHostToDevice);
    cudaMemcpy(dev_uhelp, param.uhelp, size, cudaMemcpyHostToDevice);

#if REDUCTION
#endif

    // debug
    float * residual_matrix = (float*) malloc(sizeof(float) * np * np);

    iter = 0;
    while(1) {
        gpu_Heat<<<Grid,Block>>>(dev_u, dev_uhelp, dev_residual, np);
        cudaDeviceSynchronize();
        /* cudaThreadSynchronize();                        // wait for all threads to complete */

#if REDUCTION == 0
        /* printf("Reduction cpu 0\n"); */
        cudaMemcpy(param.u, dev_u, size, cudaMemcpyDeviceToHost);
        cudaMemcpy(param.uhelp, dev_uhelp, size, cudaMemcpyDeviceToHost);
        cudaMemcpy(residual_matrix, dev_residual, size, cudaMemcpyDeviceToHost);

        /* printf("reduction = 0\n"); */
        /* residual = cpu_residual(param.u, param.uhelp, np, np); */
        residual = cpu_residual(residual_matrix, np, np);
        printf("\nresidual: %f\n", residual);

/* #elif REDUCTION == 1 */
#else
            printf("\n");
        printf("Reduction gpu 0\n");
        /* gpu_residual <<< Grid, Block >>> (dev_u, dev_uhelp, dev_residual, np); */
        /* cudaDeviceSynchronize(); */
        /*     // debug */
        /*     cudaMemcpy(debug, dev_residual,sizeof(float) * np * np, cudaMemcpyDeviceToHost); */
            /* for (int i = 0; i < np*np; i++) printf("%f ", debug[i]); */
            /* printf("\n"); */
            /* printf("dev residual [1][1] %f\n", debug[1*np + 1]); */



        /* float residual = 0.0; */
        unsigned int n = np * np;
        
        Block_Dim = 64;
        dim3 block_reduce(Block_Dim, 1, 1);
        size_t blocksPerGrid = std::ceil((1. * n) / Block_Dim);

        while (n > Block_Dim) {
            blocksPerGrid = std::ceil((1. * n) / Block_Dim);
            dim3 Grid_reduce(blocksPerGrid, 1, 1);
#if REDUCTION == 1
            reduce0 <<< Grid_reduce, block_reduce, Block_Dim >>> (dev_residual, dev_residual, n);
#elif REDUCTION == 2
            reduce1 <<< Grid_reduce, block_reduce, Block_Dim >>> (dev_residual, dev_residual, n);
#elif REDUCTION == 3
#elif REDUCTION == 4
#elif REDUCTION == 5
#elif REDUCTION == 6
#else
#endif

            cudaDeviceSynchronize();
        /*     // debug */
        /*     cudaMemcpy(debug, dev_residual,sizeof(float) * blocksPerGrid, cudaMemcpyDeviceToHost); */
        /*     for (int i = 0; i < 5; i++) printf("%f ", debug[i]); */
        /*     printf("\n"); */
            printf("blockspergrid %d and n %d\n",blocksPerGrid, n);
            n = blocksPerGrid;
        }

        if (n > 1) reduce0<<< 1, Block_Dim, Block_Dim >>>(dev_residual, dev_residual, n);


        cudaDeviceSynchronize();

        cudaMemcpy(&residual, dev_residual, sizeof(float), cudaMemcpyDeviceToHost);
        /* cudaMemcpy(&residual, to, sizeof(float), cudaMemcpyDeviceToHost); */
        printf("\nresidual: %f \n", residual);

        /* cudaFree(g_out1); */
        /* cudaFree(dev_tmp); */
#endif

	float * tmp = dev_u;
	dev_u = dev_uhelp;
	dev_uhelp = tmp;

        iter++;

        // solution good enough ?
        if (residual < 0.00005) break;

        // max. iteration reached ? (no limit with maxiter=0)
        if (iter>=param.maxiter) break;
    }

    // TODO: get result matrix from GPU
    cudaMemcpy(param.u, dev_u, size, cudaMemcpyDeviceToHost);
    cudaMemcpy(param.uhelp, dev_uhelp, size, cudaMemcpyDeviceToHost);

    // TODO: free memory used in GPU
    cudaFree(dev_u);
    cudaFree(dev_uhelp);
    cudaFree(dev_residual);

#if REDUCTION
#endif

    cudaEventRecord( stop, 0 );     // instrument code to measue end time
    cudaEventSynchronize( stop );
    cudaEventElapsedTime( &elapsed_time_ms, start, stop );

    float flop = iter * 11.0 * param.resolution * param.resolution;

    fprintf(stdout, "\nTime on GPU in ms. = %f ", elapsed_time_ms);
    fprintf(stdout, "(%3.3f GFlop => %6.2f MFlop/s)\n", 
	    flop/1000000000.0,
	    flop/elapsed_time_ms/1000);
    fprintf(stdout, "Convergence to residual=%f: %d iterations\n", residual, iter);

    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    // for plot...
    coarsen( param.u, np, np,
	     param.uvis, param.visres+2, param.visres+2 );
  
    write_image( resfile, param.uvis,  
		 param.visres+2, 
		 param.visres+2 );

    finalize( &param );

    return 0;
}


/*
 * Initialize the iterative solver
 * - allocate memory for matrices
 * - set boundary conditions according to configuration
 */
int initialize( algoparam_t *param )

{
    int i, j;
    float dist;

    // total number of points (including border)
    const int np = param->resolution + 2;
  
    //
    // allocate memory
    //
    (param->u)     = (float*)calloc( sizeof(float),np*np );
    (param->uhelp) = (float*)calloc( sizeof(float),np*np );
    (param->uvis)  = (float*)calloc( sizeof(float),
				      (param->visres+2) *
				      (param->visres+2) );
  

    if( !(param->u) || !(param->uhelp) || !(param->uvis) )
    {
	fprintf(stderr, "Error: Cannot allocate memory\n");
	return 0;
    }

    for( i=0; i<param->numsrcs; i++ )
    {
	/* top row */
	for( j=0; j<np; j++ )
	{
	    dist = sqrt( pow((float)j/(float)(np-1) - 
			     param->heatsrcs[i].posx, 2)+
			 pow(param->heatsrcs[i].posy, 2));
	  
	    if( dist <= param->heatsrcs[i].range )
	    {
		(param->u)[j] +=
		    (param->heatsrcs[i].range-dist) /
		    param->heatsrcs[i].range *
		    param->heatsrcs[i].temp;
	    }
	}
      
	/* bottom row */
	for( j=0; j<np; j++ )
	{
	    dist = sqrt( pow((float)j/(float)(np-1) - 
			     param->heatsrcs[i].posx, 2)+
			 pow(1-param->heatsrcs[i].posy, 2));
	  
	    if( dist <= param->heatsrcs[i].range )
	    {
		(param->u)[(np-1)*np+j]+=
		    (param->heatsrcs[i].range-dist) / 
		    param->heatsrcs[i].range * 
		    param->heatsrcs[i].temp;
	    }
	}
      
	/* leftmost column */
	for( j=1; j<np-1; j++ )
	{
	    dist = sqrt( pow(param->heatsrcs[i].posx, 2)+
			 pow((float)j/(float)(np-1) - 
			     param->heatsrcs[i].posy, 2)); 
	  
	    if( dist <= param->heatsrcs[i].range )
	    {
		(param->u)[ j*np ]+=
		    (param->heatsrcs[i].range-dist) / 
		    param->heatsrcs[i].range *
		    param->heatsrcs[i].temp;
	    }
	}
      
	/* rightmost column */
	for( j=1; j<np-1; j++ )
	{
	    dist = sqrt( pow(1-param->heatsrcs[i].posx, 2)+
			 pow((float)j/(float)(np-1) - 
			     param->heatsrcs[i].posy, 2)); 
	  
	    if( dist <= param->heatsrcs[i].range )
	    {
		(param->u)[ j*np+(np-1) ]+=
		    (param->heatsrcs[i].range-dist) /
		    param->heatsrcs[i].range *
		    param->heatsrcs[i].temp;
	    }
	}
    }

    // Copy u into uhelp
    float *putmp, *pu;
    pu = param->u;
    putmp = param->uhelp;
    for( j=0; j<np; j++ )
	for( i=0; i<np; i++ )
	    *putmp++ = *pu++;

    return 1;
}

/*
 * free used memory
 */
int finalize( algoparam_t *param )
{
    if( param->u ) {
	free(param->u);
	param->u = 0;
    }

    if( param->uhelp ) {
	free(param->uhelp);
	param->uhelp = 0;
    }

    if( param->uvis ) {
	free(param->uvis);
	param->uvis = 0;
    }

    return 1;
}


/*
 * write the given temperature u matrix to rgb values
 * and write the resulting image to file f
 */
void write_image( FILE * f, float *u,
		  unsigned sizex, unsigned sizey ) 
{
    // RGB table
    unsigned char r[1024], g[1024], b[1024];
    int i, j, k;
  
    float min, max;

    j=1023;

    // prepare RGB table
    for( i=0; i<256; i++ )
    {
	r[j]=255; g[j]=i; b[j]=0;
	j--;
    }
    for( i=0; i<256; i++ )
    {
	r[j]=255-i; g[j]=255; b[j]=0;
	j--;
    }
    for( i=0; i<256; i++ )
    {
	r[j]=0; g[j]=255; b[j]=i;
	j--;
    }
    for( i=0; i<256; i++ )
    {
	r[j]=0; g[j]=255-i; b[j]=255;
	j--;
    }

    min=DBL_MAX;
    max=-DBL_MAX;

    // find minimum and maximum 
    for( i=0; i<sizey; i++ )
    {
	for( j=0; j<sizex; j++ )
	{
	    if( u[i*sizex+j]>max )
		max=u[i*sizex+j];
	    if( u[i*sizex+j]<min )
		min=u[i*sizex+j];
	}
    }
  

    fprintf(f, "P3\n");
    fprintf(f, "%u %u\n", sizex, sizey);
    fprintf(f, "%u\n", 255);

    for( i=0; i<sizey; i++ )
    {
	for( j=0; j<sizex; j++ )
	{
	    k=(int)(1023.0*(u[i*sizex+j]-min)/(max-min));
	    fprintf(f, "%d %d %d  ", r[k], g[k], b[k]);
	}
	fprintf(f, "\n");
    }
}


int coarsen( float *uold, unsigned oldx, unsigned oldy ,
	     float *unew, unsigned newx, unsigned newy )
{
    int i, j;

    int stepx;
    int stepy;
    int stopx = newx;
    int stopy = newy;

    if (oldx>newx)
	stepx=oldx/newx;
    else {
	stepx=1;
	stopx=oldx;
    }
    if (oldy>newy)
	stepy=oldy/newy;
    else {
	stepy=1;
	stopy=oldy;
    }

    // NOTE: this only takes the top-left corner,
    // and doesnt' do any real coarsening 
    for( i=0; i<stopy-1; i++ )
    {
	for( j=0; j<stopx-1; j++ )
        {
	    unew[i*newx+j]=uold[i*oldx*stepy+j*stepx];
        }
    }

  return 1;
}

#define BUFSIZE 100
int read_input( FILE *infile, algoparam_t *param )
{
  int i, n;
  char buf[BUFSIZE];

  fgets(buf, BUFSIZE, infile);
  n = sscanf( buf, "%u", &(param->maxiter) );
  if( n!=1)
    return 0;

  fgets(buf, BUFSIZE, infile);
  n = sscanf( buf, "%u", &(param->resolution) );
  if( n!=1 )
    return 0;

  param->visres = param->resolution;

  fgets(buf, BUFSIZE, infile);
  n = sscanf(buf, "%u", &(param->numsrcs) );
  if( n!=1 )
    return 0;

  (param->heatsrcs) = 
    (heatsrc_t*) malloc( sizeof(heatsrc_t) * (param->numsrcs) );
  
  for( i=0; i<param->numsrcs; i++ )
    {
      fgets(buf, BUFSIZE, infile);
      n = sscanf( buf, "%f %f %f %f",
		  &(param->heatsrcs[i].posx),
		  &(param->heatsrcs[i].posy),
		  &(param->heatsrcs[i].range),
		  &(param->heatsrcs[i].temp) );

      if( n!=4 )
	return 0;
    }

  return 1;
}


void print_params( algoparam_t *param )
{
  int i;

  fprintf(stdout, "Iterations        : %u\n", param->maxiter);
  fprintf(stdout, "Resolution        : %u\n", param->resolution);
  fprintf(stdout, "Num. Heat sources : %u\n", param->numsrcs);

  for( i=0; i<param->numsrcs; i++ )
    {
      fprintf(stdout, "  %2d: (%2.2f, %2.2f) %2.2f %2.2f \n",
	     i+1,
	     param->heatsrcs[i].posx,
	     param->heatsrcs[i].posy,
	     param->heatsrcs[i].range,
	     param->heatsrcs[i].temp );
    }
}
