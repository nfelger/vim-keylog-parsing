#include <Python.h>
#include <stdio.h>
#include <ctype.h>

%%{
    machine vimkeylog;
    write data;
}%%

int DEBUG = 1;

static char * escape_control_chars(const char *orig) {
    char *result;
    char *result_cursor;
    int count = 0;

    for(int i = 0; orig[i] != 0; i++) {
        if(iscntrl(orig[i])) { count++; }
    }

    int result_size = strlen(orig) + 3 * count;
    result = result_cursor = malloc(result_size + 1);
    if (!result)
        return NULL;

    char ch;
    for(int i = 0; orig[i] != 0; i++) {
        ch = orig[i];
        if(ch < 28 || ch > 127) {
            sprintf(result_cursor, "\\x%0.2x", orig[i]);
            result_cursor += 4;
        } else {
            strncpy(result_cursor, orig + i, 1);
            result_cursor++;
        }
    }
    result[result_size] = 0;
    return result;
}

static PyObject * vimkeylog_parse(PyObject *self, PyObject *args)
{
    const char *input;
    if (!PyArg_ParseTuple(args, "s", &input))
        return NULL;

    if(DEBUG) { printf("Input:\n%s\n", escape_control_chars(input)); }

    PyObject *parsed_commands = PyList_New(0);
    if (!parsed_commands)
        return NULL;

    // Init ragel inputs.
    const char *p = input,                  // Start pointer
              *pe = input + strlen(input);  // End pointers.
    int cs;                                 // Current FSM state.

    // Own state variables.
    // ...

    %%{
        action cmd {
            PyObject *character = Py_BuildValue("s#", p, 1);
            if (!character) {
                Py_XDECREF(parsed_commands);
                return NULL;
            }
            if (PyList_Append(parsed_commands, character) < 0) {
                 Py_XDECREF(parsed_commands);
                 return NULL;
            }
            Py_XDECREF(character);
        }

        action l {
            char *curr;
            if(iscntrl(fc)) {
                curr = malloc(5 * sizeof(char));
                sprintf(curr, "\\x%0.2x", fc);
                curr[4] = 0;
            } else {
                curr = malloc(2 * sizeof(char));
                curr[0] = fc;
                curr[1] = 0;
            }
            printf("%i\t->\t%s\t->\t%i.\n", fcurs, curr, ftargs);
            free(curr);
        }

        cr = '\r';
        backspace = -128 'kb';
        ctrl_r = 18;
        ctrl_v = 22;
        escape = 27;

        abort = escape; # Add <c-c>

        normal_command = [jk] @l @cmd;

        enter_input = [iv] @l;
        input = any - escape @l;
        leave_input = abort @l;
        input_mode = enter_input input* leave_input @l;

        # Doesn't capture using backspace to leave colon mode after having
        # typed some characters, since that would require keeping track of how
        # many characters have been typed and matching that with the number of
        # backspaces, which is the equivalent of matching balanced parantheses,
        # which a regular grammar cannot match.
        exit_colon_mode = (abort | cr);
        colon_command = ':' @l (
            backspace @l |
            ((input | backspace)* @l exit_colon_mode @cmd @l)
        );

        normal_commands := (
                         normal_command |
                         input_mode |
                         colon_command
                   )*;

                 write init;
                 write exec;
    }%%


    if(p != pe) {
        printf("Didn't reach end of message. Unprocessed:\n");
        char **curr = NULL;
        int err;
        for(int i=0; p[i] != 0; i++) {
            char ch = p[i];
            if(ch < 28 || ch > 127) {
                err = asprintf(curr, "\\%i", ch);
            } else {
                err = asprintf(curr, "%c", ch);
            }
            if(err == -1) { return NULL; }
            printf("%s\n", *curr);
            free(*curr);
        }
    }

    return parsed_commands;
}

static PyMethodDef VimParseMethods[] = {
    {"parse",  vimkeylog_parse, METH_VARARGS, "Parse Vim command logs."},
    {NULL, NULL, 0, NULL}  /* Sentinel */
};

    PyMODINIT_FUNC
initvimkeylog(void)
{
    (void) Py_InitModule("vimkeylog", VimParseMethods);
}
