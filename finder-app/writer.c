#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <syslog.h>
#include <string.h>


int main(int argc, char *argv[]) {


    #define NUM_ARGS 2
    int fd;
    ssize_t bwr;
    char* wfn;
    char* wstr;
    

    openlog(NULL, 0, LOG_USER);

    if(argc == 3) {

        wfn = argv[1];
        wstr = argv[2];

    } else {
        syslog(LOG_ERR, "ERROR: Incorrect number of args (given: %d / required %d)", NUM_ARGS, argc - 1);
        return 1;
    }
    
    fd = creat(wfn, 0644);

    if(fd == -1) {
        syslog(LOG_ERR, "ERROR: %m: %s", wfn);
        return 1;
    }

    long int wsize = strlen(wstr);
    bwr = write(fd, wstr, (size_t) wsize);

    if(bwr == -1) {

        syslog(LOG_ERR, "ERROR: %m");
        return 1;
    } else if (bwr != wsize) {
        syslog(LOG_ERR,"ERROR: Byte Requested: %ld / Bytes Written: %ld",wsize,bwr);
        return 1;
    }

    syslog(LOG_DEBUG,"Writing %s to %s", wstr, wfn);


    close(fd);

    return 0;

}