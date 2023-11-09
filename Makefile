BUILDDIR ?= build

HOST_BINARY=${BUILDDIR}/host_app
HOST_SOURCES=$(wildcard host/*.c)
HOST_HEADERS=$(wildcard host/*.h)

DPU_BINARY=${BUILDDIR}/dpu_task
DPU_SOURCES=$(wildcard dpu/*.c)
DPU_HEADERS=$(wildcard dpu/*.h)

UTIL_HEADERS=$(wildcard util/*.h)
UTIL_SOURCES=$(wildcard util/*.c)
UPMEM_HEADERS=$(wildcard upmemInterface/*.h)
UPMEM_SOURCES=$(wildcard upmemInterface/*.o)

CHECK_FORMAT_FILES=${HOST_SOURCES} ${HOST_HEADERS} ${DPU_SOURCES} ${DPU_HEADERS} ${UTIL_HEADERS} ${UTIL_SOURCES}
CHECK_FORMAT_DEPENDENCIES=$(addsuffix -check-format,${CHECK_FORMAT_FILES})

NR_TASKLETS ?= 17

__dirs := $(shell mkdir -p ${BUILDDIR})

.PHONY: all clean run plotdata check check-format tools

all: ${HOST_BINARY} ${DPU_BINARY} tools
clean:
	rm -rf ${BUILDDIR}

###
### HOST APPLICATION
###
CFLAGS=-g -O2 -std=gnu99 -fgnu89-inline `dpu-pkg-config --cflags --libs dpu` -DNR_TASKLETS=${NR_TASKLETS} -pthread -lstdc++
LDFLAGS=`dpu-pkg-config --libs dpu`

${HOST_BINARY}: ${HOST_SOURCES} ${HOST_HEADERS} ${UTIL_HEADERS} ${UTIL_SOURCES} ${UPMEM_HEADERS} ${UPMEM_SOURCES} ${DPU_BINARY}
	$(CC) -o $@ ${HOST_SOURCES} ${UTIL_SOURCES} ${UPMEM_SOURCES} $(LDFLAGS) $(CFLAGS) -DDPU_BINARY=\"$(realpath ${DPU_BINARY})\"

###
### DPU BINARY
###
DPU_FLAGS=-g -O2 -fgnu89-inline -DNR_TASKLETS=${NR_TASKLETS} -DSTACK_SIZE_DEFAULT=1024

${DPU_BINARY}: ${DPU_SOURCES} ${DPU_HEADERS} ${UTIL_HEADERS} ${UTIL_SOURCES}
	dpu-upmem-dpurte-clang ${DPU_FLAGS} ${DPU_SOURCES} ${UTIL_SOURCES} -o $@
