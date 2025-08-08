/*
 * my_shell.c - A simple Unix-like shell implementation
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "include/command.h"
#include "include/shell.h"

/* History buffer - made visible to other modules */
char history[MAX_HISTORY][LINE_LEN];
int history_count = 0;

int main(int argc, char **argv)
{
    (void) argc;
    (void) argv;
    shell_init();

    while (1) {
        print_prompt();
        char *line = NULL;
        size_t cap = 0;
        if (getline(&line, &cap, stdin) < 0)
            break;
        /* skip empty lines */
        if (line[0] == '\n')
            continue;

        /* remove trailing newline */
        size_t len = strlen(line);
        if (len > 0 && line[len - 1] == '\n') {
            line[len - 1] = '\0';
        }

        /* parse and launch job */
        struct job *j = parse_line(line);
        launch_job(j);

        /* free job if it was foreground execution */
        if (j->mode == FG_EXEC) {
            free_job(j);
        }

        free(line);
    }
    return 0;
}