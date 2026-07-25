/*
 * LD_PRELOAD helper: when any Wayland client calls xdg_toplevel.set_minimized
 * (titlebar minimize button), run hypr-minimize so Hyprland actually hides it.
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include <wayland-client-core.h>

#ifndef XDG_TOPLEVEL_SET_MINIMIZED
#define XDG_TOPLEVEL_SET_MINIMIZED 13
#endif

static void trigger_minimize(void) {
    const char *bin = getenv("HYPR_MINIMIZE_BIN");
    if (!bin || !*bin)
        bin = "hypr-minimize";
    pid_t pid = fork();
    if (pid == 0) {
        /* detach from parent app */
        setsid();
        execl(bin, "hypr-minimize", (char *)NULL);
        _exit(127);
    }
}

static int is_minimize_req(struct wl_proxy *proxy, uint32_t opcode) {
    if (!proxy || opcode != XDG_TOPLEVEL_SET_MINIMIZED)
        return 0;
    const char *cls = wl_proxy_get_class(proxy);
    return cls && strcmp(cls, "xdg_toplevel") == 0;
}

struct wl_proxy *wl_proxy_marshal_array_flags(struct wl_proxy *proxy, uint32_t opcode,
                                              const struct wl_interface *interface,
                                              uint32_t version, uint32_t flags,
                                              union wl_argument *args) {
    typedef struct wl_proxy *(*fn_t)(struct wl_proxy *, uint32_t, const struct wl_interface *,
                                     uint32_t, uint32_t, union wl_argument *);
    static fn_t real = NULL;
    if (!real)
        real = (fn_t)dlsym(RTLD_NEXT, "wl_proxy_marshal_array_flags");
    if (is_minimize_req(proxy, opcode))
        trigger_minimize();
    return real(proxy, opcode, interface, version, flags, args);
}

void wl_proxy_marshal_array(struct wl_proxy *proxy, uint32_t opcode, union wl_argument *args) {
    typedef void (*fn_t)(struct wl_proxy *, uint32_t, union wl_argument *);
    static fn_t real = NULL;
    if (!real)
        real = (fn_t)dlsym(RTLD_NEXT, "wl_proxy_marshal_array");
    if (is_minimize_req(proxy, opcode))
        trigger_minimize();
    real(proxy, opcode, args);
}
