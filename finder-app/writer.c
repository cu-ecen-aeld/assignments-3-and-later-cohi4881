#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <syslog.h>

extern int errno;

int main(int argc, char *argv[] )
{

    openlog(NULL, 0, LOG_USER);
    
    if( argc != 3)
    {
        printf("Needs two params, for example './writer /tmp/aesd/assignment1 linux'");
        syslog(LOG_ERR, "Invalid # of args: %d", argc);
        return(1);
    }

    FILE *fp;
    char buffer[255];
    
    fp = fopen(argv[1], "w+");
    
    if(fp == NULL)
    {
        printf("Could not open file");
        syslog(LOG_ERR, "ERROR - Could not open file: %s", strerror(errno));
        return(1);
    }
    else
    {
        //SYSLOG HERE
        syslog(LOG_DEBUG, "Writing %s to %s", argv[2], argv[1]);
        fprintf(fp, "%s", argv[2]);
        fclose(fp);
    }
   
    return 0;
    
}

//Setup syslog logging for your utility using the LOG_USER facility.

//Use the syslog capability to write a message “Writing <string> to <file>” where <string> is the text string written to file (second argument) and <file> is the file created by the script.  This should be written with LOG_DEBUG level.

//Use the syslog capability to log any unexpected errors with LOG_ERR level.
