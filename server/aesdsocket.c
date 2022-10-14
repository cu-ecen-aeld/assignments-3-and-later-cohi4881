#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <sys/wait.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <syslog.h>
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netdb.h>


extern int errno;
FILE *fp;
int fd, cfd;

// get sockaddr, IPv4 or IPv6:
void *get_in_addr(struct sockaddr *sa)
{
    if (sa->sa_family == AF_INET) {
        return &(((struct sockaddr_in*)sa)->sin_addr);
    }

    return &(((struct sockaddr_in6*)sa)->sin6_addr);
}

static void sig_handler(int signo)
{
    syslog(LOG_DEBUG, "Caught signal, exiting");
    if(signo == SIGINT)
    {
        printf("Caught INT!\n");
    }
    else if (signo == SIGTERM)
    {
        printf("Caught SIGTERM!\n");
    }
    else
    {
        printf("Unexpected Signal error\n");
        syslog(LOG_ERR, "Unexpected Signal error");
	    return 1;
    }
    if(fp == NULL) fclose(fp);
    remove("/var/tmp/aesdsocketdata");
    close(cfd);
    close(fd);
	exit(EXIT_SUCCESS);
}

int main(int argc, char *argv[] )
{
    openlog(NULL, 0, LOG_USER);
    
    if( argc > 2)
    {
        printf("Needs less than 2 params'\n");
        syslog(LOG_ERR, "Invalid # of args: %d", argc);
        return 1;
    }

    if(signal(SIGINT, sig_handler) == SIG_ERR) 
    {
        printf("Cannot handle SIGINT error\n");
        syslog(LOG_ERR, "Cannot handle SIGINT error");
	    return 1;
	}
	
	if(signal(SIGTERM, sig_handler) == SIG_ERR) 
    {
        printf("Cannot handle SIGTERM error\n");
        syslog(LOG_ERR, "Cannot handle SIGTERM error");
	    return 1;
	}

    int status;
    struct addrinfo hints;
    struct addrinfo *servinfo;
    struct sockaddr_storage their_addr;
    socklen_t addr_size;
    char s[INET6_ADDRSTRLEN];

    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;

    if( (status = getaddrinfo(NULL, "9000", &hints, &servinfo)) != 0)
    {
        printf("getaddrinfo error\n");
        syslog(LOG_ERR, "getaddrinfo error");
        return 1;
    }

    fd = socket(servinfo->ai_family, servinfo->ai_socktype, servinfo->ai_protocol);
    if( fd == -1)
    {
        printf("socket() error\n");
        syslog(LOG_ERR, "socket() error");
        return 1;
    }

    int rc = bind(fd, servinfo->ai_addr, servinfo->ai_addrlen);
    if( rc == -1)
    {
        printf("bind() error\n");
        syslog(LOG_ERR, "bind() error");
        return 1;
    }

    freeaddrinfo(servinfo);
    
    if(argc == 2)
    {
        daemon(0, 0);
    }
    
    rc = listen(fd, 10);
    if( rc == -1)
    {
        printf("listen() error\n");
        syslog(LOG_ERR, "listen() error");
        return 1;
    }
    char *buf;
    int filesize = 0;
    int bufsize;
    int rev_size = 0;
    int buf_loc = 0;
    int bufmax = 1024;
        
    fp = open("/var/tmp/aesdsocketdata",O_APPEND | O_RDWR | O_CREAT, S_IRWXO | S_IRWXG | S_IRWXU);
    while(1)
    {
        bufsize = bufmax;
        buf_loc = 0;
        addr_size = sizeof(their_addr);
        cfd = accept(fd, (struct sockaddr *)&their_addr, &addr_size);
        if( cfd == -1)
        {
            printf("accept() error\n");
            syslog(LOG_ERR, "accept() error");
            return 1;
        }
        inet_ntop(their_addr.ss_family, get_in_addr((struct sockaddr *)&their_addr), s, sizeof s);
        syslog(LOG_DEBUG, "Accepted connection from %s", s);
        
        buf = (char *)malloc(bufsize);
        int end_found = 0;
        while(!end_found)
        {
            ssize_t r_len = recv(cfd, buf, bufsize, 0);
            buf_loc += r_len;
            if ( buf[r_len-1] == '\n')
            {
                end_found = 1;
            }
            rc = write(fp, buf, r_len);
            fsync(fp);
        }
        if( rc == -1)
        {
            printf("file write() error\n");
            syslog(LOG_ERR, "file write() error");
            return 1;
        }
        lseek(fp, 0, SEEK_SET);
        filesize += buf_loc;
        buf = realloc(buf, filesize);
        read(fp, buf, filesize);
        
        ssize_t s_len = send(cfd, buf, filesize, 0);

        free(buf);
        close(cfd);
    }


}

