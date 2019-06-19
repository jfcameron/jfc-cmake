// © 2019 Joseph Cameron - All Rights Reserved

#ifndef JFC_ADD_TEST_TYPES 
#define JFC_ADD_TEST_TYPES

#include <tuple>

namespace type
{
    using floating_point = std::tuple<float, double, long double>;

    using integral = std::tuple<
        char, unsigned char,
        short, short int, signed short, unsigned short, unsigned short int,
        int, signed, signed int, unsigned, unsigned int,
        long, long int, signed long, signed long int, unsigned long, unsigned long int,
        long long, long long int, signed long long, signed long long int, unsigned long long, unsigned long long int
    >;
}

#endif

