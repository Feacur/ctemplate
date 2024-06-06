#include <stdio.h>

#include "_project.h" // IWYU pragma: keep

int main(int argc, char * argv[])
{
	printf("main args:\n");
	for (int i = 0; i < argc; i++)
	{
		printf("- %s\n", argv[i]);
	}
	fgetc(stdin);
	return 0;
}
