/*
 * shell.c - Shell main loop and process control
 */

#define _GNU_SOURCE
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <pwd.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include "../include/builtin.h"
#include "../include/command.h"
#include "../include/shell.h"

/* Global shell state */
struct shell_info shell;

/* Helper: update current working directory in shell state */
void update_cwd()
{
    if (getcwd(shell.cwd, PATH_LEN) == NULL) {
        perror("getcwd");
    }
}

/* Helper: write to fd or stdout interchangeably */
void pprintf(int fd, const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    if (fd == STDOUT_FILENO) {
        vprintf(fmt, ap);
    } else {
        vdprintf(fd, fmt, ap);
    }
    va_end(ap);
}

/* Initialize shell: set pgid, ignore signals, load user info */
void shell_init()
{
    /* ignore interactive signals */
    signal(SIGINT, SIG_IGN);
    signal(SIGQUIT, SIG_IGN);
    signal(SIGTSTP, SIG_IGN);
    signal(SIGTTIN, SIG_IGN);

    /* set process group */
    pid_t pid = getpid();
    setpgid(pid, pid);
    tcsetpgrp(STDIN_FILENO, pid);

    /* load user info */
    struct passwd *pw = getpwuid(getuid());
    strncpy(shell.home_dir, pw->pw_dir, PATH_LEN);
    getlogin_r(shell.user, TOK_LEN);
    update_cwd();

    /* clear job slots */
    for (int i = 0; i <= MAX_JOBS; i++)
        shell.jobs[i] = NULL;
}

/* Print shell prompt (with current directory) */
void print_prompt()
{
    pprintf(STDOUT_FILENO, "%s:%s >>> $ ", shell.user, shell.cwd);
}

/* Add command line to history buffer */
void add_history(const char *line)
{
    if (*line == '\0')
        return;
    if (history_count < MAX_HISTORY) {
        strcpy(history[history_count++], line);
    } else {
        /* shift oldest out */
        memmove(history, history + 1, (MAX_HISTORY - 1) * LINE_LEN);
        strcpy(history[MAX_HISTORY - 1], line);
    }
}

/* Helper: get parent PID from /proc/<pid>/stat */
pid_t get_parent_pid(pid_t pid)
{
    char path[256];
    char line[1024];
    pid_t ppid = 0;

    snprintf(path, sizeof(path), "/proc/%d/stat", pid);
    FILE *fp = fopen(path, "r");
    if (!fp) {
        return -1; /* process doesn't exist */
    }

    if (fgets(line, sizeof(line), fp)) {
        /* Parse stat file format: pid (comm) state ppid ... */
        char *token, *saveptr;
        int field = 0;

        for (token = strtok_r(line, " ", &saveptr); token; token = strtok_r(NULL, " ", &saveptr)) {
            field++;
            if (field == 4) { /* 4th field is ppid */
                ppid = atoi(token);
                break;
            }
        }
    }

    fclose(fp);
    return ppid;
}

/* Helper: find all child processes of given PID */
void find_children(pid_t parent_pid, int out_fd)
{
    DIR *proc_dir;
    struct dirent *entry;
    pid_t pid;

    proc_dir = opendir("/proc");
    if (!proc_dir) {
        perror("opendir /proc");
        return;
    }

    while ((entry = readdir(proc_dir)) != NULL) {
        /* Check if directory name is a number (PID) */
        if (strspn(entry->d_name, "0123456789") == strlen(entry->d_name)) {
            pid = atoi(entry->d_name);
            if (pid > 0 && get_parent_pid(pid) == parent_pid) {
                pprintf(out_fd, "%d\n", pid);
            }
        }
    }

    closedir(proc_dir);
}

/* Launch a single process, handling built-in or exec */
int launch_process(struct job *j, struct process *p, int in_fd, int out_fd)
{
    /* handle input/output redirection */
    int infile_fd = in_fd;
    int outfile_fd = out_fd;

    if (p->infile) {
        infile_fd = open(p->infile, O_RDONLY);
        if (infile_fd < 0) {
            perror(p->infile);
            return -1;
        }
    }

    if (p->outfile) {
        outfile_fd = open(p->outfile, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (outfile_fd < 0) {
            perror(p->outfile);
            if (p->infile && infile_fd != in_fd)
                close(infile_fd);
            return -1;
        }
    }

    /* built-in command ----- */
    if (p->type != CMD_EXTERNAL) {
        /* find function and call */
        for (int i = 0; i < num_builtins; i++) {
            if (builtins[i].id == p->type) {
                int ret = builtins[i].func(p, infile_fd, outfile_fd);
                /* close redirected files */
                if (p->infile && infile_fd != in_fd)
                    close(infile_fd);
                if (p->outfile && outfile_fd != out_fd)
                    close(outfile_fd);
                return ret;
            }
        }
    }

    /* external command ----- */
    pid_t pid = fork();
    if (pid == 0) {
        /* child resets signals and I/O */
        signal(SIGINT, SIG_DFL);
        signal(SIGQUIT, SIG_DFL);
        signal(SIGTSTP, SIG_DFL);
        signal(SIGTTIN, SIG_DFL);
        signal(SIGTTOU, SIG_DFL);

        /* set up input/output redirection */
        if (infile_fd != STDIN_FILENO) {
            dup2(infile_fd, STDIN_FILENO);
            close(infile_fd);
        }
        if (outfile_fd != STDOUT_FILENO) {
            dup2(outfile_fd, STDOUT_FILENO);
            close(outfile_fd);
        }

        execvp(p->argv[0], p->argv);
        perror("execvp");
        exit(EXIT_FAILURE);
    }

    /* parent process */
    p->pid = pid;
    if (j->pgid == 0)
        j->pgid = pid;
    setpgid(pid, j->pgid);

    /* close redirected files in parent */
    if (p->infile && infile_fd != in_fd)
        close(infile_fd);
    if (p->outfile && outfile_fd != out_fd)
        close(outfile_fd);

    return 0;
}

/* Find an available job slot */
int get_job_id()
{
    for (int i = 1; i <= MAX_JOBS; i++) {
        if (shell.jobs[i] == NULL)
            return i;
    }
    return -1; /* no available slots */
}

/* Launch all processes in a job (pipeline), handle fg/bg */
int launch_job(struct job *j)
{
    struct process *p;
    int pipe_fd[2];
    int in_fd = STDIN_FILENO;
    pid_t rightmost_pid = 0;

    /* get job id for background jobs */
    if (j->mode == BG_EXEC) {
        j->id = get_job_id();
        if (j->id > 0) {
            shell.jobs[j->id] = j;
        }
    }

    /* launch each process in the pipeline */
    for (p = j->first; p; p = p->next) {
        int out_fd;

        /* determine output fd */
        if (p->next) {
            /* not the last process, create pipe */
            if (pipe(pipe_fd) < 0) {
                perror("pipe");
                return -1;
            }
            out_fd = pipe_fd[1];
        } else {
            /* last process uses stdout */
            out_fd = STDOUT_FILENO;
            rightmost_pid = 0; /* will be set after launch_process */
        }

        /* launch the process */
        if (launch_process(j, p, in_fd, out_fd) < 0) {
            if (p->next) {
                close(pipe_fd[0]);
                close(pipe_fd[1]);
            }
            return -1;
        }

        /* save rightmost pid for background jobs */
        if (!p->next) {
            rightmost_pid = p->pid;
        }

        /* close write end of pipe in parent, setup next input */
        if (p->next) {
            close(pipe_fd[1]);
            if (in_fd != STDIN_FILENO)
                close(in_fd);
            in_fd = pipe_fd[0];
        }
    }

    /* close final input fd if it's a pipe */
    if (in_fd != STDIN_FILENO)
        close(in_fd);

    /* handle foreground vs background execution */
    if (j->mode == FG_EXEC) {
        /* foreground: wait for all processes to complete */
        int status;
        for (p = j->first; p; p = p->next) {
            if (p->type == CMD_EXTERNAL) {
                waitpid(p->pid, &status, 0);
            }
        }
    } else {
        /* background: print rightmost pid and job info */
        if (rightmost_pid > 0) {
            pprintf(STDOUT_FILENO, "%d\n", rightmost_pid);
        }
        if (j->id > 0) {
            pprintf(STDOUT_FILENO, "[%d] %d\n", j->id, j->pgid);
        }
    }

    return 0;
}