// © Joseph Cameron - All Rights Reserved
//
// Includes the library's PUBLIC header by its public path and nothing else. If jfc_add_tests stops
// propagating the owning project's include directories, this stops compiling. \see §7b
#include <probe/probe.h>
int probe_test_entry() { return probe::answer(); }
