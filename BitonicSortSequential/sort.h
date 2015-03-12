#ifndef BITONIC_SORT_SEQUENTIAL_H
#define BITONIC_SORT_SEQUENTIAL_H

#include "../Utils/data_types_common.h"
#include "../Utils/sort_interface.h"


class BitonicSortSequential : public SortSequential
{
private:
    std::string _sortName = "Bitonic sort sequential";

    // Key only
    template <order_t sortOrder>
    void bitonicSortSequentialKeyOnly(data_t *h_keys, uint_t arrayLength);
    void sortKeyOnly();

    // Key-value
    template <order_t sortOrder>
    void bitonicSortSequentialKeyValue(data_t *h_keys, data_t *h_values, uint_t arrayLength);
    void sortKeyValue();

public:
    std::string getSortName()
    {
        return this->_sortName;
    }
};

#endif
