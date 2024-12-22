import os
import sys
import codecs

def transform_line(str):
    return str.strip()
    
def is_line_useful(str):
    return not str.startswith("//")

def remove_comments(file):
    '''
    Searches the file for comments and doesn't print them
    '''
    valid_strings = ""
    
    for f in file:
        if f != None:
            line = transform_line(f)
            if line != None and (is_line_useful(line)):
                valid_strings += f
                
    return valid_strings

def read_txt_file(txt_file):
    '''
    Reads the text file and handles bad reads.
    '''
    if txt_file is None:
        return None
    try:
        with codecs.open(txt_file, 'r', encoding='cp1252',
                         errors='ignore') as f:
            return remove_comments(f)
    except FileNotFoundError as error:
        pass
    return None
    
def write_txt_file(txt_file, valid_strings):
    '''
    Writes the text file and handles bad behaviour.
    '''
    if txt_file is None:
        return None
    try:
        with codecs.open(txt_file, 'w', encoding='utf-8',
                         errors='ignore') as f:
            f.write(valid_strings)
    except FileNotFoundError as error:
        pass
    return None

if len(sys.argv) < 3:
    print("You need to pass both the source file and the target file as a parameters!")
else:
    valid_strings = read_txt_file(sys.argv[1])
    if valid_strings is not None:
        write_txt_file(sys.argv[2], valid_strings)
    