#! /usr/bin/env python3

import sys
import rwt_processor.processor as process

# here is the code repository...
roots = []  # names of 'roots,' which amount to file names

# entries, which take the form of 'name' = ['line1','line2',...]
entries = {} 

def is_root(name):
    return name.startswith('file:')

def add_entry(name,lines):
    # if the entry is already there, we are adding to it...
    if name in entries:
        entries[name].extend(lines)
    else:
        entries[name] = lines
    if is_root(name):
        roots.append(name)


def is_section_head(line):
    # identify lines that look like:
    #  @<Stop the world, I want to get off@>=
    tmp = line.strip()
    return ( tmp.startswith('@<') and
             tmp.endswith('@>=') )

def normalize_name(name):
    # FIXME  eventually normalize capitalization, etc?
    tmp = name.strip()
    if tmp.endswith('...'):
        found = None
        tmp = tmp[:-3]
        for k in entries:
            if k.startswith(tmp):
                if not found:
                    found = k
                else:
                    raise ValueError(name + " matches both <" + found + "> and <" + k + ">")
        if found:
            tmp = found
        else:
            raise ValueError(name + " does not match any sections defined so far!")
    return tmp
    
def extract_section_name(line):
    assert is_section_head(line)
    return normalize_name(line.strip()[2:-3])

def is_start_of_docs(line):
    return ( line.startswith('@ ') or
             line.startswith('@* ') or
             line.startswith('@+') or
             line.rstrip() == '@'
           )

def is_section_pointer(line):
    # identify lines that look like:
    #  @<Stop the world, I want to get off@>=
    # FIXME... check for crazy cases like
    #     @<one thing@> and @<another thing@>
    # all on the same line...
    tmp = line.strip()
    return ( tmp.startswith('@<') and
             tmp.endswith('@>') )

def extract_section_indentation(line):
    assert is_section_pointer(line)
    # FIXME there's got to be a better way to do this in python!
    tmp = line.lstrip()
    return len(line) - len(tmp)

def extract_section_pointer(line):
    assert is_section_pointer(line)
    return normalize_name(line.strip()[2:-2])

def extract_section(line,infile):
    name = extract_section_name(line)
    text = []
    while True:
        line = infile.readline()
        if len(line) == 0:
            break
        if (is_start_of_docs(line) or
            is_section_head(line)):
            break
        if len(line.strip()) > 0:
            text.append(line.rstrip()+'\n')
            if is_section_pointer(line):
                entries.setdefault(extract_section_pointer(line),[])
    add_entry(name,text)
    return line
    

# to write an entry... recursively expand the sections,
# preserving whitespace...
def write_entry(fp,name,indent=0):
    for line in entries[name]:
        if is_section_pointer(line):
            spacing = extract_section_indentation(line)
            pointer_name = extract_section_pointer(line)
            write_entry(fp,pointer_name,indent+spacing)
        else:
            fp.write(' '*indent)
            fp.write(line)


def sanity_check():
    for it in entries.items():
        if(len(it[1]) == 0):
            print("Warning: tag <",it[0],"> is empty!")


########################
## Main script starts here
########################
print('pytangle v0.1 (c) 2010 Richard Todd <richard@movethemarkets.com>')
print()

def outExt(p,a):
  pass

# open the file and suck in all the data
fn = sys.argv[1]
print('Reading in',fn)
with process.FileProcessor(open(fn,'r')) as infile:
   infile.register("out-extension",outExt,False)
   line = infile.readline()
   while True:
     if len(line) == 0:
        break  # end of file
     elif is_section_head(line):
        line = extract_section(line,infile)
     else:
        line = infile.readline() 

# perform a sanity check
sanity_check()

# ok, now tangle it all together!
for r in roots:
    fname = r[5:].strip() # take off the file: part
    print('Writing',fname)
    with open(fname,'w') as outfile:
        write_entry(outfile,r)

print('Done!')

