#include<iostream>
#include<fstream>
using namespace std;

// Loads the main_font's characters and rearranges them.
// It goes from:
// First row top left tile           First row top right tile
// Second row top left tile          Second row top right tile
// to:
// First row top left tile           Second row top left tile
// Third row top left tile           Fourth row top left tile
void rearrange_main_font(unsigned char main_font[], int letters)
{
    unsigned char tile_buffer[2][8];
    for(int i = 0; i < letters; i++)
    {
        for(int j = 0; j < 2; j++)
        {
            for(int k = 0; k < 8; k++)
                tile_buffer[0][k] = main_font[(i * 0x20) + (j * 0x10) + (k * 2)];
            for(int k = 0; k < 8; k++)
                tile_buffer[1][k] = main_font[(i * 0x20) + (j * 0x10) + (k * 2) + 1];
                
            for(int k = 0; k < 8; k++)
                main_font[(i * 0x20) + (j * 0x10) + k] = tile_buffer[0][k];
            for(int k = 0; k < 8; k++)
                main_font[(i * 0x20) + (j * 0x10) + 8 + k] = tile_buffer[1][k];
        }
    }
}

// Loads the font's characters and checks whether it uses the tiles it has or not.
void does_font_use_characters(unsigned char font[], unsigned char is_used[], int letters, int size_X, int size_Y, int size_tile)
{
    for(int i = 0; i < letters; i++)
    {
        int is_used_letter = 0;
        for(int j = 0; j < size_Y; j++)
        {
            int is_used_tile = 0;
            for(int k = 0; k < size_X; k++)
                for(int l = 0; l < 8; l++)
                    is_used_tile |= (font[(i * size_X * size_Y * size_tile) + (j * size_X * size_tile) + (k * size_tile) + l] != 0);
            is_used_letter |= (is_used_tile << j);
        }
        is_used[i] = is_used_letter;
    }
}

int main(int argc, char *argv[])
{
    if(argc < 8)
    {
        cout << "Not enough arguments!" << endl;
        cout << "First, provide mainfont, smallfont and castroll's font files!" << endl;
        cout << "Then, provide the new locations for the rearranged mainfont and castroll!" << endl;
        cout << "Lastly, provide the location for the pre-compiled tiles info ";
        cout << "for both mainfont and smallfont!" << endl;
        return -1;
    }
    
    // Load main_font
    ifstream file_main (argv[1], ios::in|ios::binary|ios::ate);

    if (!file_main.is_open())
    {
        cout << "Unable to open main_font's file!" << endl;
        return -1;
    }
        
    // Load small_font
    ifstream file_small (argv[2], ios::in|ios::binary|ios::ate);

    if (!file_small.is_open())
    {
        cout << "Unable to open small_font's file!" << endl;
        return -1;
    }
    
    // Load castroll_font
    ifstream file_cast (argv[3], ios::in|ios::binary|ios::ate);

    if (!file_cast.is_open())
    {
        cout << "Unable to open castroll_font's file!" << endl;
        return -1;
    }

    // Save to array
    int size_main = file_main.tellg();
    int size_small = file_small.tellg();
    int size_cast = file_cast.tellg();
    char* memblock_main = new char[size_main];
    file_main.seekg (0, ios::beg);
    file_main.read (memblock_main, size_main);
    file_main.close();
    char* memblock_small = new char[size_small];
    file_small.seekg (0, ios::beg);
    file_small.read (memblock_small, size_small);
    file_small.close();
    char* memblock_cast = new char[size_cast];
    file_cast.seekg (0, ios::beg);
    file_cast.read (memblock_cast, size_cast);
    file_cast.close();
    
    int letters_main = size_main/0x20;
    int letters_small = size_small/0xA;
    int letters_cast = size_cast/0x20;
    
    char* memblock_main_is_used = new char[letters_main];
    char* memblock_small_is_used = new char[letters_small];
    
    // Actual operations on fonts
    rearrange_main_font((unsigned char*)memblock_main, letters_main);
    rearrange_main_font((unsigned char*)memblock_cast, letters_cast);
    
    does_font_use_characters((unsigned char*)memblock_main, (unsigned char*)memblock_main_is_used, letters_main, 2, 2, 8);
    does_font_use_characters((unsigned char*)(memblock_small + 2), (unsigned char*)memblock_small_is_used, letters_small, 1, 1, 0xA);
    
    // Write to file
    ofstream fileO (argv[4], ios::out|ios::binary);
    if (!fileO.is_open())
    {
        cout << "Unable to open main_font's output file!" << endl;
        return -1;
    }
    fileO.write(memblock_main, size_main);
    
    ofstream fileO4 (argv[5], ios::out|ios::binary);
    if (!fileO4.is_open())
    {
        cout << "Unable to open castroll_font's output file!" << endl;
        return -1;
    }
    fileO4.write(memblock_cast, size_cast);
    
    ofstream fileO2 (argv[6], ios::out|ios::binary);
    if (!fileO2.is_open())
    {
        cout << "Unable to open main_font's usefulness output file!" << endl;
        return -1;
    }
    fileO2.write(memblock_main_is_used, letters_main);
    
    ofstream fileO3 (argv[7], ios::out|ios::binary);
    if (!fileO3.is_open())
    {
        cout << "Unable to open small_font's usefulness output file!" << endl;
        return -1;
    }
    fileO3.write(memblock_small_is_used, letters_small);
    
    delete(memblock_main);
    delete(memblock_small);
    delete(memblock_cast);
    delete(memblock_main_is_used);
    delete(memblock_small_is_used);
    return 0;
}