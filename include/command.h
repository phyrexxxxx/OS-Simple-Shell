#ifndef COMMAND_H
#define COMMAND_H

#include <sys/types.h>

/* Built-in command identifiers */
enum {
    CMD_EXTERNAL = 0,
    CMD_EXIT,
    CMD_CD,
    CMD_HELP,
    CMD_ECHO,
    CMD_RECORD,
    CMD_REPLAY,
    CMD_MYPID
};

/* Process linked list node */
struct process {
    char *raw_cmd;         // original segment
    char **argv;           // arguments with NULL terminator
    int argc;              // argument count
    char *infile;          // input redirect path
    char *outfile;         // output redirect path
    pid_t pid;             // process ID
    int type;              // CMD_EXTERNAL or built-in id
    int state;             // PROC_*
    struct process *next;  // next in pipeline
};

/* Job structure to group pipeline processes */
struct job {
    int id;                 // job slot
    pid_t pgid;             // process group ID
    int mode;               // FG_EXEC or BG_EXEC
    char *full_cmd;         // entire command string
    struct process *first;  // head of process list
};

/* Command parsing functions */
struct process *parse_segment(char *seg);
struct job *parse_line(char *line);
char *process_replay(const char *line);

/* Memory management */
void free_process(struct process *p);
void free_job(struct job *j);

#endif /* COMMAND_H */