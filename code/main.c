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

//
#if BUILD_SUBSYTEM == BUILD_SUBSYTEM_WINDOWS
#define WIN32_LEAN_AND_MEAN
#include <Windows.h>

#include <stdlib.h>
int main(int argc, char * argv[]);
int WinMain(HINSTANCE hInst, HINSTANCE hInstPrev, PSTR cmdline, int cmdshow)
{
	return main(__argc, __argv);
}
#endif
