#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

int main (int argc, char* argv[])
{
  if (argc > 1) {
    for (int argIter = 1; argIter < argc; ++argIter) {
      char *result = realpath(argv[argIter], NULL); // malloc result
      if (result == NULL) {
        return errno;
      }
      else{
        puts(result);
        free(result);
      }
    }
  }

  return 0;
}