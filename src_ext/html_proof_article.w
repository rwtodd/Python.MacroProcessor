@[import rwt_processor.article @]
@[import rwt_processor.command.math_text @]

@{@rem  *********** definition for axioms...
class math_defs:
  def __init__(self,type):
    self.__type = type
    self.__count = 0
  def next(self,processor,txt):
    self.__count = self.__count + 1
    return ('<dl><dt>{0} {1}:</dt><dd>{2}</dd></dl>'.
               format(self.__type,self.__count,txt) )

axdefs = math_defs("Axiom")
thmdefs = math_defs("Theorem")
defdefs = math_defs("Definition")

processor.register("axiom",axdefs.next,False)
processor.register("definition",defdefs.next,False)
processor.register("theorem",thmdefs.next,False)
@}

@{@rem  *********** definition for axioms...
def proof_text(processor, txt):
   import io
   ans = io.StringIO()
   print('<table><tbody>',file=ans)

   for line in [ i for i in txt.splitlines() if i != '' ]:
     if line[0]=='#':
        ln = line.strip()
        if len(ln)>1:
           print('<tr><td colspan="2">',line[1:],'</td></tr>',file=ans)
     elif line[0].isspace():
        print('<tr><td>&nbsp;</td><td>@@{math:',
               line.strip(),'@@}</td></tr>',file=ans)
     else:
        spl = line.find(' ') 
        if spl < 0:
          print('<tr><td>@@{math:',line,
                '@@}</td><td>&nbsp;</td></tr>',file=ans)
        else:
          print('<tr><td>@@{math:',line[:spl],'@@}</td><td>&nbsp;&nbsp;&nbsp;&#9001;&nbsp;@@{math:',
                line[spl+1:].strip(),'@@}&nbsp;&#9002;</td></tr>',file=ans)

   print('</tbody></table>',file=ans) 
   return ans

processor.register("proof",proof_text,False)
@}

@[article-start: "Semi-formal Musings on Indicators"
                 RWT-017
                 2010-11-04 @]

<h2>Preliminaries</h2>

<p>Let's lay some ground-work for the discussion to follow.  I call this article "semi-formal" 
because we are going to simplify our premise way down.  First off, I'll
restrict my attention to long-side profit opportunities, so that I don't have
to continually say "X for long, and of course (&not;X for short)."   Also, I'll
restrict myself to one scale of action, and let the other scales enjoy their equivalence
through the scale-agnostic quality of market action.

@{axiom: The market action, M, exists. @}

<p>Hopefully that's not controversial!  In other words, the market action is
our universe of discourse.  Logically, it is our weakest argument, evaluating
to <em>true</em>. 

@{axiom: Let L be the portion of market action when there are profitable long opportunities at some scale. @}

<p>So immediately we see that, for some scale (a 30-minute scale, for
instance), @{math: L SUBS= M @} and that @{math: L UNION ~L == M @}.  In other
words, it's either a good time to be long, or it's not, and these two states
partition all of the market action.

@{axiom: An <em>indicator</em> is a set @{math: I SUBS= M @}.  
The set is interpreted as times when a bullish condition is indicated. @}

<p>Equivalently, you could look at an indicator as a predicate on the market
that is <em>true</em> when it thinks you should go long.  For instance, an
example indicator might be "the 20-ema is rising."  This restricts indicators
to yes/no decision-makers, but for most studies this is fine.  When formulating
a trading strategy, decisions all boil down to go/no-go choices in the end...
you can't trade a slow stochastic value, but you can trade "the slow stochastic
hooks up over 20."  These are the decision points our "indicators" describe.

<p> New indicators can be derived from existing ones in several ways.  For example:

<ul>
<li>I = ~J ; Do the opposite of what the indicator says
<li>I = J &cap; K ; Go long if two indicators agree
<li>I = J &cup; K ; Go long if either indicator says to
<li>I = J - K ; Go long when J says long but K doesn't
</ul>

<p> Since I've defined M to be the universe for this theory, and an indicator is
simply a subset of M, it's trivial to see that all of these derived 
calculations result in new indicators. 

<h2>Rating Indicators</h2>
<p>Any given indicator can be broken into two independent parts, like so:
@{theorem: @[math: I == (I INTER L) UNION (I INTER ~L)  @] @}

<p>This is pretty obvious but I'll prove it anyway.  Proof: 

@[proof: #
   (I INTER L) UNION (I INTER ~L)
==  distribute INTER over UNION
   I INTER (L UNION ~L)
==  excluded middle 
   I INTER M 
==  Identity of INTER 
   I   Q.E.D.
@]

<p>You can think of @[math:(I INTER L)@] as "the profitable part" and @[math:(I
INTER ~L)@] as "the unprofitable part" of an indicator's choices.  Probably the
biggest simplifying assumption I'll make is that, for a given time-frame, all
profitable and unprofitable opportunities are the same size.  This makes many
aspects of the system a lot easier to reason about, and for a single timeframe
it probably isn't as terrible an assumption as it sounds.

<p>I can formalize this line of thought with a scoring function for indicators:

@{axiom: @{math: profit.I == (SUM x | x ELEM (I INTER L) : 1) - (SUM x | x ELEM (I INTER ~L) : 1) @} @}

<p>If we use the typical set cardinality notation, @[math: #S = (SUM x | x ELEM S : 1) @], then 'profit.I' reduces
to @{math: #(I INTER L) - #(I INTER ~L)@}. I'll mostly use this form for brevity.

<p>From here I can make a couple immediate observations:

@{theorem: L is the ideal indicator. @[math: (A. x:Indicator |: profit.x <= profit.L) @] @}

@{proof: # 
   profit.x
== definition of profit.x 
  #(x INTER L) - #(x INTER ~L)
<=  arithmetic (b - a) <= b ; b : &#x2124;, a : &#x2115;
  #(x INTER L)
<=   #(A INTER B) <= #(A)
  #L
==  (L INTER L) == L  ;   (L INTER ~L) == EMPTY 
  #(L INTER L) - #(L INTER ~L)
== definition of profit.L  
  profit.L   Q.E.D.
@}

@{theorem: ~L is the worst indicator. @[math: (A. x:Indicator |: profit.x >= profit.~L) @] @}

<p>The proof is nearly identical to the previous one, so I'll omit it.

<h2>Trading System Indicators</h2>

<p> One of the primary reasons to have indicators is to build trading systems out of them.
That is, one attempts to find an indicator, most likely derived from some combination of simpler
indicators, that profitably finds long opportunities.

<p> As I've already shown, the best answer you can arrive at is L.  Unfortunately, no one knows how
to construct L.  I can reason about indicators in relation to it, though.

<p> For a trading system 'S,' how far back can we reasonably step back from S = L?  Pretty far, actually.  
You don't have to cover much of L at all, as long as you cover a lot less of ~L.  In English:
to succeed, you don't have to catch too many profitable trades, provided you catch even fewer 
losses.  

<p><strong>Method 1.</strong> So, one plan of attack would be a cycle of refinement against a promising indicator as follows:

<ol>

<li> Find an indicator, S, with a decent-sized portion @[math:S INTER L@]

<li> Now, focus on the portion of S that is @[math:S INTER ~L@] 

<li> Find an indicator, F, that matches areas of @[math:S INTER ~L@], without
matching very much of @[math:S INTER L@].  In other words, you want @[math: (F
INTER S INTER ~L)@] to be a much larger set than @[math:(F INTER S INTER L)@].

<li> Generate a new, more-profitable indicator S' = S - F

<li> Go to step 2 and repeat with S' until satisfied with the system

</ol>

<p> Here's a short proof that S' is a better system than S:

@{theorem: @[math: (A. S,F |: (#(F INTER S INTER ~L) > #(F INTER S INTER L)) => (profit.(S-F) > profit.S) @]) @}  

<p> For this proof, I'll assume the antecedent, and prove the consequent from left to right:

@{proof:  #
  profit.(S-F)
==  definition of profit
  #((S-F) INTER L) - #((S-F) INTER ~L)
==  def of set minus
  #(S INTER ~F INTER L) - #(S INTER ~F INTER ~L)
==  symmetry of INTER
  #(S INTER L INTER ~F) - #(S INTER ~L INTER ~F)
==  def of set minus
  #((S INTER L) - F) - #((S INTER ~L) - F)
==    #(X-Y) == #(X) - #(X INTER Y)
  (#(S INTER L) - #(S INTER L INTER F)) - (#(S INTER ~L) - #(S INTER ~L INTER F))
>   x < y => ((a-x) - (b-y)) > (a - b) for a,x,b,y:&#x2115;; #(S INTER F INTER L) < #(S INTER F INTER ~L)
  #(S INTER L) - #(S INTER ~L)
== definition of profit
  profit.S  Q.E.D.
@}

<p> A pivotal step in the above proof states:
@{theorem: @[math: #(X - Y) == #X - #(X INTER Y) @] @}

<p> Intuitively, that seems true, but I might as well prove it.  I'll transform the right side into the left
via equivalences:

@{proof: #
  #X - #(X INTER Y)
== Identitiy for intersection, excluded middle
  #(X INTER (Y UNION ~Y)) - #(X INTER Y)
==  distribute INTER over UNION
  #((X INTER Y) UNION (X INTER ~Y)) - #(X INTER Y)
== range split
  #(X INTER Y) + #(X INTER ~Y) - #(X INTER Y)
== arithmetic 
  #(X INTER ~Y)
== definition of set minus
  #(X - Y)  Q.E.D.
@}

<p>In the above algorithm I name the secondary indicator 'F' for 'filter,' because
that's what it does.  It filters out bad trades that indicator 'S' would make.  It 
does that by targeting subsets of 'S' that lead to lost money.  This 
is not to be confused with what many traders call 'filters,' though!  

<p><strong>Method 2.</strong> When a typical trader looks for filters, he goes after the exact opposite of the
filters just described. He'll say something like "I will only trade in the direction
of the 50-EMA." That style of filter must have:

<ul>
<li> @[math:(F INTER S INTER L)@] as close as possible to @[math:(S INTER L) @]
<li> @[math:(F INTER S INTER ~L)@] as close to &empty; as possible.
<li> These approximations must be at least close enough that: @[math:#(F INTER S INTER ~L) < #(F INTER S INTER L)@]
</ul>

<p> In other words, the filter must win in
all the areas that 'S' wins, but lose in very different areas than 'S' lost in. If
it does those two things, then @[math:S' == S INTER F@] will be a much better indicator
than 'S' ever was. Since @[math:X-Y == X INTER ~Y@], you can see that this style of filter is just
the inverted version of the first filter, so in some sense they take equal effort to find.  
The mindset of the system designer is different, though!  Isolating specific failings of an indicator feels 
very different than trying to match the indicator except where it fails. 
The latter feels like a taller order, especially when people throw blunt instruments like long
averages at the problem!  No wonder traders have so many difficulties! 

@{theorem: @[math: (A. S,F |:  #(F INTER S INTER ~L) < (F INTER S INTER L) => profit.(S INTER F) > profit.S @]) @}  

<p> The proof of this theorem is very similar to the proof for the first filter, and is omitted.

<p><strong>Method 3.</strong> Our formulation suggests a third way to build up a system.
In short, if you can find an indicator, A, with:

<ul>
<li> @[math:(A UNION S) INTER L as large as possible @]
<li> @[math:(A UNION S) INTER ~L as similar as possible to (S INTER ~L) @]
<li> These approximations must be a least close enough that: @[math:profit.A > profit.(A INTER S)@]
</ul>

<p> In English: Indicator 'A' needs to lose in same places 'S' does,
while winning in different places than 'S' does, as much as possible.  
If so, then @[math:S' == S UNION A@] will be a better indicator than 'S' was.  
I call the second indicator 'A' for 'add-in,' since via union you "add A into S."  

@{theorem: @[math: (A. S,A |:  (profit.A > profit.(A INTER S)) => profit.(S UNION A) > profit.S) @] @}

<p>We'll prove this one as we did before, assuming the antecedent and proving the consequent from left to right:

@{proof: #
  profit.(A UNION S)
== definition of profit
  #((A UNION S) INTER L) - #((A UNION S) INTER ~L)
==  distribute INTER over UNION
  #((A INTER L) UNION (S INTER L)) - #((A INTER ~L) UNION (S INTER ~L))
==  range split, non-independent ranges
  #(A INTER L) + #(S INTER L) - #(A INTER S INTER L) - #(A INTER ~L) - #(S INTER ~L) + #(A INTER S INTER ~L)
== definition of profit
  profit.S + profit.A - profit.(A INTER S)
>  assumption profit.A > profit.(A INTER S)
  profit.S Q.E.D.
@}

<p> All three of these approaches have their place, but the first is the most surgical kind
of strike, and probably not employed as often as it deserves.
 
<h2>Sanity-Check Indicators</h2>

<p> I should point out that indicators are often used as
a support system for discretionary trading.  The idea here is for an indicator
to act as a last double-check when the human decides he or she wants to go
long.  Most people don't seem to realize that a discretionary indicator should
be built up differently than a system indicator, so I'd like to mention that here. 

<p> For sanity checks, there's nothing worse than a human wanting to take a
profitable long and the indicator telling them to stay out.  So, coverage of
the set L is very important for sanity-checks.  Contrast that to system
indicators, where we discussed earlier that total profit is more important than
how much of L we capture.

<p>So, rather than profit, we might want a measure encouraging L-coverage:

@{axiom: @[math: lcov.I == 0 - #(L - I) - #(I INTER ~L) @] @}

<p> We can see L is the indicator with the best L coverage:

@{theorem: @[math:(A. x:Indicator |: lcov.x <= lcov.L) @] @}

<p> Proof:
@{proof: #
  lcov.x
== definition of lcov
  0 - #(L - x) - #(x INTER ~L)
<=  #A is a natural number
  0 
== arithmetic
  0 - 0 - 0
== #(L-L) == 0 and #(L INTER ~L) == 0
  0 - #(L - L) - #(L INTER ~L)
== definition of lcov
  lcov.L  Q.E.D.
@}

<p> In English, what you want in a sanity check indicator is:
<ul>
<li> Suggests long during most profitable long opportunitites
<li> Suggests long during the fewest non-profitable opportunities as possible 
</ul>

<p> You can see from the above that far too many traders get this wrong.
They'll use, say, the rising 50-EMA to double-check their long entries. This
keeps them out of <em>lots</em> of profitable longs that occur when the 50-EMA
is falling.  The L-coverage is very bad, making the 50-EMA a very poor indicator for
sanity checks.

<p> Meanwhile, an indicator like the paintbar below:

<img class="centered" src="trendbars.PNG">

<p> ... is a very good sanity check indicator.  You can see that, during the
majority of the times when going long would work out, it is green.  There are
also some, but not too terribly many, green bars when going long would be a bad
idea.  The lcov score on an indicator like this would be very good compared to
the average indicator, even though this indicator would make a very poor
trading system (putting on a long position on every green bar would be a bad
way to go!).  Hopefully this clarifies the difference between the two.

<p> Theorems of indicator refinement for the sanity-check case can be developed much
like the ones I presented above for systems.  The main difference is to use lcov as the
measure of quality rather than profit.  I'll leave the development of those as an exercise for
 the reader.

<h2>Summary</h2>

<p>The main reasons I wrote this article were to give people a taste of what
formal reasoning looks like, and to outline the main ways I think about
indicator combinations and indicator goals.  A little formality goes a long
way toward eliminating careless mistakes.  In fact, while writing this very article I
caught myself twice trying to say something that wasn't quite true.  The only
reason I caught myself was because I couldn't find a proof of what I had said!  

@signature

@article-end

