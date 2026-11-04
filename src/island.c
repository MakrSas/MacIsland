#include <dlfcn.h>
#include <string.h>
#include <stdlib.h>
extern int IsAppleInternalBuild(void);
static int fake_IsAppleInternalBuild(void) {
    const char *n = getprogname();
    if (n && strcmp(n, "MenuBarAgent") == 0) return 1;
    return IsAppleInternalBuild();
}
__attribute__((used)) static struct { const void *r; const void *o; } interposers[]
__attribute__((section("__DATA,__interpose"))) = {
    { (const void *)fake_IsAppleInternalBuild, (const void *)IsAppleInternalBuild },
};
