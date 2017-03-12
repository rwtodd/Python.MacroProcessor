import io

def proof_text(processor, txt):
   ans = io.StringIO()
   print('{\obeylines',file=ans)

   for line in [ i for i in txt.splitlines() if i != '' ]:
     if line[0]=='#':
        ln = line.strip()
        if len(ln)>1:
           print(line[1:],file=ans)
     elif line[0].isspace():
        print('\qquad',line.strip(),file=ans)
     else:
        spl = line.find(' ') 
        if spl < 0:
          print(line,file=ans)
        else:
          print(line[:spl],'&&',line[spl+1:].strip(),file=ans)

   print('}',file=ans) 
   return ans

processor.register("proof",proof_text,False)
