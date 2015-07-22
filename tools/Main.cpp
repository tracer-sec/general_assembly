#include <Windows.h>
#include <fstream>

using namespace std;

void GetShellcode(LPSTR commandLine, char **buffer)
{
    string targetFile(commandLine);
    if (targetFile.length() == 0)
    {
        *buffer = nullptr;
    }
    else
    {
        ifstream f(commandLine, ifstream::in | ifstream::binary);
        f.seekg(0, ios::end);
        size_t length = static_cast<size_t>(f.tellg());
        f.seekg(0, ios::beg);
        *buffer = new char[length + 1];
        f.read(*buffer, length + 1);
        f.close();
    }
}

int WINAPI WinMain(HINSTANCE instance, HINSTANCE prevInstance, LPSTR commandLine, int show)
{
    char *buffer;
    GetShellcode(commandLine, &buffer);

    int result = 0;
    if (buffer)
    {
        void(*func)();
        func = reinterpret_cast<void(*)()>(buffer);
        (*func)();

        ::MessageBox(NULL, "Quitting", "Laterz", MB_OK);
    }
    else
    {
        result = 1;
    }
    return result;
}
