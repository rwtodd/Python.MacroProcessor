import io

# A minimal literate programming style for html.
# compatible with article.py for specific uses

# stylesheet ref looks like this:
#   <link href="../rwtstyle3.css" rel="stylesheet" type="text/css"> 

zz_hdr = '''<!DOCTYPE html>
<html> 
<head> 
<meta charset="UTF-8" />
<style type="text/css">
div#content > pre.listing {{
  background-color: #eee;
  color: #000;
  font-size: 1em;
  border-right: 2px solid #aaa;
  border-bottom: 2px solid #aaa;
  margin: 1.12em 4em;
  padding-left: 1em;
  padding-top: 1em;
  padding-bottom: 1em;
}}

code {{
  font-family: "Courier New", Courier, monospace;
}}

div.titleinfo {{
  color: #000;
  font-size: 1.25em;
  font-weight: normal;
  margin-top: 0em;
}}

div#footer {{
  font-style: italic;
  color: #333;
  font-size: 0.8em;
}}
</style>
<title>{0}</title> 
</head> 
<body> 
<div id=header> 
<h1>{0}</h1>
</div> 

<div id=content>'''

zz_author = ''
zz_date = ''

zz_footer = '''<div id=footer> 
<p>&copy; {0} by {1}.  All rights reserved. 
</div>'''

zz_bottom = '''</body> 
</html>'''

def frontmatter(title,author,date):
  global zz_author 
  global zz_date
  zz_author = author
  zz_date = date
  ans = io.StringIO()
  print(zz_hdr.format(title),file=ans) 
  print('<div class=titleinfo>{0}<br>{1}</div>'.format(author,date),file=ans)
  return ans

def endmatter():
  ans = io.StringIO()
  print('</div>',file=ans)
  print(zz_footer.format(zz_date,zz_author),file=ans)
  print(zz_bottom,file=ans)
  return ans


# command version so we can type @signature
def artCmd(processor,args):
  return frontmatter(args[0],args[1],args[2])
def endCmd(processor,args):
  assert(len(args)==0)
  return endmatter()

def init_processor_module(processor):
  processor.register("article-start",artCmd,True) # @[article-start: title author date@]
  processor.register("article-end",endCmd,False)  # @article-end

