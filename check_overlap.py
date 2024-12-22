import os
import sys
import codecs

def org_func(str, occupied_array, defines_dict, curr_addr, base_string):
    tokens = str.split()
    return manip_entry(transform_line(tokens[1]), defines_dict)
    
def define_func(str, occupied_array, defines_dict, curr_addr, base_string):
    tokens = str.split()
    defines_dict[transform_line(tokens[1])] = manip_entry(transform_line(tokens[2]), defines_dict)
    return None
    
def db_func(str, occupied_array, defines_dict, curr_addr, base_string):
    return alter_subset_of_bytes(str, occupied_array, defines_dict, curr_addr, 1, base_string)
    
def dw_func(str, occupied_array, defines_dict, curr_addr, base_string):
    return alter_subset_of_bytes(str, occupied_array, defines_dict, curr_addr, 2, base_string)
    
def dd_func(str, occupied_array, defines_dict, curr_addr, base_string):
    return alter_subset_of_bytes(str, occupied_array, defines_dict, curr_addr, 4, base_string)
    
def fill_func(str, occupied_array, defines_dict, curr_addr, base_string):
    tokens = str.split()
    size = manip_entry(transform_line(tokens[1]), defines_dict)
    check_for_size(occupied_array, base_string, set(), curr_addr, size)
    return curr_addr + size
    
def incbin_func(str, occupied_array, defines_dict, curr_addr, base_string):
    bin_path = transform_line(str.split()[1].split("//", 1)[0])
    size = os.path.getsize(bin_path)
    check_for_size(occupied_array, base_string, set(), curr_addr, size)
    return curr_addr + size

operations_dict = {"define": define_func, "incbin": incbin_func, "dd": dd_func, \
                   "db": db_func, "dw": dw_func, "org": org_func, "fill": fill_func}

def occupied_check(addr, old_str, str, other_str):
    '''
    Prints info on overlaps.
    '''
    if not old_str in other_str:
        print("WARNING! FOUND OVERLAP IN " + hex(addr).upper() + "!" \
              " - CONFLICTING STRINGS:\n" + old_str + "\n" + str)
        other_str.add(old_str)
    return other_str

def handle_addr(addr):
    '''
    Properly handles addresses.
    '''
    base = 0x8000000
    if addr >= base:
        return addr - base
    return addr

def alter_subset_of_bytes(str, occupied_array, defines_dict, curr_addr, single_size, base_string):
    '''
    Function that is used to make a small subset of bytes occupied.
    This can happen repeatedly if there are various entries separated by a ",".
    '''
    tokens = transform_line(str.split("//", 1)[0]).split(",")
    other_str = set()
    for token in tokens:
        other_str = check_for_size(occupied_array, base_string, other_str, curr_addr, single_size)
        curr_addr += single_size
    return curr_addr

def check_for_size(occupied_array, base_string, other_str, curr_addr, size):
    '''
    Checks whether or not something overlaps.
    '''
    for i in range(size):
        addr = handle_addr(curr_addr + i)
        if occupied_array[addr] is not None:
            other_str = occupied_check(curr_addr + i, occupied_array[addr], \
                                       base_string, other_str)
        else:
            occupied_array[addr] = base_string
    return other_str
    
def manip_entry(str, defines_dict):
    '''
    Handles an address. It's missing handling arithmetics,
    however they're not really needed
    '''
    if str.startswith("$"):
        actual_entry = int(transform_line(transform_line(str[1:]).replace("//", " ").split()[0]), 16)
    if str.startswith("{"):
        actual_entry = defines_dict[transform_line(transform_line(str[1:]).replace("}", " ").split()[0])]
    return actual_entry

def transform_line(str):
    return str.strip()
    
def is_line_useful(str):
    return not str.startswith("//")

def handle_useful_line(str, occupied_array, defines_dict, curr_addr):
    '''
    Handles a non empty line with some useful instructions.
    Calls the right operation from operations_dict, if it is in there.
    '''
    lines = str.split(";")
    for line in lines:
        line = transform_line(line)
        if line != None and line != "" and (is_line_useful(line)):
            value = transform_line(line.split()[0])
            if value in operations_dict.keys() and operations_dict[value] is not None:
                returned_val = operations_dict[value](line, occupied_array, defines_dict, curr_addr, str)
                if returned_val is not None:
                    curr_addr = returned_val
    
    return curr_addr

def search_overlaps(file, occupied_array, defines_dict):
    '''
    Searches the file for overlaps
    '''
    curr_addr = None
    
    for f in file:
        if f != None and f != "":
            line = transform_line(f)
            if line != None and line != "" and (is_line_useful(line)):
                curr_addr = handle_useful_line(line, occupied_array, defines_dict, curr_addr)
                
    return 0

def read_xkas_asm_file(asm_file, occupied_array, defines_dict):
    '''
    Reads the xkas asm file and handles bad reads.
    '''
    if asm_file is None:
        return None
    try:
        with codecs.open(asm_file, 'r', encoding='utf-8',
                         errors='ignore') as f:
            return search_overlaps(f, occupied_array, defines_dict)
    except FileNotFoundError as error:
        pass
    return None

occupied_array = [None]*0x2000000
defines_dict = dict()
for i in range(1, len(sys.argv)):
    read_xkas_asm_file(sys.argv[i], occupied_array, defines_dict)
    print("Overlap check for " + sys.argv[i] + " done!")
if(len(sys.argv) <= 1):
    print("Too few parameters!")