import sys
import io
class FileStack:
  def __init__(self):
    self.__stack = []
  def push(self,fl):
    self.__stack.append(fl)
  def rawchar(self):
    if len(self.__stack)==0:
      return ''
    c = self.__stack[-1].read(1)
    while len(c) == 0:
      old = self.__stack.pop()
      old.close()
      if len(self.__stack)==0:
        return ''
      c = self.__stack[-1].read(1)
    return c
  def curloc(self):
    ## FIXME print what the next line would have been...
    while len(self.__stack)>0 and (not hasattr(self.__stack[-1],'name')):
      self.__stack.pop()
    if len(self.__stack)==0:
      return 'Nowhere'
    return (self.__stack[-1].name + ' at position  ' +
            str(self.__stack[-1].tell()))
  def closeall(self):
    for f in self.__stack:
      f.close()
class FileProcessor:
  def __init__(self,file=None):
    self.__files = FileStack()
    if(file):
      self.__files.push(file)
    self.__commandList = {}
    self.__CHAR = 1
    self.__CMDINIT = 2
    self.__CMDTERM = 3
    self.__CMDNOARG = 4
    self.__REMEOL = 5
    self.__PYTHON = 6
    self.__EOF = 7
    self.__locals = {}
    self.__globals = {}
    self.__globals['__builtins__'] = __builtins__
    self.__globals['processor']=self
  def read(self,n):
    assert(n>0)
    if n == 1:
       return self.__nextchar()
    else:
       return ''.join([self.__nextchar() for i in range(n)])
  def readline(self):
    c = self.__nextchar()
    ans = [c]
    while (c != '\n') and (c != ''):
      c = self.__nextchar()
      ans.append(c)
    return ''.join(ans)
  def pushfile(self,fl):
    self.__files.push(fl)
  def register(self,name,cmd,parsed):
    n = name.upper()
    if (n in self.__commandList):
      print('Warning: duplicate command "{0}" installed!'.format(n),
            file=sys.stderr)
    self.__commandList[n]=(cmd,parsed)
  def __token(self):
    c = self.__files.rawchar()
    if len(c)==0:
      return (self.__EOF,None)
    elif c == '@':
      c2 = self.__files.rawchar()
      if c2 == '@':  # the @@ case...
        return (self.__CHAR,c2)
      elif c2 == '{' or c2 == '(' or c2 == '[':
        chars = []
        c = self.__files.rawchar()
        while(c.isalnum() or c=='_' or c=='-'):
          chars.append(c)
          c = self.__files.rawchar()
        if c != ':':
          chars.append(c)
          self.__files.push(io.StringIO(''.join(chars)))
          return (self.__PYTHON,c2)
        else:
          cname = ''.join(chars).upper()
          return (self.__CMDINIT,(c2,cname))
      elif c2 == '}' or c2 == ')' or c2 == ']':
         return (self.__CMDTERM,c2)
      elif (c2.isalnum() or c2=='-' or c2=='_'):
        chars = [c2]
        c = self.__files.rawchar()
        while(c.isalnum() or c=='_' or c=='-'):
          chars.append(c)
          c = self.__files.rawchar()
        if c != ':':
          self.__files.push(io.StringIO(c))
        cname = ''.join(chars).upper()
        if cname == 'REM':
          return (self.__REMEOL,None)
        return (self.__CMDNOARG,cname)
      else:
        self.__files.push(io.StringIO(c2))
    return (self.__CHAR,c)
  def __nextchar(self,inComment=False,inBraces=False):
    typ, c = self.__token()
    if typ==self.__CHAR:
      return c
    elif typ==self.__PYTHON:
      text = self.__readUntilClosingBraces(inComment,c).lstrip()
      if not inComment:
        try:
           ans = eval(text,self.__globals,self.__locals)
           self.__interpretResults(ans)
        except SyntaxError:
           exec(text,self.__globals,self.__locals)
           if text.startswith('import '):
             for ln in text.split('\n'):
               spl = ln.split()
               if spl[0]=='import':
                  mod = spl[1]
                  # import x as y
                  if (len(spl) == 4) and (spl[2]=='as'):
                     mod = spl[3]
                  exec('if hasattr({0},"init_processor_module"): '
                       '{0}.init_processor_module(processor)'.format(mod),
                       self.__globals,self.__locals)
               else:
                 break
      return self.__nextchar(inComment)
    elif typ==self.__CMDINIT:
      if c[1] == 'REM':
        self.__readUntilClosingBraces(True,c[0])
      else:
        args = self.__readUntilClosingBraces(inComment,c[0]).strip()
        self.__executeCommand(c[1],args,inComment)
      return self.__nextchar(inComment,inBraces)
    elif typ==self.__CMDNOARG:
      self.__executeCommand(c,'',inComment)
      return self.__nextchar(inComment,inBraces)
    elif typ==self.__REMEOL:
      c = self.__files.rawchar()
      while c != '' and c != '\n':
        c = self.__files.rawchar()
      return self.__nextchar(inComment,inBraces)
    elif typ==self.__CMDTERM:
      if ( (inBraces=='{' and c=='}') or
           (inBraces=='[' and c==']') or
           (inBraces=='(' and c==')') ):
         return None
      else:
         raise SyntaxError('Unexpected closing brace while processing '+
                           self.__files.curloc())
    elif typ==self.__EOF:
          if inBraces==False:
            return ''
          else:
            raise SyntaxError('Unexpected EOF while inside a command!"')
    else:
      raise Exception('Bad Token! '+str(typ)+str(c)+' while processing '+
                      self.__files.curloc())
  def __executeCommand(self,c,args,inComment):
    if not inComment:
      try:
        func,parsed = self.__commandList[c]
      except KeyError:
        raise SyntaxError('Never heard of a command named '+c+' near ' +
                          self.__files.curloc())
      else:
        if parsed:
           parsed = []
           sloc = 0
           eloc = 0
           while( eloc < len(args) ):
             # find the first letter...
             while args[eloc].isspace():
                eloc = eloc + 1
             sloc = eloc
             if(args[sloc] == '"'):
                eloc = args.find('"',sloc+1)
                if(eloc > 0):
                   parsed.append(args[sloc+1:eloc])
                   eloc = eloc + 1
                else:
                   raise SyntaxError('Mismatched quotes in <' +
                                      args + '> near ' +
                                      self.__files.curloc())
             else:
                 eloc = eloc + 1
                 while( eloc < len(args) and
                        not args[eloc].isspace() ):
                     eloc = eloc + 1
                 parsed.append(args[sloc:eloc])
           args = parsed
        try:
           self.__interpretResults( func(self,args) )
        except Exception as e:
           raise Exception("Error: "+str(e)+" near " +
                           self.__files.curloc())
  def __readUntilClosingBraces(self,inComment,brace):
    ans = []
    c = self.__nextchar(inComment,brace)
    while c != None:
      ans.append(c)
      c = self.__nextchar(inComment,brace)
    return ''.join(ans)
  def __interpretResults(self,r):
    if isinstance(r,io.StringIO):
      r.seek(0)
      self.__files.push(r)
    elif isinstance(r,io.TextIOBase):
      self.__files.push(r)
    elif isinstance(r,str):
      if len(r)>0:
        self.__files.push(io.StringIO(r))
    elif r != None:
      self.__files.push(io.StringIO( str(r) ))
  def __enter__(self):
    return self
  def __exit__(self,t,v,tb):
    self.__files.closeall()
    return False
