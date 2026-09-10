#include <sys/socket.h>
#include <sys/event.h>
#include <sys/wait.h>
#include <sys/ioctl.h>
#include <util.h>
#include <unistd.h>
#include <signal.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <fcntl.h>
#include <time.h>

static void signal_owned(pid_t child, pid_t foreground, int signal) {
    if (foreground > 0 && foreground != child && getsid(foreground) == child) kill(-foreground, signal);
    kill(-child, signal);
}
static void shutdown_child(pid_t child, int master, int *status) {
    pid_t foreground = tcgetpgrp(master);
    signal_owned(child, foreground, SIGHUP);
    signal_owned(child, foreground, SIGCONT);
    close(master);
    struct timespec pause = {.tv_nsec = 10000000};
    for (int tick = 0; tick < 100; tick++) {
        if (waitpid(child, status, WNOHANG) == child) return;
        nanosleep(&pause, NULL);
    }
    signal_owned(child, foreground, SIGTERM);
    for (int tick = 0; tick < 100; tick++) {
        if (waitpid(child, status, WNOHANG) == child) return;
        nanosleep(&pause, NULL);
    }
    signal_owned(child, foreground, SIGKILL);
    while (waitpid(child, status, 0) < 0 && errno == EINTR) {}
}
int main(int argc, char **argv) {
    if (argc != 6) return 64;
    signal(SIGPIPE, SIG_IGN);
    fcntl(3, F_SETFD, FD_CLOEXEC);
    setenv("TERM", "specter", 1); setenv("COLORTERM", "truecolor", 1); setenv("TERM_PROGRAM", "Specter", 1);
    if (*argv[5]) setenv("TERMINFO", argv[5], 1);
    if (!getenv("LANG")) setenv("LANG", "en_US.UTF-8", 1);
    char loginName[1024]; const char *base = strrchr(argv[1], '/');
    snprintf(loginName, sizeof(loginName), "-%s", base ? base + 1 : argv[1]);
    char *shellArgs[] = {loginName, NULL};
    struct winsize size = {.ws_row = (unsigned short)atoi(argv[3]), .ws_col = (unsigned short)atoi(argv[4])};
    int master = -1;
    pid_t child = forkpty(&master, NULL, NULL, &size);
    if (child < 0) return 71;
    if (child == 0) {
        for (int sig = 1; sig < NSIG; sig++) signal(sig, SIG_DFL);
        sigset_t mask; sigemptyset(&mask); sigprocmask(SIG_SETMASK, &mask, NULL);
        close(3);
        if (chdir(argv[2]) != 0) { const char text[] = "Specter: working directory unavailable\r\n"; write(2, text, sizeof(text)-1); _exit(126); }
        execv(argv[1], shellArgs);
        const char text[] = "Specter: shell execution failed\r\n"; write(2, text, sizeof(text)-1); _exit(127);
    }
    char payload = 'P'; struct iovec iov = {.iov_base = &payload, .iov_len = 1};
    union { struct cmsghdr alignment; char bytes[CMSG_SPACE(sizeof(int))]; } control;
    memset(&control, 0, sizeof(control));
    struct msghdr message = {0}; message.msg_iov = &iov; message.msg_iovlen = 1;
    message.msg_control = control.bytes; message.msg_controllen = sizeof(control.bytes);
    struct cmsghdr *header = CMSG_FIRSTHDR(&message);
    header->cmsg_level = SOL_SOCKET; header->cmsg_type = SCM_RIGHTS; header->cmsg_len = CMSG_LEN(sizeof(int));
    memcpy(CMSG_DATA(header), &master, sizeof(master));
    int status = 0;
    if (sendmsg(3, &message, 0) != 1) { shutdown_child(child, master, &status); return 74; }
    int queue = kqueue();
    struct kevent changes[2], event;
    EV_SET(&changes[0], 3, EVFILT_READ, EV_ADD, 0, 0, NULL);
    EV_SET(&changes[1], child, EVFILT_PROC, EV_ADD | EV_ONESHOT, NOTE_EXIT, 0, NULL);
    if (queue < 0 || kevent(queue, changes, 2, NULL, 0, NULL) < 0) {
        shutdown_child(child, master, &status); close(3); return 71;
    }
    for (;;) {
        int result = kevent(queue, NULL, 0, &event, 1, NULL);
        if (result < 0 && errno == EINTR) continue;
        if (result < 0 || event.filter == EVFILT_READ) { shutdown_child(child, master, &status); break; }
        if (event.filter == EVFILT_PROC) {
            while (waitpid(child, &status, 0) < 0 && errno == EINTR) {}
            close(master); break;
        }
    }
    write(3, &status, sizeof(status)); close(3); close(queue);
    return 0;
}
