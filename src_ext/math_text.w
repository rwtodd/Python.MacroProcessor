@[import rwt_processor.article as rwt @]@rem
@[import rwt_processor.command.math_text @]@rem
@[article-start: "A Math Module for the FileProcessor"
                 RWT-015
                 2010-10-26 @]

@ Some of the more formal articles I plan to write have elements
of predicate calculus and other maths, which means I need an easy way to produce
the typical symbols, tables, and diagrams.  This article describes a 
small module for @{ rwt.article_ref(12) @}'s |FileProcessor| to
help with all things mathy.  Right now, it only has code to help
print simple equations, but the functionality will no doubt 
grow over time.

<p>With this module, I can type:<br>
<pre class=listing><code>@@[math: p or !q => (E.x: 0<=x<=N, b[x] NELEM c) @@]</code></pre>
<p>... and get:
<pre class=listing><code>@[math: p or !q => (E.x: 0<=x<=N, b[x] NELEM c) @]</code></pre>

<p>The code from this article can be downloaded here: <a href="http://www.movethemarkets.com/downloads/rwt/rwt015/math_text.tgz">math_text.tgz</a>

@* Implementation. So, as with all simple modules for |FileProcessor|, the file
consists of a few functions and the registration code.
@<file:math_text.py@>=
@<Functions@>
@<Register commands with the |FileProcessor|@>

@ First and foremost, I want to be able to type naturally.  Instead
of typing |&equiv;| to get the '&equiv;' symbol, I'd like to type '|=|'.
Instead of typing |&or;| to get the '&or;' symbol, I'd like to type '|or|'
or '||'.  You get the idea.

<p> The implementation here is not too flashy... just a series of full-text
replacements.  I can get away with this because the equations to translate
will never be too long.  One drawback is that it makes the order of replacements
dependent on each other.  In other words, I have to replace "NELEM" before I
replace "ELEM," because otherwise the "ELEM" check will erroneously match
"NELEM."

@<Functions@>=
def math_text(processor,text):
  # RELATIONS
  text = text.replace('<=','&le;')
  text = text.replace('>=','&ge;')
  text = text.replace('<','&lt;')
  text = text.replace('>','&gt;')

  # JUNCTIONS
  text = text.replace(' or ',' &or; ')
  text = text.replace('||','&or;')
  text = text.replace(' and ',' &and; ')
  text = text.replace('&&','&and;')
  text = text.replace('!','&not;')

  # MISC
  text = text.replace('|','&#124;')
  text = text.replace('Q.E.D.','&#x220E;')
  text = text.replace('SUM ','&sum; ') 
  text = text.replace('PROD ','&prod; ') 

  # QUANTIFIERS
  text = text.replace('E.','&exist;')
  text = text.replace('A.','&forall;')

  # SETS...
  text = text.replace('NELEM','&notin;')
  text = text.replace('ELEM','&isin;')
  text = text.replace('NHAS','&#x220C;')
  text = text.replace('HAS','&#x220B;')
  
  text = text.replace('EMPTY','&empty;')
  text = text.replace('UNION','&cup;')
  text = text.replace('INTER','&cap;')
  text = text.replace('SUBS=','&sube;')
  text = text.replace('SUPS=','&supe;')
  text = text.replace('SUBS','&sub;')
  text = text.replace('SUPS','&sup;')

  # IMPLIES and EQUIV
  text = text.replace('=&gt;','&rArr;')
  text = text.replace('!=','&#x2262;')
  text = text.replace('=','&equiv;')
  text = text.replace('&equiv;&equiv;','=')
  text = text.replace('!=','&neq;')

  return text

@<Register...@>=
def init_processor_module(processor):
  processor.register("math",math_text,False)
  
@+
@signature

@article-end

