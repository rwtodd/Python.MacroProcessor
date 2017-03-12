#!/usr/bin/env python
import sys
import rwt_processor.processor as fp
class name_entry:
  def __init__(self):
     self.defined = []
     self.used_in = []
name_registry = {}  # "name" -> name_entry
class input_pair:
  def __init__(self):
     self.number = None
     self.text = []
     self.text_name = None
     self.code = []
     self.code_name = None
input_db = []     # list of input_pairs
outExtension = "txt"
def set_ext(processor,txt):
  global outExtension
  outExtension = txt
def is_text_head(line):
  return ( line.startswith('@ ') or
           line.startswith('@* ') or
           line.startswith('@+') or
           line.rstrip() == '@'
         )
def is_code_head(line):
    tmp = line.strip()
    return ( tmp.startswith('@<') and
             tmp.endswith('@>=') )
def gen_new_section():
  num = 1
  while True:
    yield num
    num = num + 1
section_number = gen_new_section()
def process_text(infile,line):
   new_section = input_pair()
   if line.startswith('@*'):
      line = line[3:].lstrip()
      new_section.text_name = line[:line.index('.')+1]
      line = line[line.index('.')+1:]
      new_section.number = next(section_number)
   elif line.startswith('@+'):
      line = line[3:].lstrip()
   else:
      line = line[1:]
      new_section.number = next(section_number)
   if len(line.strip())>0:
     new_section.text.append(line)
   num_empty = 0
   while True:
        line = infile.readline()
        if ( len(line) == 0 or
             is_text_head(line) or
             is_code_head(line)  ):
           break
        elif len(line.strip())>0:
           if num_empty > 0:
              if len(new_section.text) > 0:
                 new_section.text.append('\n'*num_empty)
           num_empty = 0
           new_section.text.append(line)
        else:
           num_empty = num_empty + 1
   input_db.append(new_section)
   return line
def normalize_name(name):
    tmp = name.strip()
    if tmp.endswith('...'):
        found = None
        tmp = tmp[:-3]
        for k in name_registry:
            if k.startswith(tmp):
                if not found:
                    found = k
                else:
                    raise ValueError(name +
                                     " matches both <" +
                                     found + "> and <" +
                                     k + ">")
        if found:
            tmp = found
        else:
            raise ValueError(name + " does not match any " +
                             "code sections defined so far!")
    return tmp
def process_code(infile,line):
    pair = None
    if len(input_db) > 0:
      pair = input_db[-1]
    else:
      pair = input_pair()
    if( (pair.number == None) or
        (pair.code_name != None) ):
      pair = input_pair()
      pair.number = next(section_number)
      input_db.append(pair)
    code_name = normalize_name(line.strip()[2:-3])
    entry = name_registry.setdefault(code_name,name_entry())
    entry.defined.append(pair.number)
    answer = []
    num_empty = 0
    while True:
        rawline = infile.readline()
        line = rawline.rstrip()
        if (len(rawline) == 0 or
            is_text_head(rawline) or
            is_code_head(rawline) ):
            break
        elif  len(line)==0:
            num_empty = num_empty+1
        else:
            if num_empty > 0:
               answer.append('\n'*num_empty)
               num_empty = 0
            answer.append(line+'\n')
            if is_code_pointer(line):
                pointed_name = extract_code_pointer(line)
                pointed = name_registry.setdefault(pointed_name,name_entry())
                pointed.used_in.append(pair.number)
    pair.code = answer
    pair.code_name = code_name
    return rawline
def is_code_pointer(line):
    tmp = line.strip()
    return ( tmp.startswith('@<') and
             tmp.endswith('@>') )
def extract_code_pointer(line):
    return normalize_name(line.strip()[2:-2])
def process_code_escapes(formatter,s):
  ind1 = s.find('|')
  if(ind1 >= 0):
     ind2 = s.find('|', ind1+1)
     if(ind2 > 0):
        if (ind2-ind1) > 1:
          formatter.text(s[:ind1])
          formatter.inlineCode(s[ind1+1:ind2])
        else:
          formatter.text(s[:ind2+1])
        process_code_escapes(formatter,s[ind2+1:])
     else:
        formatter.text(s)
  else:
    formatter.text(s)
class HTMLWeaver:
  def __init__(self,of):
     self.__outfile = of
  def __make_section_anchor(self,sec):
    return '<a name="sect{0}">{0}</a>'.format(sec)
  def __make_section_link(self,sec):
    return '<a href="#sect{0}">{0}</a>'.format(sec)
  def __sanitize_for_HTML(self,s):
    return s.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')
  def nextEntry(self):
    print('<p>',end='',file=self.__outfile)
  def entryNumber(self,num,name):
    print('<strong>{0}. {1}</strong>'.format(
                                          self.__make_section_anchor(num),
                                          name or ''),
          sep = '',end = '',file = self.__outfile)
  def text(self,l):
    self.__outfile.write(l)
  def inlineCode(self,l):
    print('<code>',l,'</code>',sep='',end='',file=self.__outfile)
  def codeHeader(self,name,continued,afterText):
    suffix = ' &rang;&equiv;'
    if continued:
         suffix = ' &rang;+&equiv;'
    prefix='';
    if afterText:
       prefix = '<p>'
    print(prefix,'&lang;',end='',file=self.__outfile)
    process_code_escapes(self,name)
    print(suffix,file = self.__outfile)
  def startCodeBlock(self):
    print('<pre class=listing><code>',end='',file = self.__outfile)
  def endCodeBlock(self):
    print('</code></pre>',file = self.__outfile)
  def codePointer(self,name,number,wspace):
    self.__outfile.write(' '*wspace)
    print('</code>&lt; ',end='',file=self.__outfile)
    process_code_escapes(self,name)
    print(' ',self.__make_section_link(number),' &gt;<code>',sep='',file = self.__outfile)
  def code(self, l):
    self.__outfile.write(self.__sanitize_for_HTML(l))
  def seeAlso(self, sa):
     seealso = map(self.__make_section_link,sa)
     print('<br>See also: ',end = '',file = outfile)
     print(*seealso,sep = ', ',end = '',file = outfile)
     print('.',file=outfile)
  def usedIn(self, ui):
     usedin = map(self.__make_section_link,ui)
     print('<br>This code used in: ',end = '',file = outfile)
     print(*usedin,sep = ', ',end = '',file = outfile)
     print('.',file=outfile)
class TextWeaver:
  def __init__(self,of):
     self.__outfile = of
  def nextEntry(self):
    print('\n\n',end='',file=self.__outfile)
  def entryNumber(self,num,name):
    print('{0}. {1}'.format(num,name or ''),
          sep = '',end = '',file = self.__outfile)
  def text(self,l):
    self.__outfile.write(l)
  def inlineCode(self,l):
    print('|',l,'|',sep='',end='',file=self.__outfile)
  def codeHeader(self,name,continued,afterText):
    if afterText:
      print('',file=self.__outfile)
      print('   < ',end='',file=self.__outfile)
    else:
      print('< ',end='',file=self.__outfile)
    process_code_escapes(self,name)
    if continued:
      print(' >+=',file=self.__outfile)
    else:
      print(' >=',file=self.__outfile)
  def startCodeBlock(self):
    pass
  def endCodeBlock(self):
    print('',file=self.__outfile)
  def codePointer(self,name,number,wspace):
    self.__outfile.write(' '*(wspace+4))
    self.__outfile.write('<')
    process_code_escapes(self,name)
    print(' ',number,'>',sep='',file = self.__outfile)
  def code(self, l):
    self.__outfile.write('    ')
    self.__outfile.write(l)
  def seeAlso(self, sa):
     print('See also: ',end = '',file = outfile)
     print(*sa,sep = ', ',end = '',file = outfile)
     print('.',file=outfile)
  def usedIn(self, ui):
     print('This code used in: ',end = '',file = outfile)
     print(*ui,sep = ', ',end = '',file = outfile)
     print('.',file=outfile)
class LaTeXWeaver:
  def __init__(self,of):
     self.__outfile = of
     self.__inlineCharOpts = '!@$,*:abcdefghijklmnopqrstuvwxyz'
     self.__inCode = False
  def __sanitizeCode(self, c):
    #return c.replace('|','|\\textbar|')
    return c.replace('%','%\char37%')
  def nextEntry(self):
    print('\n\n',end='',file=self.__outfile)
  def entryNumber(self,num,name):
    print('\\bigbreak\\noindent{{\\bfseries {0}. {1}}}'.format(num,name or ''),
          sep = '',end = '',file = self.__outfile)
  def text(self,l):
    self.__outfile.write(l)
  def inlineCode(self,l):
    if self.__inCode:
       # Can't do much already inside a listing...except break back into
       # listing mode...
       print('}%',l,'%\\textrm{',sep='',end='',file=self.__outfile)
    else:
       # select a character not in the string
       goodopts = (c for c in self.__inlineCharOpts if l.find(c) < 0)
       cch = next(goodopts)
       print('\\lstinline',cch,l,cch,sep='',end='',file=self.__outfile)
  def codeHeader(self,name,continued,afterText):
    if afterText:
      print('',file=self.__outfile)
      print('\\noindent$<$ ',end='',file=self.__outfile)
    else:
      print('$<$ ',end='',file=self.__outfile)
    process_code_escapes(self,name)
    if continued:
      print(' $>+\\equiv$',file=self.__outfile)
    else:
      print(' $>\\equiv$',file=self.__outfile)
  def startCodeBlock(self):
    print('\\begin{lstlisting}',file=self.__outfile)
    self.__inCode = True
  def endCodeBlock(self):
    print('\\end{lstlisting}',file=self.__outfile)
    self.__inCode = False
  def codePointer(self,name,number,wspace):
    self.__outfile.write(' '*(wspace+2))
    self.__outfile.write('%\\textrm{$<$')
    process_code_escapes(self,name)
    print(' ',number,'$>$}%',sep='',file = self.__outfile)
  def code(self, l):
    self.__outfile.write('  ')
    self.__outfile.write(self.__sanitizeCode(l))
  def seeAlso(self, sa):
     print('See also: ',end = '',file = outfile)
     print(*sa,sep = ', ',end = '',file = outfile)
     print('.\\\\',file=outfile)
  def usedIn(self, ui):
     print('This code used in: ',end = '',file = outfile)
     print(*ui,sep = ', ',end = '',file = outfile)
     print('.',file=outfile)
class BBCodeWeaver:
  def __init__(self,of):
     self.__outfile = of
  def nextEntry(self):
    print('\n\n',end='',file=self.__outfile)
  def entryNumber(self,num,name):
    print('[b]{0}. {1}[/b]'.format(num,name or ''),
          sep = '',end = '',file = self.__outfile)
  def text(self,l):
    self.__outfile.write(l)
  def inlineCode(self,l):
    print('[color=green]',l,'[/color]',sep='',end='',file=self.__outfile)
  def codeHeader(self,name,continued,afterText):
    if afterText:
      print('',file=self.__outfile)
      print('[color=green]< ',end='',file=self.__outfile)
    else:
      print('[color=green]< ',end='',file=self.__outfile)
    process_code_escapes(self,name)
    if continued:
      print(' >+=[/color]',file=self.__outfile)
    else:
      print(' >=[/color]',file=self.__outfile)
  def startCodeBlock(self):
    print('[code]',file=self.__outfile)
  def endCodeBlock(self):
    print('[/code]\n',file=self.__outfile)
  def codePointer(self,name,number,wspace):
    self.__outfile.write(' '*wspace)
    self.__outfile.write('<')
    process_code_escapes(self,name)
    print(' ',number,'>',sep='',file = self.__outfile)
  def code(self, l):
    self.__outfile.write(l)
  def seeAlso(self, sa):
     print('[i]See also: ',end = '',file = outfile)
     print(*sa,sep = ', ',end = '',file = outfile)
     print('.[/i]',file=outfile)
  def usedIn(self, ui):
     print('[i]This code used in: ',end = '',file = outfile)
     print(*ui,sep = ', ',end = '',file = outfile)
     print('.[/i]',file=outfile)
print('pyweave v0.2 '
      '(c) 2011 Richard Todd '
      '<richard@richardtodd.name>')
print()
filename = sys.argv[1]
print('Reading',filename)
with fp.FileProcessor(open(filename,'r')) as infile:
    infile.register("out-extension",set_ext,False);
    line = "@+\n" # start with RAW html...
    while True:
       if len(line) == 0:
           break
       elif is_text_head(line):
          line = process_text(infile,line)
       elif is_code_head(line):
          line = process_code(infile,line)
       else:
          raise SyntaxError("Unknown input: "+line)
outfilename = filename[:filename.rindex('.')] + '.' + outExtension
print('Writing',outfilename)
with open(outfilename,'w') as outfile:
    formatter = None
    if outExtension == "txt":
      formatter = TextWeaver(outfile)
    elif outExtension == "tex":
      formatter = LaTeXWeaver(outfile)
    elif outExtension == "html":
      formatter = HTMLWeaver(outfile)
    elif outExtension == "bbcode":
      formatter = BBCodeWeaver(outfile)
    for entry in input_db:
       formatter.nextEntry()
       if (entry.number != None):
         formatter.entryNumber(entry.number,entry.text_name)
       for l in entry.text:
          process_code_escapes(formatter,l)
       if entry.code_name:
          reg_ent = name_registry[entry.code_name]
          formatter.codeHeader(entry.code_name,
                               reg_ent.defined[0] != entry.number,
                               len(entry.text) > 0)
          formatter.startCodeBlock()
          for l in entry.code:
             if is_code_pointer(l):
                pname = extract_code_pointer(l)
                formatter.codePointer(pname,name_registry[pname].defined[0],len(l)-len(l.lstrip()))
             else:
                formatter.code(l)
          formatter.endCodeBlock()
          seealso = [e for e in reg_ent.defined if e != entry.number]
          if len(seealso)>0:
            formatter.seeAlso(seealso)
          if len(reg_ent.used_in)>0:
            formatter.usedIn(reg_ent.used_in)
print('Done!')
