import io
# goes in rwt_processor.tex

def artCmd(processor, args):
  ans = io.StringIO()
  print('\\title{',args[0],'}\\date{',args[1],'}\\author{Richard Todd}\\maketitle',sep='',file=ans)
  print('\\setlength{\\parindent}{0pt}\\setlength{\\parskip}{1ex plus 0.5ex minus 0.2ex}',file=ans)
  return ans

def init_processor_module(proc):
  proc.register("article-start",artCmd,True)
