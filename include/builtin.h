#ifndef BUILTIN_H
#define BUILTIN_H

#include "command.h"

/* Built-in command function signature */
typedef int (*builtin_fn)(struct process *proc, int in_fd, int out_fd);

/* Built-in command table */
struct builtin_cmd {
    const char *name;
    builtin_fn func;
    int id;
};

/* Built-in command table and count */
extern struct builtin_cmd builtins[];
extern const int num_builtins;

/* Built-in command functions */
int cmd_exit(struct process *proc, int in_fd, int out_fd);
int cmd_cd(struct process *proc, int in_fd, int out_fd);
int cmd_help(struct process *proc, int in_fd, int out_fd);
int cmd_echo(struct process *proc, int in_fd, int out_fd);
int cmd_record(struct process *proc, int in_fd, int out_fd);
int cmd_replay(struct process *proc, int in_fd, int out_fd);
int cmd_mypid(struct process *proc, int in_fd, int out_fd);

/* Command type detection */
int get_cmd_id(const char *name);

#endif /* BUILTIN_H */