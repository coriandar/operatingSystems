#include "kernel/types.h"
#include "user/user.h"

int main(void) {
	// Index 0 = read, index 1 = write
	int p1[2]; // For parent-to-child pipe
	int p2[2]; // For child-to-parent pipe
	
	pipe(p1);
	pipe(p2);

	char parent[] = "Message from parent";
	char child[] = "Message from child";

	int pid = fork(); // Create child process

	if (pid > 0) // Parent process
	{
		close(p1[0]);
		//close(p2[1]);

		write(p1[1], parent, sizeof(parent)); // Write message to child
		close(p1[1]);

		wait(0); // Wait for child to send a message
		close(p2[1]);

		char buffer[50];
		read(p2[0], buffer, sizeof(buffer)); // Read message from child
		printf("%d %s\n", getpid(), buffer);

		//close(p1[1]);
		close(p2[0]);
	}
	else if (pid == 0) // Child process
	{
		//close(p1[0]);
		//close(p2[0]);
		close(p1[1]);

		char buffer[50];
		read(p1[0], buffer, sizeof(buffer)); // Read message from parent
		printf("%d %s\n", getpid(), buffer); // Print message from parent

		write(p2[1], child, sizeof(child)); // Write message to parent

		//close(p1[0]);
		close(p2[1]);
	}
	else
	{
		printf("Fork error. \n");
		exit(1); // Exit with error
	}

	exit(0); // Normal exit
}
