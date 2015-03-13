#include <stdio.h>

#include <cuda.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "math_functions.h"

#include "../Utils/data_types_common.h"
#include "constants.h"
#include "kernels_common_utils.h"
#include "kernels_key_value_utils.h"


/*
Sorts sub-blocks of input data with NORMALIZED bitonic sort.
*/
template <order_t sortOrder>
__global__ void bitonicSortKernel(data_t *keys, data_t *values, uint_t tableLen)
{
    extern __shared__ data_t bitonicSortTile[];

    uint_t elemsPerThreadBlock = THREADS_PER_BITONIC_SORT_KV * ELEMS_PER_THREAD_BITONIC_SORT_KV;
    uint_t offset = blockIdx.x * elemsPerThreadBlock;
    uint_t dataBlockLength = offset + elemsPerThreadBlock <= tableLen ? elemsPerThreadBlock : tableLen - offset;

    data_t *keysTile = bitonicSortTile;
    data_t *valuesTile = bitonicSortTile + dataBlockLength;

    // Reads data from global to shared memory.
    for (uint_t tx = threadIdx.x; tx < dataBlockLength; tx += THREADS_PER_BITONIC_SORT_KV)
    {
        keysTile[tx] = keys[offset + tx];
        valuesTile[tx] = values[offset + tx];
    }
    __syncthreads();

    // Bitonic sort PHASES
    for (uint_t subBlockSize = 1; subBlockSize < dataBlockLength; subBlockSize <<= 1)
    {
        // Bitonic merge STEPS
        for (uint_t stride = subBlockSize; stride > 0; stride >>= 1)
        {
            for (uint_t tx = threadIdx.x; tx < dataBlockLength >> 1; tx += THREADS_PER_BITONIC_SORT_KV)
            {
                uint_t indexThread = tx;
                uint_t offset = stride;

                // In NORMALIZED bitonic sort, first STEP of every PHASE uses different offset than all other
                // STEPS. Also, in first step of every phase, offset sizes are generated in ASCENDING order
                // (normalized bitnic sort requires DESCENDING order). Because of that, we can break the loop if
                // index + offset >= length (bellow). If we want to generate offset sizes in ASCENDING order,
                // than thread indexes inside every sub-block have to be reversed.
                if (stride == subBlockSize)
                {
                    indexThread = (tx / stride) * stride + ((stride - 1) - (tx % stride));
                    offset = ((tx & (stride - 1)) << 1) + 1;
                }

                uint_t index = (indexThread << 1) - (indexThread & (stride - 1));
                if (index + offset >= dataBlockLength)
                {
                    break;
                }

                compareExchange2<sortOrder>(
                    &keysTile[index], &keysTile[index + offset], &valuesTile[index], &valuesTile[index + offset]
                );
            }

            __syncthreads();
        }
    }

    // Stores data from shared to global memory
    for (uint_t tx = threadIdx.x; tx < dataBlockLength; tx += THREADS_PER_BITONIC_SORT_KV)
    {
        keys[offset + tx] = keysTile[tx];
        values[offset + tx] = valuesTile[tx];
    }
}

template __global__ void bitonicSortKernel<ORDER_ASC>(data_t *keys, data_t *values, uint_t tableLen);
template __global__ void bitonicSortKernel<ORDER_DESC>(data_t *keys, data_t *values, uint_t tableLen);


/*
Performs bitonic merge with 1-multistep (sorts 2 elements per thread).
*/
template <order_t sortOrder>
__global__ void multiStep1Kernel(data_t *keys, data_t *values, int_t tableLen, uint_t step)
{
    uint_t stride, tableOffset, indexTable;
    data_t key1, key2;
    data_t val1, val2;

    getMultiStepParams(step, 1, stride, tableOffset, indexTable);

    load2<sortOrder>(
        keys + indexTable, values + indexTable, tableLen - indexTable - 1, stride, &key1, &key2, &val1, &val2
    );
    compareExchange2<sortOrder>(&key1, &key2, &val1, &val2);
    store2(
        keys + indexTable, values + indexTable, tableLen - indexTable - 1, stride, key1, key2, val1, val2
    );
}

template __global__ void multiStep1Kernel<ORDER_ASC>(data_t *key, data_t *values, int_t tableLen, uint_t step);
template __global__ void multiStep1Kernel<ORDER_DESC>(data_t *key, data_t *values, int_t tableLen, uint_t step);


/*
Performs bitonic merge with 2-multistep (sorts 4 elements per thread).
*/
template <order_t sortOrder>
__global__ void multiStep2Kernel(data_t *keys, data_t *values, int_t tableLen, uint_t step)
{
    uint_t stride, tableOffset, indexTable;
    data_t key1, key2, key3, key4;
    data_t val1, val2, val3, val4;

    getMultiStepParams(step, 2, stride, tableOffset, indexTable);

    load4<sortOrder>(
        keys + indexTable, values + indexTable, tableLen - indexTable - 1, tableOffset, stride,
        &key1, &key2, &key3, &key4, &val1, &val2, &val3, &val4
    );
    compareExchange4<sortOrder>(&key1, &key2, &key3, &key4, &val1, &val2, &val3, &val4);
    store4(
        keys + indexTable, values + indexTable, tableLen - indexTable - 1, tableOffset, stride,
        key1, key2, key3, key4, val1, val2, val3, val4
    );
}

template __global__ void multiStep2Kernel<ORDER_ASC>(data_t *keys, data_t *values, int_t tableLen, uint_t step);
template __global__ void multiStep2Kernel<ORDER_DESC>(data_t *keys, data_t *values, int_t tableLen, uint_t step);


/*
Performs bitonic merge with 3-multistep (sorts 8 elements per thread).
*/
template <order_t sortOrder>
__global__ void multiStep3Kernel(data_t *keys, data_t *values, int_t tableLen, uint_t step)
{
    uint_t stride, tableOffset, indexTable;
    data_t key1, key2, key3, key4, key5, key6, key7, key8;
    data_t val1, val2, val3, val4, val5, val6, val7, val8;

    getMultiStepParams(step, 3, stride, tableOffset, indexTable);

    load8<sortOrder>(
        keys + indexTable, values + indexTable, tableLen - indexTable - 1, tableOffset, stride, &key1, &key2,
        &key3, &key4, &key5, &key6, &key7, &key8, &val1, &val2, &val3, &val4, &val5, &val6, &val7, &val8
    );
    compareExchange8<sortOrder>(
        &key1, &key2, &key3, &key4, &key5, &key6, &key7, &key8,
        &val1, &val2, &val3, &val4, &val5, &val6, &val7, &val8
    );
    store8(
        keys + indexTable, values + indexTable, tableLen - indexTable - 1, tableOffset, stride, key1, key2,
        key3, key4, key5, key6, key7, key8, val1, val2, val3, val4, val5, val6, val7, val8
    );
}

template __global__ void multiStep3Kernel<ORDER_ASC>(data_t *keys, data_t *values, int_t tableLen, uint_t step);
template __global__ void multiStep3Kernel<ORDER_DESC>(data_t *keys, data_t *values, int_t tableLen, uint_t step);


/*
Performs bitonic merge with 4-multistep (sorts 16 elements per thread).
*/
template <order_t sortOrder>
__global__ void multiStep4Kernel(data_t *keys, data_t *values, int_t tableLen, uint_t step)
{
    uint_t stride, tableOffset, indexTable;
    data_t key1, key2, key3, key4, key5, key6, key7, key8, key9, key10, key11, key12, key13, key14, key15, key16;
    data_t val1, val2, val3, val4, val5, val6, val7, val8, val9, val10, val11, val12, val13, val14, val15, val16;

    getMultiStepParams(step, 4, stride, tableOffset, indexTable);

    load16<sortOrder>(
        keys + indexTable, values + indexTable, tableLen - indexTable - 1, tableOffset, stride, &key1, &key2,
        &key3, &key4, &key5, &key6, &key7, &key8, &key9, &key10, &key11, &key12, &key13, &key14, &key15, &key16,
        &val1, &val2, &val3, &val4, &val5, &val6, &val7, &val8, &val9, &val10, &val11, &val12, &val13, &val14,
        &val15, &val16
    );
    compareExchange16<sortOrder>(
        &key1, &key2, &key3, &key4, &key5, &key6, &key7, &key8, &key9, &key10, &key11, &key12, &key13, &key14,
        &key15, &key16, &val1, &val2, &val3, &val4, &val5, &val6, &val7, &val8, &val9, &val10, &val11, &val12,
        &val13, &val14, &val15, &val16
    );
    store16(
        keys + indexTable, values + indexTable, tableLen - indexTable - 1, tableOffset, stride, key1, key2,
        key3, key4, key5, key6, key7, key8, key9, key10, key11, key12, key13, key14, key15, key16, val1, val2,
        val3, val4, val5, val6, val7, val8, val9, val10, val11, val12, val13, val14, val15, val16
    );
}

template __global__ void multiStep4Kernel<ORDER_ASC>(data_t *keys, data_t *values, int_t tableLen, uint_t step);
template __global__ void multiStep4Kernel<ORDER_DESC>(data_t *keys, data_t *values, int_t tableLen, uint_t step);


/*
Performs bitonic merge with 5-multistep (sorts 32 elements per thread).
*/
template <order_t sortOrder>
__global__ void multiStep5Kernel(data_t *keys, data_t *values, int_t tableLen, uint_t step)
{
    uint_t stride, tableOffset, indexTable;
    data_t key1, key2, key3, key4, key5, key6, key7, key8, key9, key10, key11, key12, key13, key14, key15, key16,
        key17, key18, key19, key20, key21, key22, key23, key24, key25, key26, key27, key28, key29, key30, key31, key32;
    data_t val1, val2, val3, val4, val5, val6, val7, val8, val9, val10, val11, val12, val13, val14, val15, val16,
        val17, val18, val19, val20, val21, val22, val23, val24, val25, val26, val27, val28, val29, val30, val31, val32;

    getMultiStepParams(step, 5, stride, tableOffset, indexTable);

    load32<sortOrder>(
        keys + indexTable, values + indexTable, tableLen - indexTable - 1, tableOffset, stride, &key1, &key2,
        &key3, &key4, &key5, &key6, &key7, &key8, &key9, &key10, &key11, &key12, &key13, &key14, &key15, &key16,
        &key17, &key18, &key19, &key20, &key21, &key22, &key23, &key24, &key25, &key26, &key27, &key28, &key29,
        &key30, &key31, &key32, &val1, &val2, &val3, &val4, &val5, &val6, &val7, &val8, &val9, &val10, &val11,
        &val12, &val13, &val14, &val15, &val16, &val17, &val18, &val19, &val20, &val21, &val22, &val23, &val24,
        &val25, &val26, &val27, &val28, &val29, &val30, &val31, &val32
    );
    compareExchange32<sortOrder>(
        &key1, &key2, &key3, &key4, &key5, &key6, &key7, &key8, &key9, &key10, &key11, &key12, &key13, &key14,
        &key15, &key16, &key17, &key18, &key19, &key20, &key21, &key22, &key23, &key24, &key25, &key26, &key27,
        &key28, &key29, &key30, &key31, &key32, &val1, &val2, &val3, &val4, &val5, &val6, &val7, &val8, &val9,
        &val10, &val11, &val12, &val13, &val14, &val15, &val16, &val17, &val18, &val19, &val20, &val21, &val22,
        &val23, &val24, &val25, &val26, &val27, &val28, &val29, &val30, &val31, &val32
    );
    store32(
        keys + indexTable, values + indexTable, tableLen - indexTable - 1, tableOffset, stride, key1, key2,
        key3, key4, key5, key6, key7, key8, key9, key10, key11, key12, key13, key14, key15, key16, key17,
        key18, key19, key20, key21, key22, key23, key24, key25, key26, key27, key28, key29, key30, key31,
        key32, val1, val2, val3, val4, val5, val6, val7, val8, val9, val10, val11, val12, val13, val14,
        val15, val16, val17, val18, val19, val20, val21, val22, val23, val24, val25, val26, val27, val28,
        val29, val30, val31, val32
    );
}

template __global__ void multiStep5Kernel<ORDER_ASC>(data_t *keys, data_t *values, int_t tableLen, uint_t step);
template __global__ void multiStep5Kernel<ORDER_DESC>(data_t *keys, data_t *values, int_t tableLen, uint_t step);


/*
Global bitonic merge - needed for first step of every phase, when stride is greater than shared memory size.
*/
template <order_t sortOrder>
__global__ void bitonicMergeGlobalKernel(data_t *keys, data_t *values, uint_t tableLen, uint_t phase)
{
    uint_t stride = 1 << (phase - 1);
    uint_t pairsPerThreadBlock = (THREADS_PER_GLOBAL_MERGE_KV * ELEMS_PER_THREAD_GLOBAL_MERGE_KV) >> 1;
    uint_t indexGlobal = blockIdx.x * pairsPerThreadBlock + threadIdx.x;

    for (uint_t i = 0; i < ELEMS_PER_THREAD_GLOBAL_MERGE_KV >> 1; i++)
    {
        uint_t indexThread = indexGlobal + i * THREADS_PER_GLOBAL_MERGE_KV;
        uint_t offset = ((indexThread & (stride - 1)) << 1) + 1;
        indexThread = (indexThread / stride) * stride + ((stride - 1) - (indexThread % stride));

        uint_t index = (indexThread << 1) - (indexThread & (stride - 1));
        if (index + offset >= tableLen)
        {
            break;
        }

        compareExchange2<sortOrder>(&keys[index], &keys[index + offset], &values[index], &values[index + offset]);
    }
}

template __global__ void bitonicMergeGlobalKernel<ORDER_ASC>(
    data_t *keys, data_t *values, uint_t tableLen, uint_t step
);
template __global__ void bitonicMergeGlobalKernel<ORDER_DESC>(
    data_t *keys, data_t *values, uint_t tableLen, uint_t step
);


/*
Local bitonic merge for sections, where stride IS LOWER OR EQUAL than max shared memory.
*/
template <order_t sortOrder, bool isFirstStepOfPhase>
__global__ void bitonicMergeLocalKernel(data_t *keys, data_t *values, uint_t tableLen, uint_t step)
{
    extern __shared__ data_t mergeTile[];
    bool firstStepOfPhaseCopy = isFirstStepOfPhase;  // isFirstStepOfPhase is not editable (constant)

    uint_t elemsPerThreadBlock = THREADS_PER_LOCAL_MERGE_KV * ELEMS_PER_THREAD_LOCAL_MERGE_KV;
    uint_t offset = blockIdx.x * elemsPerThreadBlock;
    uint_t dataBlockLength = offset + elemsPerThreadBlock <= tableLen ? elemsPerThreadBlock : tableLen - offset;
    uint_t pairsPerBlockLength = dataBlockLength >> 1;

    data_t *keysTile = mergeTile;
    data_t *valuesTile = mergeTile + dataBlockLength;

    // Reads data from global to shared memory.
    for (uint_t tx = threadIdx.x; tx < dataBlockLength; tx += THREADS_PER_LOCAL_MERGE_KV)
    {
        keysTile[tx] = keys[offset + tx];
        valuesTile[tx] = values[offset + tx];
    }
    __syncthreads();

    // Bitonic merge
    for (uint_t stride = 1 << (step - 1); stride > 0; stride >>= 1)
    {
        for (uint_t tx = threadIdx.x; tx < pairsPerBlockLength; tx += THREADS_PER_LOCAL_MERGE_KV)
        {
            uint_t indexThread = tx;
            uint_t offset = stride;

            // In normalized bitonic sort, first STEP of every PHASE uses different offset than all other STEPS.
            if (firstStepOfPhaseCopy)
            {
                offset = ((tx & (stride - 1)) << 1) + 1;
                indexThread = (tx / stride) * stride + ((stride - 1) - (tx % stride));
                firstStepOfPhaseCopy = false;
            }

            uint_t index = (indexThread << 1) - (indexThread & (stride - 1));
            if (index + offset >= dataBlockLength)
            {
                break;
            }

            compareExchange2<sortOrder>(
                &keysTile[index], &keysTile[index + offset], &valuesTile[index], &valuesTile[index + offset]
            );
        }
        __syncthreads();
    }

    // Stores data from shared to global memory
    for (uint_t tx = threadIdx.x; tx < dataBlockLength; tx += THREADS_PER_LOCAL_MERGE_KV)
    {
        keys[offset + tx] = keysTile[tx];
        values[offset + tx] = valuesTile[tx];
    }
}

template __global__ void bitonicMergeLocalKernel<ORDER_ASC, true>(
    data_t *keys, data_t *values, uint_t tableLen, uint_t step
);
template __global__ void bitonicMergeLocalKernel<ORDER_ASC, false>(
    data_t *keys, data_t *values, uint_t tableLen, uint_t step
);
template __global__ void bitonicMergeLocalKernel<ORDER_DESC, true>(
    data_t *keys, data_t *values, uint_t tableLen, uint_t step
);
template __global__ void bitonicMergeLocalKernel<ORDER_DESC, false>(
    data_t *keys, data_t *values, uint_t tableLen, uint_t step
);
