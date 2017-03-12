import io

# Minimal LaTeX article for weaving...

preamble = '''
\\documentclass{article}

\\usepackage[left=1.5in,right=1.5in]{geometry}
\\usepackage{color}
\\usepackage{listings}

\\begin{document}
\\lstset{language={},backgroundcolor=\\color[rgb]{0.95,0.95,0.95},basicstyle=\\small\\ttfamily,escapechar=\\%}


'''

def artCmd(processor,args):
   ans = io.StringIO()
   print(preamble,file=ans)
   print('\\title{',args[0],'}',sep='',file=ans)
   print('\\author{',args[1],'}',sep='',file=ans)
   print('\\date{',args[2],'}',sep='',file=ans)
   print('\\maketitle',file=ans)
   return ans
  
def artEnd(proc,txt):
   return '\\end{document}\n'

def init_processor_module(processor):
   processor.register("article-start",artCmd,True)
   processor.register("article-end",artEnd,False)
