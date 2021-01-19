NVCC 	= nvcc 
CUDAPATH = $(shell which nvcc | cut -d/ -f-4)

NVCCFLAGS = -I$(CUDAPATH)/include #--ptxas-options=-v 
LFLAGS = -L$(CUDAPATH)/lib64 -lcuda -lcudart -lm

REDUCTION ?= 1

NVCCFLAGS += -DREDUCTION=$(REDUCTION) 

ALL	= heatCUDA
all: $(ALL)

kernels.o: kernels.cu 
	$(NVCC) -c -g $(NVCCFLAGS) $+ $(LFLAGS) -o $@

heatCUDA: heatCUDA.cu kernels.o
	$(NVCC) -g -O2 $(NVCCFLAGS) $+ $(LFLAGS) -o $@

clean:
	rm -fr $(ALL) *.o *.prv *.pcf *.row *.sym *.mpits set-0

