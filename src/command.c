/*
 * command.c - Command parsing and data structure management
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "../include/builtin.h"
#include "../include/command.h"
#include "../include/shell.h"

/* Free a process and its resources */
void free_process(struct process *p)
{
    if (!p)
        return;
    free(p->raw_cmd);

    /* free individual argv strings */
    if (p->argv) {
        for (int i = 0; i < p->argc; i++) {
            free(p->argv[i]);
        }
        free(p->argv);
    }

    free(p->infile);
    free(p->outfile);
    free(p);
}

/* Free a job and all its processes */
void free_job(struct job *j)
{
    if (!j)
        return;

    struct process *p = j->first;
    while (p) {
        struct process *next = p->next;
        free_process(p);
        p = next;
    }

    free(j->full_cmd);
    free(j);
}

/* Helper: process replay substitution in command line */
char *process_replay(const char *line)
{
    /* Check if command starts with "replay " */
    if (strncmp(line, "replay ", 7) != 0) {
        return strdup(line); /* No replay, return copy */
    }

    /* Find the replay number */
    char *line_copy = strdup(line);
    char *saveptr;
    char *token = strtok_r(line_copy, " ", &saveptr); /* "replay" */
    token = strtok_r(NULL, " ", &saveptr);            /* number */

    if (!token) {
        free(line_copy);
        return strdup(line); /* Invalid format, return original */
    }

    int idx = atoi(token);

    if (idx < 1 || idx > history_count) {
        free(line_copy);
        return strdup(line); /* Invalid index, return original */
    }

    /* Get the rest of the command line after "replay N" */
    char *rest = strtok_r(NULL, "", &saveptr);

    /* Build the new command: history[idx-1] + rest */
    char *new_cmd = malloc(LINE_LEN);
    strcpy(new_cmd, history[idx - 1]);

    if (rest && *rest) {
        /* Append the rest (e.g., "| head -1") */
        strcat(new_cmd, rest);
    }

    free(line_copy);
    return new_cmd;
}

/* Parse a single command segment into a process struct */
struct process *parse_segment(char *seg)
{
    char *token, *saveptr;
    struct process *p = calloc(1, sizeof(*p));
    p->raw_cmd = strdup(seg);

    /* tokenize and collect args */
    int cap = TOK_LEN, pos = 0;
    p->argv = calloc(cap, sizeof(char *));
    for (token = strtok_r(seg, TOK_DELIM, &saveptr); token; token = strtok_r(NULL, TOK_DELIM, &saveptr)) {
        if (pos >= cap) {
            cap *= 2;
            p->argv = realloc(p->argv, cap * sizeof(char *));
        }
        /* handle redirection tokens */
        if (strcmp(token, "<") == 0) {
            token = strtok_r(NULL, TOK_DELIM, &saveptr);
            p->infile = strdup(token);
        } else if (strcmp(token, ">") == 0) {
            token = strtok_r(NULL, TOK_DELIM, &saveptr);
            p->outfile = strdup(token);
        } else {
            p->argv[pos++] = strdup(token);
        }
    }
    p->argc = pos;
    p->argv[pos] = NULL;

    /* determine built-in or external */
    p->type = (p->argc > 0 ? get_cmd_id(p->argv[0]) : CMD_EXTERNAL);
    return p;
}

/* Parse input line into a job (possibly pipeline) */
struct job *parse_line(char *line)
{
    /* Process replay substitution first */
    char *processed_line = process_replay(line);

    /* Add the processed command to history */
    add_history(processed_line);

    /* make a copy for processing */
    char *line_copy = strdup(processed_line);

    /* detect background '&' */
    int mode = FG_EXEC;
    size_t len = strlen(line_copy);
    if (len > 0 && line_copy[len - 1] == '&') {
        mode = BG_EXEC;
        line_copy[--len] = '\0';
        /* trim any trailing spaces before & */
        while (len > 0 && line_copy[len - 1] == ' ') {
            line_copy[--len] = '\0';
        }
    }

    /* split by '|' for pipeline */
    char *seg, *saveptr;
    struct job *j = calloc(1, sizeof(*j));
    j->mode = mode;
    j->full_cmd = strdup(processed_line); /* use processed line for full command */

    int first = 1;
    for (seg = strtok_r(line_copy, "|", &saveptr); seg; seg = strtok_r(NULL, "|", &saveptr)) {
        /* trim leading spaces */
        while (*seg == ' ')
            seg++;
        struct process *p = parse_segment(seg);
        if (first)
            j->first = p;
        else {
            /* attach to pipeline */
            struct process *prev = j->first;
            while (prev->next)
                prev = prev->next;
            prev->next = p;
        }
        first = 0;
    }

    free(line_copy);
    free(processed_line);
    return j;
}