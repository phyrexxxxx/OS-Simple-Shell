#ifndef SHELL_H
#define SHELL_H

#include <sys/types.h>
#include <stdarg.h>

/* Forward declarations */
struct process;
struct job;

/* Buffer sizes and limits */
#define MAX_JOBS 20
#define MAX_HISTORY 16
#define PATH_LEN 1024
#define LINE_LEN 1024
#define TOK_LEN 64
#define TOK_DELIM " \t\r\n\a"
#define PID_BUF 1024

/* Execution modes */
enum {
    FG_EXEC = 1,
    BG_EXEC = 0,
    PIPE_EXEC = 2,
};

/* Child process states */
enum {
    PROC_RUNNING,
    PROC_DONE,
    PROC_SUSPENDED,
    PROC_CONTINUED,
    PROC_TERMINATED
};

/* Global shell state */
struct shell_info {
    char home_dir[PATH_LEN];
    char cwd[PATH_LEN];
    char user[TOK_LEN];
    struct job *jobs[MAX_JOBS + 1];
};

extern struct shell_info shell;

/* History buffer - shared across modules */
extern char history[MAX_HISTORY][LINE_LEN];
extern int history_count;

/* Shell initialization and control functions */
void shell_init(void);
void print_prompt(void);
void update_cwd(void);
void pprintf(int fd, const char *fmt, ...);

/* History management */
void add_history(const char *line);

/* Job management */
int get_job_id(void);
int launch_job(struct job *j);
int launch_process(struct job *j, struct process *p, int in_fd, int out_fd);

/* Process ID helpers */
pid_t get_parent_pid(pid_t pid);
void find_children(pid_t parent_pid, int out_fd);

#endif /* SHELL_H */