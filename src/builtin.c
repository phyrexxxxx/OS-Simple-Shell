/*
 * builtin.c - Built-in command implementations
 */

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "../include/builtin.h"
#include "../include/command.h"
#include "../include/shell.h"

/* Table of built-in commands */
struct builtin_cmd builtins[] = {
    {"exit", cmd_exit, CMD_EXIT},       {"cd", cmd_cd, CMD_CD},
    {"help", cmd_help, CMD_HELP},       {"echo", cmd_echo, CMD_ECHO},
    {"record", cmd_record, CMD_RECORD}, {"replay", cmd_replay, CMD_REPLAY},
    {"mypid", cmd_mypid, CMD_MYPID},
};
const int num_builtins = sizeof(builtins) / sizeof(*builtins);

/* Determine command type by name, return CMD_* */
int get_cmd_id(const char *name)
{
    for (int i = 0; i < num_builtins; i++) {
        if (strcmp(name, builtins[i].name) == 0)
            return builtins[i].id;
    }
    return CMD_EXTERNAL;
}

/* Built-in: help - list available built-ins */
int cmd_help(struct process *proc, int in_fd, int out_fd)
{
    (void) proc;
    (void) in_fd;
    pprintf(out_fd,
            "--------------------------------\n"
            "Simple Shell Built-ins:\n"
            "  help\t\tShow this help menu\n"
            "  cd [dir]\tChange directory to [dir] or $HOME\n"
            "  echo [-n]\tPrint arguments\n"
            "  record\tShow last %d commands\n"
            "  replay N\tRe-execute command #N from history\n"
            "  mypid [-i|-p|-c] [pid]\tShow process IDs\n"
            "  exit\t\tExit the shell\n"
            "--------------------------------\n",
            MAX_HISTORY);
    return 1;
}

/* Built-in: cd - change working directory */
int cmd_cd(struct process *proc, int in_fd, int out_fd)
{
    (void) in_fd;
    (void) out_fd;
    if (proc->argc == 1) {
        chdir(shell.home_dir);
    } else {
        if (chdir(proc->argv[1]) < 0)
            pprintf(STDERR_FILENO, "cd: %s: %s\n", proc->argv[1], strerror(errno));
    }
    update_cwd();
    return 1;
}

/* Built-in: echo [-n] */
int cmd_echo(struct process *proc, int in_fd, int out_fd)
{
    (void) in_fd;
    int start = 1, newline = 1;
    if (proc->argc > 1 && strcmp(proc->argv[1], "-n") == 0) {
        newline = 0;
        start = 2;
    }
    for (int i = start; i < proc->argc; i++) {
        pprintf(out_fd, "%s", proc->argv[i]);
        if (i < proc->argc - 1)
            pprintf(out_fd, " ");
    }
    if (newline)
        pprintf(out_fd, "\n");
    return 1;
}

/* Built-in: record - show history */
int cmd_record(struct process *proc, int in_fd, int out_fd)
{
    (void) proc;
    (void) in_fd;
    for (int i = 0; i < history_count; i++) {
        pprintf(out_fd, "%2d  %s\n", i + 1, history[i]);
    }
    return 1;
}

/* Built-in: mypid - [-i|-p|-c] [pid] */
int cmd_mypid(struct process *proc, int in_fd, int out_fd)
{
    (void) in_fd;

    if (proc->argc < 2) {
        pprintf(STDERR_FILENO, "usage: mypid [-i|-p|-c] [pid]\n");
        return -1;
    }

    const char *opt = proc->argv[1];

    if (strcmp(opt, "-i") == 0) {
        /* -i: print current process PID (ignore number argument) */
        pprintf(out_fd, "%d\n", getpid());
        return 1;
    }

    if (proc->argc < 3) {
        pprintf(STDERR_FILENO, "mypid %s: missing pid argument\n", opt);
        return -1;
    }

    pid_t target_pid = atoi(proc->argv[2]);

    if (strcmp(opt, "-p") == 0) {
        /* -p: print parent's PID */
        pid_t ppid = get_parent_pid(target_pid);
        if (ppid == -1) {
            pprintf(STDERR_FILENO, "mypid -p: process id not exist\n");
            return -1;
        }
        pprintf(out_fd, "%d\n", ppid);
        return 1;
    } else if (strcmp(opt, "-c") == 0) {
        /* -c: print children's PIDs */
        find_children(target_pid, out_fd);
        return 1;
    } else {
        pprintf(STDERR_FILENO, "mypid: invalid option %s\n", opt);
        return -1;
    }
}

/* Built-in: replay N - should not be called directly in normal cases
 * since replay is handled at parse time, but handle error cases */
int cmd_replay(struct process *proc, int in_fd, int out_fd)
{
    (void) in_fd;
    (void) out_fd;

    /* This function should rarely be called since replay is handled in parse_line */
    if (proc->argc != 2) {
        pprintf(STDERR_FILENO, "usage: replay N\n");
        return -1;
    }

    int idx = atoi(proc->argv[1]);
    if (idx < 1 || idx > history_count) {
        pprintf(STDERR_FILENO, "replay: invalid index %d\n", idx);
        return -1;
    }

    /* Should not reach here in normal execution */
    pprintf(STDERR_FILENO, "replay: unexpected error\n");
    return -1;
}

int cmd_exit(struct process *proc, int in_fd, int out_fd)
{
    (void) proc;
    (void) in_fd;
    (void) out_fd;
    exit(0);
}