#include <stdio.h>
#include <stdlib.h>

typedef struct {
	int hours;
	int mins;
	double secs;
} timeinfo_t;

timeinfo_t convertTime(double seconds)
{
	timeinfo_t t;
	t.hours = (int)seconds / 3600;
	seconds = seconds - t.hours * 3600;

	t.mins = (int)seconds / 60;
	seconds = seconds - t.mins * 60;

	t.secs = seconds;
	return t;
}

int main(int argc, char *argv[])
{
	if (argc == 2) {
		double input = atof(argv[1]);
		timeinfo_t t = convertTime(input);
		printf("%02d:%02d:%.2f\n", t.hours, t.mins, t.secs);
		return 0;
	}
	else {
		printf("Please enter seconds to convert.\n");
		return -1;
	}
}
