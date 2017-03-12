@[ import rwt_processor.article as rwt @]@rem

@[article-start: "An Article Template"
                 RWT-013
                 2010-10-25 @]

@ One of the main reasons I built the processor in @{rwt.article_ref(12)@}
was to facilitate my HTML articles.  Since they all have the same formatting,
it makes sense to hide away all the tedious details that never change.  More importantly,
it makes it easy to change the formatting of the entire article set, by changing the
processor module and re-processing the documents.

@ Though my version of this module is customized for <a href="http://www.movethemarkets.com">MtM</a>,
the module presented here has all the same commands in it.  It is a bare-bones template, ready
for your customization.

@ An example article text looks like this, when using the module:
@<file:example_article.w@>=
@@[import rwt_processor.article@@]

@@[article-start:  "The Title"
                  "The Subtitle"
                  2010-10-25 @@]

Hi there, here's an article.

@@signature

@@article-end

@ The code can be downloaded here: <a href="http://www.movethemarkets.com/downloads/rwt/rwt013/article.tgz">article.tgz</a>

@ Let's get started!
@<file:article.py@>=
import io

# Install this as rwt_processor.article

@<Functions@>
@<Register commands with the processor@>

@ We have a function to cover all the prematter in the document, covering headers and titles.  Everything
up until the first paragraph of article text:
@<Functions@>=
def frontmatter(title,subtitle,date):
  return ('''<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>{0}</title>
</head>
<body>
<div id="header">
<h1><a href="http://www.mywebsite.com">My Website</a></h1>
</div>

<div id=content><h1>{0}</h1>
<div class="titleinfo">{1}<br>{2}</div>'''.
format(title,subtitle,date))

@ During a document, I like to be able to reference other documents 
in the series.  If you use this, you'll need to customize it to provide 
a correct link for the article reference passed in.  This default version
just returns whatever string was passed in:
@<Functions@>=
def article_ref(a):
  return a

@ Towards the end of a document, but before the postmatter like end-notes, I leave a signature.
@<Functions@>=
def signature():
  return "<address>My Name</address>"

@ Finally, at the bottom of the document I need to close off the |content| div, and put in a 
standard footer, etc.
@<Functions@>=
def endmatter():
  return ('''</div><div id="footer"><p>&copy; 2010 My Name.
All rights reserved.</p></div></body></html>''')

@* Registering commands. All of the functions above can be called within
the document, but we can provide a slightly nicer interface as well, by
registering commands with the |FileProcessor|.  So that the signature can 
be called via "|@@signature|" rather than "|@@{article.signature()@@}|"

<p>First we define wrapper functions that the processor will call:
@<Functions@>=
def sigCmd(processor,args):
  return signature()
def artCmd(processor,args):
  return frontmatter(args[0],args[1],args[2])
def endCmd(processor,args):
  return endmatter()

@ And finally, we have, the |init_processor_module()| function:
@<Register commands with the processor@>=
def init_processor_module(processor):
  processor.register("article-start",artCmd,True)
  processor.register("signature",sigCmd,False)
  processor.register("article-end",endCmd,False)

@+

@signature

@article-end
