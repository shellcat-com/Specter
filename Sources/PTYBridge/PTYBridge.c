#include "PTYBridge.h"
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <spawn.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <poll.h>
#include <signal.h>
extern char **environ;

int specter_start(const char *helper, const char *shell, const char *cwd, const char *termInfo,
                  int rows, int columns, int *master, int *lifetime, pid_t *pid) {
    int pair[2];
    if (socketpair(AF_UNIX, SOCK_STREAM, 0, pair) != 0) return errno;
    fcntl(pair[0], F_SETFD, FD_CLOEXEC); fcntl(pair[1], F_SETFD, FD_CLOEXEC);
    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);
    // Descriptor 3 is the only inherited IPC endpoint, irrespective of pair allocation.
    posix_spawn_file_actions_adddup2(&actions, pair[1], 3);
    if (pair[0] != 3) posix_spawn_file_actions_addclose(&actions, pair[0]);
    if (pair[1] != 3) posix_spawn_file_actions_addclose(&actions, pair[1]);
    posix_spawnattr_t attr; posix_spawnattr_init(&attr);
    posix_spawnattr_setflags(&attr, POSIX_SPAWN_CLOEXEC_DEFAULT);
    char rowText[16], colText[16];
    snprintf(rowText, sizeof(rowText), "%d", rows); snprintf(colText, sizeof(colText), "%d", columns);
    char *argv[] = {(char *)helper, (char *)shell, (char *)cwd, rowText, colText, (char *)termInfo, NULL};
    int result = posix_spawn(pid, helper, &actions, &attr, argv, environ);
    posix_spawn_file_actions_destroy(&actions); posix_spawnattr_destroy(&attr); close(pair[1]);
    if (result) { close(pair[0]); return result; }
    struct pollfd pollfd = {.fd = pair[0], .events = POLLIN};
    if (poll(&pollfd, 1, 5000) <= 0) { close(pair[0]); kill(*pid, SIGTERM); waitpid(*pid, NULL, 0); return ETIMEDOUT; }
    char payload;
    struct iovec iov = {.iov_base = &payload, .iov_len = 1};
    union { struct cmsghdr alignment; char bytes[CMSG_SPACE(sizeof(int))]; } control;
    memset(&control, 0, sizeof(control));
    struct msghdr message = {0}; message.msg_iov = &iov; message.msg_iovlen = 1;
    message.msg_control = control.bytes; message.msg_controllen = sizeof(control.bytes);
    ssize_t count = recvmsg(pair[0], &message, 0);
    struct cmsghdr *header = CMSG_FIRSTHDR(&message);
    if (count != 1 || !header || header->cmsg_type != SCM_RIGHTS || header->cmsg_len < CMSG_LEN(sizeof(int))) {
        close(pair[0]); kill(*pid, SIGTERM); waitpid(*pid, NULL, 0); return EIO;
    }
    memcpy(master, CMSG_DATA(header), sizeof(int));
    fcntl(*master, F_SETFL, fcntl(*master, F_GETFL) | O_NONBLOCK);
    fcntl(*master, F_SETFD, FD_CLOEXEC);
    int yes = 1; setsockopt(pair[0], SOL_SOCKET, SO_NOSIGPIPE, &yes, sizeof(yes));
    *lifetime = pair[0]; return 0;
}
int specter_resize(int fd, int rows, int columns) {
    struct winsize size = {.ws_row = (unsigned short)rows, .ws_col = (unsigned short)columns};
    return ioctl(fd, TIOCSWINSZ, &size);
}
