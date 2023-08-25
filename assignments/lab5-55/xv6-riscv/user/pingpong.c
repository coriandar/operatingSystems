#include "kernel/types.h"
#include "user/user.h"

int main(void) {
	// Index 0 = read, index 1 = write
	int p[2];
	pipe(p);

	char parent[] = "Message from parent";
	char child[] = "Message from child";

	int pid = fork(); // Create child process

	if (pid > 0) // Parent process
	{
		write(p[1], parent, sizeof(parent)); // Write message to child
		close(p[1]);

		wait(0); // Wait for child to send a message

		char buffer[50];
		read(p[0], buffer, sizeof(buffer)); // Read message from child
		printf("%d %s\n", getpid(), buffer);

		close(p[0]);
	}
	else if (pid == 0) // Child process
	{
		char buffer[50];
		read(p[0], buffer, sizeof(buffer)); // Read message from parent
		printf("%d %s\n", getpid(), buffer); // Print message from parent

		write(p[1], child, sizeof(child)); // Write message to parent

		close(p[1]);
	}
	else
	{
		printf("Fork error. \n");
		exit(1); // Exit with error
	}

	exit(0); // Normal exit
}
