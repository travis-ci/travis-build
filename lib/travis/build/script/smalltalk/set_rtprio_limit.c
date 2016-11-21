// Set rtprio to 2:2 for a given pid (required to run OpenSmalltalk VMs).

#define _GNU_SOURCE
#define _FILE_OFFSET_BITS 64
#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/resource.h>

#define errExit(msg) do { perror(msg); exit(EXIT_FAILURE); \
 } while (0)

int main(int argc, char *argv[]) {
  struct rlimit old, new;
  struct rlimit *newp;
  pid_t pid;

  if (!(argc == 2)) {
    fprintf(stderr, "Usage: %s <pid>\n", argv[0]);
    exit(EXIT_FAILURE);
  }

  pid = atoi(argv[1]); /* PID of target process */

  new.rlim_cur = 2;
  new.rlim_max = 2;
  newp = &new;

  /* Set RTPRIO limit of target process; retrieve and display
  previous limit */

  if (prlimit(pid, RLIMIT_RTPRIO, newp, &old) == -1)
    errExit("prlimit-rtprio-1");
  printf("Previous limits: soft=%lld; hard=%lld\n",
    (long long) old.rlim_cur, (long long) old.rlim_max);

  /* Retrieve and display new RTPRIO limit */

  if (prlimit(pid, RLIMIT_RTPRIO, NULL, &old) == -1)
    errExit("prlimit-rtprio-2");
  printf("New limits: soft=%lld; hard=%lld\n",
    (long long) old.rlim_cur, (long long) old.rlim_max);

  exit(EXIT_SUCCESS);
}