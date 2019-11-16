// © 2019 Joseph Cameron - All Rights Reserved

#ifndef JFC_ADD_TEST_TYPES 
#define JFC_ADD_TEST_TYPES

#include <tuple>

namespace type
{
    using floating_point = std::tuple<
        float, double, long double
    >;

    using signed_integral = std::tuple<
        char,
        short, short int, signed short,
        int, signed, signed int,
        long, long int, signed long, signed long int
    >;

    using unsigned_integral = std::tuple<
        unsigned char,
        unsigned short, unsigned short int,
        unsigned int,
        unsigned long, unsigned long int
    >;

    using integral = std::tuple<
        char,
        short, short int, signed short,
        int, signed, signed int,
        long, long int, signed long, signed long int, 
        
        unsigned char,
        unsigned short, unsigned short int,
        unsigned int,
        unsigned long, unsigned long int
    >;
    
    using signed_arithmetic = std::tuple<
        float, double, long double,
        
        char,
        short, short int, signed short,
        int, signed, signed int,
        long, long int, signed long, signed long int
    >;

    using unsigned_arithmetic = std::tuple<
        char,
        short, short int, signed short,
        int, signed, signed int,
        long, long int, signed long, signed long int
    >;

    using arithmetic = std::tuple<
        float, double, long double,
        
        char,
        short, short int, signed short,
        int, signed, signed int,
        long, long int, signed long, signed long int, 
        
        unsigned char,
        unsigned short, unsigned short int,
        unsigned int,
        unsigned long, unsigned long int
    >;
}

#endif

