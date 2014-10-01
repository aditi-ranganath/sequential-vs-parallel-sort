#include <stdio.h>
#include <stdint.h>
#include <Windows.h>

#include <cuda.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include "data_types.h"
#include "constants.h"


void startStopwatch(LARGE_INTEGER* start) {
    QueryPerformanceCounter(start);
}

void endStopwatch(LARGE_INTEGER start, char* comment, char deviceType) {
    LARGE_INTEGER frequency;
    LARGE_INTEGER end;
    double elapsedTime;
    char* device;

    QueryPerformanceFrequency(&frequency);
    QueryPerformanceCounter(&end);
    elapsedTime = (end.QuadPart - start.QuadPart) * 1000.0 / frequency.QuadPart;

    if (deviceType == 'H' || deviceType == 'h') {
        device = "HOST   >>> ";
    } else if (deviceType == 'D' || deviceType == 'd') {
        device = "DEVICE >>> ";
    } else if (deviceType == 'M' || deviceType == 'm') {
        device = "MEMCPY >>> ";
    } else {
        device = "";
    }

    printf("%s%s: %.5lf ms\n", device, comment, elapsedTime);
}

void endStopwatch(LARGE_INTEGER start, char* comment) {
    endStopwatch(start, comment, NULL);
}

/*
Keys are filled with random numbers and values are filled with consecutive naumbers.
*/
void fillTable(el_t *table, uint_t tableLen, uint_t interval) {
    for (uint_t i = 0; i < tableLen; i++) {
        table[i].key = rand() % interval;
        table[i].val = i;
    }
}

void compareArrays(el_t* array1, el_t* array2, uint_t arrayLen) {
    for (uint_t i = 0; i < arrayLen; i++) {
        if (array1[i].key != array2[i].key) {
            printf("Arrays are different: array1[%d] = %d, array2[%d] = %d.\n", i, array1[i].key, i, array2[i].key);
            return;
        }
    }

    printf("Arrays are the same.\n");
}

void printTable(el_t *table, uint_t startIndex, uint_t endIndex) {
    for (uint_t i = startIndex; i <= endIndex; i++) {
        char* separator = i == endIndex ? "" : ", ";
        printf("%2d%s", table[i].key, separator);
    }
    printf("\n\n");

    for (uint_t i = startIndex; i <= endIndex; i++) {
        char* separator = i == endIndex ? "" : ", ";
        printf("%2d%s", table[i].val, separator);
    }
    printf("\n\n");
}

void printTable(el_t *table, uint_t tableLen) {
    printTable(table, 0, tableLen - 1);
}