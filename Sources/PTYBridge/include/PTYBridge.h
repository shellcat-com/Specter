#ifndef SPECTER_PTY_H
#define SPECTER_PTY_H
#include <sys/types.h>
int specter_start(const char *helper, const char *shell, const char *cwd, const char *termInfo,
                  int rows, int columns, int *master, int *lifetime, pid_t *pid);
int specter_resize(int fd, int rows, int columns);
#endif
