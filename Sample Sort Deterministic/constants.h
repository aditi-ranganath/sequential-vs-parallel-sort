#ifndef CONSTANTS_H
#define CONSTANTS_H


/* ------------------ PADDING KERNEL ----------------- */

// How many threads are used per on thread block for padding. Has to be power of 2.
#define THREADS_PER_PADDING 128
// How many table elements are processed by one thread in padding kernel. Min value is 2.
#define ELEMS_PER_THREAD_PADDING 8


/* --------------- ALGORITHM PARAMETERS -------------- */
// Has to be lower or equal than multiplication of THREADS_PER_BITONIC_SORT * ELEMS_PER_THREAD_BITONIC_SORT.
// Has to be power of 2.
#define NUM_SAMPLES_PARALLEL 32


/* ---------------- BITONIC SORT KERNEL -------------- */

// How many threads are used per one thread block for bitonic sort, which is performed entirely
// in shared memory. Has to be power of 2.
#define THREADS_PER_BITONIC_SORT 512
// How many elements are processed by one thread in bitonic sort kernel. Min value is 2.
// Has to be divisable by 2.
#define ELEMS_PER_THREAD_BITONIC_SORT 4


/* --------------- BITONIC MERGE GLOBAL -------------- */

// How many threads are used per one thread block in GLOBAL bitonic merge. Has to be power of 2.
#define THREADS_PER_GLOBAL_MERGE 256
// How many elements are processed by one thread in GLOBAL bitonic merge. Min value is 2.
// Has to be divisable by 2.
#define ELEMS_PER_THREAD_GLOBAL_MERGE 4


/* --------------- BITONIC MERGE LOCAL --------------- */

// How many threads are used per one thread block in LOCAL bitonic merge. Has to be power of 2.
#define THREADS_PER_LOCAL_MERGE 512
// How many elements are processed by one thread in LOCAL bitonic merge. Min value is 2.
// Has to be divisable by 2.
#define ELEMS_PER_THREAD_LOCAL_MERGE 4


/* ----------------- SAMPLE INDEXING ----------------- */

// Has to be greater or equal than NUM_SAMPLES. Has to be multiple of NUM_SAMPLES.
#define THREADS_PER_SAMPLE_INDEXING 128


/* ---------------- BUCKETS RELOCATION --------------- */

// How many threads are used per one thread block in kernel for buckets relocation. Has to be power of 2.
// Also has to be greater or equal than NUM_SAMPLES. Has to be multiple of NUM_SAMPLES.
#define THREADS_PER_BUCKETS_RELOCATION 256


/* --------- SEQUENTIAL ALGORITHM PARAMETERS --------- */

#define NUM_SPLITTERS_SEQUENTIAL 64
#define OVERSAMPLING_FACTOR 4
#define NUM_SAMPLES_SEQUENTIAL (NUM_SPLITTERS_SEQUENTIAL * OVERSAMPLING_FACTOR)
// Has to be greater or equeal than NUM_SAMPLES_SEQUENTIAL
#define SMALL_SORT_THRESHOLD (1 << 10)

#endif
