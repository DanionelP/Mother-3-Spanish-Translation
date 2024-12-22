#include<iostream>
#include<fstream>
using namespace std;

int main(int argc, char *argv[])
{
    if(argc < 2)
    {
        cout << "No argument(s)!";
        return -1;
    }
    for(int i=1; i < argc; i++)
    {
        ifstream file (argv[i], ios::in|ios::binary|ios::ate);

        if (!file.is_open())
            break;
        int size=file.tellg();
        char* memblock = new char[size];
        file.seekg (0, ios::beg);
        file.read (memblock, size);
        file.close();
		int j = 0;
		while(j < size)
		{
			int k = 0;
			bool found = false;
			while(!found && k < 0x28 && k + j + 1 < size)
			{
				int u = memblock[k + j] + (memblock[k + j + 1] << 8);
				if(u == 0xFFFF)
					found = true;
				k += 2;
			}
			
			if(!found)
			{
				k = 0;
				while(k < 0x28 && k + j + 1 < size)
				{
					int u = memblock[k + j] + (memblock[k + j + 1] << 8);
					if(u == 0)
					{
						memblock[k + j] = 0xFF;
						memblock[k + j + 1] = 0xFF;
						found = true;
					}
					k += 2;
				}
				if(!found && k < 0x28) //End of file, we still need a final 0xFFFF
				{
					char* memblock2 = new char[size + 2];
					for(int o = 0; o < size; o++)
						memblock2[o] = memblock[o];
					memblock = memblock2;
					memblock[size] = 0xFF;
					memblock[size + 1] = 0xFF;
					size += 2;
					j += 2; //Make sure we go out of the file
				}
			}
			
			j += 0x28;
		}
        ofstream fileO (argv[i], ios::out|ios::binary);
        if (!fileO.is_open())
            break;
		fileO.write(memblock, size);
		delete(memblock);
    }
    return 0;
}