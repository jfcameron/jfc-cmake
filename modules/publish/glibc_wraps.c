/* © Joseph Cameron - MIT License
 *
 * **What the C++ library linked into a published linux build asks of glibc, that glibc 2.34 does not have.**
 *
 * A published linux build carries its C++ library and gcc's runtime inside it (-static-libstdc++ -static-libgcc), so
 * a user's older C++ library does not matter -- SteamOS's lacked a symbol std::format here asks for, and the program
 * would not start. But those were built against this machine's glibc, and call three functions newer than the floor
 * (publish.cmake), which glibc.h cannot bind to older versions: it is forced into what is compiled here, not
 * into what was compiled before. So the programs are linked with `--wrap` for each, and their calls come here instead:
 *
 * - `_dl_find_object` (2.35): how gcc's unwinder finds an exception's tables. Answered by dl_iterate_phdr, as the
 *   unwinder itself did before 2.35. **Get this wrong and every exception terminates the program.**
 * - `arc4random` (2.36): std::random_device's. Answered by getrandom (2.25).
 * - `__isoc23_strtoul` (2.38): C23's strtoul, which reads a 0b prefix. Answered by strtoul.
 *
 * Compiled into the programs publish packs, and nothing else: jfc_publish, given GLIBC. \see glibc.h
 */

#define _GNU_SOURCE

#include <dlfcn.h>
#include <link.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <sys/random.h>

extern unsigned long jfc_publish_strtoul(const char *aText, char **aEnd, int aBase) __asm__("strtoul");

struct jfc_publish_finding {
    uintptr_t address;
    struct dl_find_object *pResult;
    int found;
};

static int jfc_publish_look_in(struct dl_phdr_info *pInfo, size_t aSize, void *pData) {
    struct jfc_publish_finding *pFinding = pData;

    uintptr_t low = UINTPTR_MAX, high = 0;
    void *pEhFrame = NULL;
    int holds = 0;

    (void)aSize;

    for (ElfW(Half) each = 0; each < pInfo->dlpi_phnum; ++each) {
        const ElfW(Phdr) *const pSegment = &pInfo->dlpi_phdr[each];

        if (pSegment->p_type == PT_LOAD) {
            const uintptr_t start = (uintptr_t)pInfo->dlpi_addr + pSegment->p_vaddr;
            const uintptr_t end = start + pSegment->p_memsz;

            if (start < low) low = start;
            if (end > high) high = end;

            if (pFinding->address >= start && pFinding->address < end) holds = 1;
        }
        else if (pSegment->p_type == PT_GNU_EH_FRAME)
            pEhFrame = (void *)((uintptr_t)pInfo->dlpi_addr + pSegment->p_vaddr);
    }

    if (!holds) return 0;

    memset(pFinding->pResult, 0, sizeof *pFinding->pResult);

    pFinding->pResult->dlfo_map_start = (void *)low;
    pFinding->pResult->dlfo_map_end = (void *)high;
    pFinding->pResult->dlfo_eh_frame = pEhFrame;

    pFinding->found = 1;

    return 1;
}

int __wrap__dl_find_object(void *pAddress, struct dl_find_object *pResult) {
    struct jfc_publish_finding finding = {(uintptr_t)pAddress, pResult, 0};

    dl_iterate_phdr(jfc_publish_look_in, &finding);

    return finding.found ? 0 : -1;
}

uint32_t __wrap_arc4random(void) {
    uint32_t out = 0;

    while (getrandom(&out, sizeof out, 0) != (ssize_t)sizeof out) {}

    return out;
}

unsigned long __wrap___isoc23_strtoul(const char *aText, char **aEnd, int aBase) {
    return jfc_publish_strtoul(aText, aEnd, aBase);
}
