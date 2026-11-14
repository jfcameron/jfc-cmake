/* © Joseph Cameron - MIT License
 *
 * Binds glibc symbols to their oldest versions, so a published linux build starts on older machines. Forced into
 * every translation unit of a published build (glibc_floor.cmake); wants binutils 2.36 or newer.
 */

#ifndef JFC_PUBLISH_GLIBC_H
#define JFC_PUBLISH_GLIBC_H

/* nothing may be included here: a libc header read this early hides mremap from LuaJIT */
#if defined(__linux__)

#ifdef __ASSEMBLER__
#define JFC_OLDEST(aName, aVersion) .symver aName,aName@aVersion,remove
#define JFC_WAS(aName, aWas, aVersion) .symver aName,aWas@aVersion,remove
#else
#define JFC_OLDEST(aName, aVersion) __asm__(".symver " #aName "," #aName "@" #aVersion ",remove")
#define JFC_WAS(aName, aWas, aVersion) __asm__(".symver " #aName "," #aWas "@" #aVersion ",remove")
#endif

JFC_OLDEST(cosh, GLIBC_2.2.5);
JFC_OLDEST(sinh, GLIBC_2.2.5);

JFC_OLDEST(acosf, GLIBC_2.2.5);
JFC_OLDEST(atan2f, GLIBC_2.2.5);
JFC_OLDEST(sqrtf, GLIBC_2.2.5);
JFC_OLDEST(remainder, GLIBC_2.2.5);
JFC_OLDEST(remainderf, GLIBC_2.2.5);
JFC_OLDEST(asinf, GLIBC_2.2.5);
JFC_OLDEST(log10f, GLIBC_2.2.5);
JFC_OLDEST(sinhf, GLIBC_2.2.5);

JFC_OLDEST(fmod, GLIBC_2.2.5);
JFC_OLDEST(fmodf, GLIBC_2.2.5);

JFC_OLDEST(hypotf, GLIBC_2.2.5);
JFC_OLDEST(hypot, GLIBC_2.2.5);

/* the __isoc23_ names _GNU_SOURCE turns on, bound back to the functions they were */
JFC_WAS(__isoc23_strtol, strtol, GLIBC_2.2.5);
JFC_WAS(__isoc23_strtoll, strtoll, GLIBC_2.2.5);
JFC_WAS(__isoc23_strtoul, strtoul, GLIBC_2.2.5);
JFC_WAS(__isoc23_strtoull, strtoull, GLIBC_2.2.5);
JFC_WAS(__isoc23_sscanf, sscanf, GLIBC_2.2.5);
JFC_WAS(__isoc23_fscanf, fscanf, GLIBC_2.2.5);
JFC_WAS(__isoc23_scanf, scanf, GLIBC_2.2.5);

JFC_OLDEST(exp, GLIBC_2.2.5);
JFC_OLDEST(log, GLIBC_2.2.5);
JFC_OLDEST(pow, GLIBC_2.2.5);
JFC_OLDEST(expf, GLIBC_2.2.5);
JFC_OLDEST(logf, GLIBC_2.2.5);
JFC_OLDEST(powf, GLIBC_2.2.5);
JFC_OLDEST(log2f, GLIBC_2.2.5);
JFC_OLDEST(exp2f, GLIBC_2.2.5);

#undef JFC_OLDEST
#undef JFC_WAS

#endif /* __linux__ */

#endif
