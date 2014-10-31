#include "data_types.h"


/*
Because of circular dependencies between stuctures, methods have to be implemented after structure definitons.
*/

/* HostGlobalSequence */

void HostGlobalSequence::setInitSeq(uint_t tableLen, data_t initMinVal, data_t initMaxVal) {
    start = 0;
    length = tableLen;
    oldStart = start;
    oldLength = length;
    minVal = initMinVal;
    maxVal = initMaxVal;
    direction = PRIMARY_MEM_TO_BUFFER;
}

void HostGlobalSequence::setLowerSeq(h_glob_seq_t globalSeqHost, d_glob_seq_t globalSeqDev) {
    start = globalSeqHost.oldStart;
    length = globalSeqDev.offsetLower;
    oldStart = start;
    oldLength = length;
    minVal = globalSeqHost.minVal;
    maxVal = globalSeqDev.lowerSeqMaxVal;
    direction = (TransferDirection) !globalSeqHost.direction;
}

void HostGlobalSequence::setGreaterSeq(h_glob_seq_t globalSeqHost, d_glob_seq_t globalSeqDev) {
    start = globalSeqHost.oldStart + globalSeqHost.length - globalSeqDev.offsetGreater;
    length = globalSeqDev.offsetGreater;
    oldStart = start;
    oldLength = length;
    minVal = globalSeqDev.greaterSeqMinVal;
    maxVal = globalSeqHost.maxVal;
    direction = (TransferDirection) !globalSeqHost.direction;
}


/* DeviceGlobalSequence */

void DeviceGlobalSequence::setFromHostSeq(h_glob_seq_t globalSeqHost, uint_t startThreadBlock,
                                         uint_t threadBlocksPerSequence) {
    start = globalSeqHost.start;
    length = globalSeqHost.length;
    pivot = (globalSeqHost.minVal + globalSeqHost.maxVal) / 2;
    direction = globalSeqHost.direction;

    startThreadBlockIdx = startThreadBlock;
    threadBlockCounter = threadBlocksPerSequence;

    offsetLower = 0;
    offsetGreater = 0;

    greaterSeqMinVal = MAX_VAL;
    lowerSeqMaxVal = MIN_VAL;
}


/* LocalSequence */

void LocalSequence::setLowerSeq(h_glob_seq_t globalSeqHost, d_glob_seq_t globalSeqDev) {
    start = globalSeqHost.oldStart;
    length = globalSeqDev.offsetLower;
    direction = (TransferDirection) !globalSeqHost.direction;
}

void LocalSequence::setGreaterSeq(h_glob_seq_t globalSeqHost, d_glob_seq_t globalSeqDev) {
    start = globalSeqHost.oldStart + globalSeqHost.length - globalSeqDev.offsetGreater;
    length = globalSeqDev.offsetGreater;
    direction = (TransferDirection) !globalSeqHost.direction;
}

void LocalSequence::setFromGlobalSeq(h_glob_seq_t globalParams) {
    start = globalParams.start;
    length = globalParams.length;
    direction = globalParams.direction;
}
