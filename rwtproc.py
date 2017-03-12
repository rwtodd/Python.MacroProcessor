#!/usr/bin/env python3
import rwt_processor.processor as proc
import sys
outext = "txt"
def set_ext(processor,txt):
  global outext
  outext = txt
def out_filename(fn):
  loc = fn.rfind('.')
  if loc > 0:
    return fn[:loc+1] + outext
  else:
    return fn + '.' + outext
infile = proc.FileProcessor( open(sys.argv[1],'r') )
infile.register("out-extension",set_ext,False)
with infile:
  l = infile.readline()
  with open(out_filename(sys.argv[1]),'w') as outfile:
    while l != '':
      outfile.write(l)
      l = infile.readline()
