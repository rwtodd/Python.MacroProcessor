@[import rwt_processor.article@]@rem

@[article-start: "A Useful File Pre-Processor"
                 RWT-012
                 2010-10-21 @]

@* Introduction. Writing HTML with numbered end-notes can be frustrating; if I add an
end-note in the middle of the document, they may need to be renumbered.  Writing a 
series of articles with similar formatting can be tedious and error-prone.  Manually
crafting tables to represent game-theory payoffs, for example, is a pain.  I can
write simple software filters to help with these and other tasks, but before long it
makes sense to create a generally useful and extensible text filter.

@ This short article describes a python utility module 
that pre-processes a text file to prepare it for other uses. The public interface is
in a single class, |FileProcessor|. To a user, a |FileProcessor| object
looks and acts just like a standard python file object.  So, the user just
calls |read()| and |readline()| like normal, and gets processed text rather 
than the raw text of the input file.

<p>The capabilities of the processor are practically endless, as all of the
work is delegated to modules that define the commands.  New commands can even
be created <em>during the processing</em>.  So, |FileProcessor| itself is 
mainly a parser for recognizing commands and delegating them out:

<ul>
  <li>It can recognize a command preceeded by an '|@@|'-symbol.  As in, "|@@break|", which
  might be a command that produces a large line break in the text, for example.  Commands
  executed in this form have no arguments.
  <li>It can recognize a command in the form "|@@{break: 5@@}|", and in this form the text
  after the '|:|' is sent as arguments to the command.  The example given might insert 
  5 newlines, perhaps.  The user can use |@@{ @@}|, |@@( @@)|, or |@@[ @@]| as delimiters.
  <li>It allows for the execution of arbitrary python code, with the result
      of the calculation textually inserted into the text stream.  This command takes the
      second form above, only with no name, as in: "|@@{ 1 + math.sin(0.2) @@}|" or 
      "|@@{ import rwt_article as rwt @@}|"  
  <li>It allows users to escape the '@@'-symbol with another '@@'-symbol.  This is because
  the text "|richard@@movethemarkets.com|"  would assume that |movethemarkets.com| is a 
  command that needs to be executed.  So, I can type "|richard@@@@movethemarkets.com|" to
  get the |@@| symbol through unprocessed.
</ul>

<p>The only built-in commands will be the nameless "execute python code" command,
and the |rem| command.  The |rem| command acts as a comment, stripping text out of the input 
stream and not passing it through.  All other commands will be built modularly and 
installed in the processor when they are imported.  We'll create a few generally-useful
commands in this very report, so you can see how it's done!

<p>Case is not sensitive on the command names (so |@@rem| or |@@REM| or even |@@rEm| are all ok).

@ This module is used to build all of my articles.  It allows me to 
write in this fashion:
<pre class=listing><code>@@{import math@@}@@rem
@@{import rwt_processor.command.inc @@}@@rem
@@{import rwt_processor.article @@}@@rem

@@{article-start: "Rapid Eye Movement"
                  RWT-012
                  2010-11-04 @@}

&lt;h2&gt;Intro&lt;/h2&gt;
You know, the sine of @@{ math.pi @@} is @@{ math.sin(math.pi) @@}.

@@{inc: sect1.html @@} @@{rem: don't forget to copy this... @@}
@@{inc: sect2.html @@}
@@{inc: sect3.html @@}

&lt;h2&gt;Outro&lt;/h2&gt;
That's it!

@@signature

@@article-end

</code></pre>

@* Implementation.  The module is called |processor|, which is installed as |rwt_processor.processor|.  
@<file:processor.py@>=
import sys
import io

@<Helper classes@>

class FileProcessor:
  @<FileProcessor methods@>

@ So, you'd instantiate the |FileProcessor| with a file, typically.  In general, the processor
will need to maintain a stack of files.  This is to support concepts like processing the output
of commands, such that commands can produce commands and cause recursion.  As we'll see, it will
also help us backtrack in the parser, and process inclusion of files from within the first file, etc. 
So, we'll create a helper class |FileStack| to handle the complication of reading from the next available
input stream.

@<FileProcessor methods@>=
def __init__(self,file=None):
  self.__files = FileStack()
  if(file):
    self.__files.push(file)
  @<FileProcessor initialization@>

@ The |FileStack| is pretty straightforward:
@<Helper classes@>=
class FileStack:
  def __init__(self):
    self.__stack = []

  def push(self,fl):
    self.__stack.append(fl)

  @<FileStack methods@>

@ We know we'll need a way to grab the next raw character from the input stack, so let's
go ahead and define it.
@<FileStack methods@>=
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

@ Ok, back to |FileProcessor|.  We'll provide the typical |read()| and |readline()| interfaces, 
with the exception that the unbounded version of |read()| is not supported.  The real work of tokenizing
the input and processing commands is delegated to |nextchar()|, which we'll get to later.

@<FileProcessor methods@>=
def read(self,n):
  assert(n>0)
  if n == 1:
     return self.__nextchar()
  else:
     return ''.join([self.__nextchar() for i in range(n)])

@ Reading a line is as easy as calling |nextchar()| until we get
either a newline or the EOF.

@<FileProcessor methods@>=
def readline(self):
  c = self.__nextchar()
  ans = [c]
  while (c != '\n') and (c != ''):
    c = self.__nextchar()
    ans.append(c)
  return ''.join(ans)

@ If a user wants to push an input file into the front of the processor's stack, they can do that.  This way,
you can set it up to process a series of files in a sort-of batch mode if you want.
@<FileProcessor methods@>=
def pushfile(self,fl):
  self.__files.push(fl)

@* Commands Interface.  As I mentioned in the introduction, the set of commands that the processor can handle
is not only extensible, but dynamic at runtime.  So, part of our public interface will be devoted to registering
new commands.  When you register a command, you give it a name, a function to call to handle the command, and
tell whether you want the arguments parsed out for you or not.  More on that later.
@<FileProcessor methods@>=
def register(self,name,cmd,parsed):
  n = name.upper()
  if (n in self.__commandList):
    print('Warning: duplicate command "{0}" installed!'.format(n),
          file=sys.stderr)
  self.__commandList[n]=(cmd,parsed)

@ We'll initialize our command list during |__init__|:
@<FileProcessor initialization@>=
self.__commandList = {}

@ As an example of how commands work, let's define an "|inc|" command, to pull in the text of a named file.
Since there's no state to store, we can define our command as a simple function, |run()|.   The function 
returns an opened file, which the |FileProcessor| will duly push onto the stack for us.  If we had returned
a string or a number or a list, that would have been turned into a string and pushed onto the input stack
for processing as well, in the form of an |io.StringIO| memory stream.  So, the processor tries to be
reasonably intelligent about what to do with our return values.

<P>The |init_processor_module()| function will be called by the |FileProcessor| when this module is loaded, to 
give it a chance to register any commands it may have.  A single module can register any number of
commands.
@<file:inc.py@>=
def run(processor,args):
   if len(args)>1:
      raise Exception("Too many arguments to INC: "+str(args))
   return open(args[0],'r')

def init_processor_module(processor):
  processor.register("inc",run,True)

@ Note that, in many cases, you won't want to define new parser commands, but merely import a module that
makes functions and classes available to you.  This is also possible. For instance, we could have also
defined the "|inc|" functionality like this:

<pre class=listing><code>def include(fname):
  return(open(fname,'r'))
</code></pre>

<p>...and called it like this from our document:

<pre class=listing><code>
@@{ import rwt_processor.commands.inc as inc @@}

@@{ inc.include("test1.html") @@} @@rem works just as well...

@@{ open("test1.html",'r') @@} @@rem of course, so does this!
</code></pre>

<p>So the point is, you have options.  

@ Let's define a more complex command module, this time for tracking and referencing end-notes.
Note that, this time, we have to maintain state across two commands, so we put them in the 
same object.  We register bound methods with the processor in |init_processor_module()|, which works
great for our purposes.
@<file:endnotes.py@>=
import io

class EndNotes:
  def __init__(self):
    self.__notes = []

  def add(self,processor,text):
    self.__notes.append(text)
    return ( '<sup><a href="#ENDNOTE-{0}">{0}</a></sup>'.
                format(len(self.__notes)) )

  def output(self,processor,text):
    if len(text)>0:
      raise Exception('Not expecting arguments when outputting endnotes!')
    fl = io.StringIO()
    print('<ol>',file=fl)
    for i,n in enumerate(self.__notes):
      print('<li id="ENDNOTE-{0}">{1}</li>'.format(i,n),
            file=fl)
    print('</ol>',file=fl)
    return fl

def init_processor_module(processor):
  notes = EndNotes()
  processor.register("endnote",notes.add,False)
  processor.register("output-notes",notes.output,False)

@ That short module is the exact code I use for end-notes in my articles.  An 
example of using this module might look like:
<pre class=listing><code>@rem
@@[ import rwt_processor.command.endnotes @@]

...
And here's a thing@@[ENDNOTE: Things are pretty cool. @@] you 
should know.

...

&lt;h2&gt;End Notes&lt;/h2&gt;
@@OUTPUT-NOTES</code></pre>

@ So that's the public interface of the |FileProcessor|.  You can see all the real command-parsing and dispatch
happens in the |nextchar()| method.  We'll spend most of the rest of this article building that up.

@* A Tokenizer. We're about to get to |nextchar()|, but first we'll need a tokenizer
to break the input stream into:
<ul>
  <li>Normal characters.
  <li>Command initiators (|@@{name: |):
   <li>Command terminators (|@@}|)
   <li>Commands without arguments (|@@name| or |@@name:|)
   <li>The special case: end-of-line |@@rem|
   <li>The special case: arbitrary python code (|@@{ code @@}|)
</ul>
<p>The tokenizer won't know or care how to process the commands... it just splits
up the text into useful guideposts for |nextchar()| to use.

@ Those guideposts will need easy-to-check tags.  We'll store them at the object level.
@<FileProcessor initialization@>=
self.__CHAR = 1
self.__CMDINIT = 2
self.__CMDTERM = 3
self.__CMDNOARG = 4
self.__REMEOL = 5
self.__PYTHON = 6
self.__EOF = 7

@ The basic plan for the tokenizer is simple... assume you are going to get 
a character, unless you spot a '|@@|.'  If you spot a '|@@|,' check to see
if you have one of the other tokens.
@<FileProcessor methods@>=
def __token(self):
  c = self.__files.rawchar()
  if len(c)==0:
    return (self.__EOF,None)
  elif c == '@@':
    @<Check for a command@>
  return (self.__CHAR,c)

@ Here, we're reading ahead to see if we have a command
token.  In the case where we have to back up again, we just
push the string onto our input stack, rather than using costly
|seek()| and |tell()| calls.  In the first version of this code,
I did |seek()| and |tell()|, but it turned out to be a costly
bottleneck.
@<Check for a command@>=
c2 = self.__files.rawchar()
if c2 == '@@':  # the @@@@ case...
  return (self.__CHAR,c2) 
elif c2 == '{' or c2 == '(' or c2 == '[':
  @<Tokenize a command in braces@>
elif c2 == '}' or c2 == ')' or c2 == ']':
   return (self.__CMDTERM,c2)
elif (c2.isalnum() or c2=='-' or c2=='_'):
  @<Tokenize a command with no args@>
else:
  self.__files.push(io.StringIO(c2))

@ When we get inside braces, we start looking for a command name.  These
can any amount of alphanumerics, plus dashes and underscores. 
 If we find a colon-delimited word, we assume it is a command name.
If we don't find a command name, we assume we are looking at
arbitrary python code.

@<Tokenize a command in braces@>=
chars = []
c = self.__files.rawchar()
while(c.isalnum() or c=='_' or c=='-'):
  chars.append(c)
  c = self.__files.rawchar()
if c != ':':
  @<Tokenize python code@>
else:
  cname = ''.join(chars).upper()
  return (self.__CMDINIT,(c2,cname))

@ By the time we realize it's not a command, we have already read some of our
python code, so we need to push it back onto our input stack in an |io.StringIO|
object:
@<Tokenize python code@>=
chars.append(c)
self.__files.push(io.StringIO(''.join(chars)))
return (self.__PYTHON,c2)

@ Now, in the no-args case, we just read in an identifier like we did in the braces case.  
No-arg commands end with the first space, colon, or paren.  If the delimiter is a colon, 
we'll eat it.  This way, a command can be wedged into some text, as in: "|Mr.@@nbsp:Todd.|" 
@<Tokenize a command with no args@>=
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


@* nextchar().  Now we get to the most important part of the class, which is |nextchar()|.
It basically returns one character, but processes all of the commands it finds
along the way.  So, this is the code that knows how to process an inclusion, execute
arbitrary python code, etc.

@<FileProcessor methods@>=
def __nextchar(self,inComment=False,inBraces=False):
  typ, c = self.__token()
  if typ==self.__CHAR:
    return c
  elif typ==self.__PYTHON:
    @<Process python code@>
  elif typ==self.__CMDINIT:
    @<Process a command@>
  elif typ==self.__CMDNOARG:
    @<Process a no-arg command@>
  elif typ==self.__REMEOL:
    @<Process an eol comment@>
  elif typ==self.__CMDTERM:
    @<Process a closing brace@>
  elif typ==self.__EOF:
    @<Process the end-of-file@>
  else:
    raise Exception('Bad Token! '+str(typ)+str(c)+' while processing '+ 
                    self.__files.curloc())

@ During our exception handling, we used a method called |curloc()| on our
|FileStack|, so let's define it before moving on:
@<FileStack methods@>=
def curloc(self):
  ## FIXME print what the next line would have been...
  while len(self.__stack)>0 and (not hasattr(self.__stack[-1],'name')):
    self.__stack.pop()
  if len(self.__stack)==0:
    return 'Nowhere'
  return (self.__stack[-1].name + ' at position  ' + 
          str(self.__stack[-1].tell()))
   
@ Processing a command is easy... just look it up and run it. 

To get the arguments, we use a helper method |readUntilClosingBraces()|, which
we'll define in a bit, but whose purpose should be obvious.   We again have to
special-case the |@@REM| command, to properly set |inComment| and avoid processing
code while reading text meant to be elided.
@<Process a command@>=
if c[1] == 'REM':
  self.__readUntilClosingBraces(True,c[0])
else:
  args = self.__readUntilClosingBraces(inComment,c[0]).strip()
  self.__executeCommand(c[1],args,inComment)
return self.__nextchar(inComment,inBraces)

@ Here's the code that executes the command we found, which looks more
complicated than it is.  More of this code is for error-catching than 
anything else.  We don't perform the command if we are inside a comment.
@<FileProcessor methods@>=
def __executeCommand(self,c,args,inComment):
  if not inComment:
    try:
      func,parsed = self.__commandList[c]
    except KeyError:
      raise SyntaxError('Never heard of a command named '+c+' near ' +
                        self.__files.curloc())
    else:
      if parsed:
         @<Split args up@>
      try:
         self.__interpretResults( func(self,args) )
      except Exception as e:
         raise Exception("Error: "+str(e)+" near " +
                         self.__files.curloc())
     
@ A user can call a parsed command with quotes around some words,
which causes those words to count as a single argument.  For instance,
|@@{inc: "my favorite text file.txt" @@}| should receive one argument, and
not four.
@<Split args up@>=
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

@ A no-arg command is virtually identical to the braces case:
@<Process a no-arg command@>=
self.__executeCommand(c,'',inComment)
return self.__nextchar(inComment,inBraces)

@ The one special case of a no-arg command was the |@@rem|, which will throw away raw characters
until a newline is hit.  It's the fact that it works on raw characters and not processed ones
that forces us to make it a special case.
@<Process an eol comment@>=
c = self.__files.rawchar()
while c != '' and c != '\n':
  c = self.__files.rawchar()
return self.__nextchar(inComment,inBraces)

@ Processing arbitrary python code is easy... except that the language
distinguishes between <em>statements</em> and <em>expressions</em>.  So,
we assume that we are processing an expression, and if python disagrees,
we try to process the code as statements.  Note also that expressions cause output,
while statements can only cause processing.  Of course we don't execute 
anything if we are inside a comment.

<p>Note that we push the output from an expression onto the |__files| stack, so that
the result will be processed like all other text.  This makes it possible to run
metacommands that produce commands!

@<Process python code@>=
text = self.__readUntilClosingBraces(inComment,c).lstrip()
if not inComment:
  try:
     ans = eval(text,self.__globals,self.__locals)
     self.__interpretResults(ans)
  except SyntaxError:
     exec(text,self.__globals,self.__locals)
     @<Notice if the |text| was an |import|, and register commands@>
return self.__nextchar(inComment)

@ We'll store our working sandbox local and global namespaces at the 
object level, and initialize them at construction.

@<FileProcessor initialization@>=
self.__locals = {}
self.__globals = {}
self.__globals['__builtins__'] = __builtins__

@ We'll also make the processor itself available to our arbitrary code.  It can
come in handy for weird cases when your code wants to |read()| ahead in the stream.  Of 
course, extreme care should be taken if you ever do this!

@<FileProcessor initialization@>=
self.__globals['processor']=self

@ There is one unique situation when executing arbitrary python code.  That is, when
we have an |import| statement, we may be importing a module which defines some new
commands for our processor.  We looked at some example modules that did this earlier, and
they registered their commands in a function called |init_processor_module()|.  Well, for that to work,
the processor is going to have to notice the import and then call that function.

<p>Note that we don't go looking through all the code for imports... only the first 
lines in the bunch is noted.  As soon as a line doesn't start with "|import|", we stop
looking. 
@<Notice if the |text| was an |import|, and register commands@>=
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
      
@ When we get a |CMDTERM|, it's cool as long as we were looking for it. 
@<Process a closing brace@>=
if ( (inBraces=='{' and c=='}') or
     (inBraces=='[' and c==']') or
     (inBraces=='(' and c==')') ): 
   return None     
else:
   raise SyntaxError('Unexpected closing brace while processing '+ 
                     self.__files.curloc())

@ If we get to the end of the file, it's always ok <em>unless</em> we were
reading inside of braces:
@<Process the end-of-file@>=
    if inBraces==False:
      return ''
    else:
      raise SyntaxError('Unexpected EOF while inside a command!"')

@* Odds and Ends. 

@ In a couple of these code paths, we've needed 
to pull text up until a closing bace.  At long last, here is that code:

@<FileProcessor methods@>=
def __readUntilClosingBraces(self,inComment,brace):
  ans = []
  c = self.__nextchar(inComment,brace)
  while c != None:
    ans.append(c)
    c = self.__nextchar(inComment,brace)
  return ''.join(ans)

@ We had a helper method to interpret the results of our commands that 
still needs to be defined.  Basically, if it's a file or a string of 
some kind, we push it onto the input stack.  If it's |None|, we ignore it. 
If it's anything else, we call |str()| on it and push it 
onto the input stack.  The only wrinkle with |StringIO| results is that,
when you build one up, you have to |seek(0)| in order to read it back.
So here, we assume that's what is needed, which keeps every command
that builds up a string from having to do it. 
@<FileProcessor methods@>=
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

@ Lastly, we want to be able to use a |FileProcessor| with the python |with| statement.
So, we'll need to handle the |__enter__()| and |__exit__()| methods, which is 
fortunately very easy.

@<FileProcessor methods@>=
def __enter__(self):
  return self
def __exit__(self,t,v,tb):
  self.__files.closeall()
  return False

@
@<FileStack methods@>=
def closeall(self):
  for f in self.__stack:
    f.close()

@* rwtproc. Finally, a little utility to read a given file, and print out the processed version.
@<file:rwtproc.py@>=
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
 
@ And, with that, we're done!  You can get the python code from this article here: 
<a href="http://www.movethemarkets.com/downloads/rwt/rwt012/rwt_processor.tgz">rwt_processor.tgz</a>.

@signature

@rem no end notes ... 

@article-end
