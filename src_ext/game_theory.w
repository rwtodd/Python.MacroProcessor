@{import rwt_processor.article as rwt@}@rem

@[article-start: "A Game-Theory Module for the FileProcessor"
                 RWT-014
                 2010-10-26 @]

@ This is a simple module for the |FileProcessor| system that contains
helper-functions for talking about game-theory.  At present, it only
contains a function to generate a payoff table.  You can see this module
in use in @{rwt.article_ref(8)@} and @{rwt.article_ref(9)@}, and can
get the code here: <a href="http://www.movethemarkets.com/downloads/rwt/rwt014/game_theory.tgz">game_theory.tgz</a>.

@<file:game_theory.py@>=
import io # for the StringIO class
@<Functions@>

@ The |payoff| function takes a list of players, their options,
and a matrix of payoffs.  It then produces a table that looks like this:<br>
<code>payoff('A',[ 'Heads','Tails'],'B',['Bet','Pass'],[ [1,0],[2,5] ])</code> =>
@{import rwt_processor.command.game_theory as game@}@rem
@{game.payoff('A',[ 'Heads','Tails'],'B',['Bet','Pass'],[ [1,0],[2,5] ])@}

@<Functions@>=
def payoff(play1, options1, play2, options2, payoffs):
  ans = io.StringIO()

  @<Open the table@>

  @< Print the top header @>
  @< Print the first payoff row @>
  if len(options2) > 1:
    @< Print each additional payoff row @>

  @<Close the table@>

  return ans

@ To open the table, we just give |table| and |tbody| tags with
a few attributes set:
@<Open the table@>=
print('<table border="0" cellpadding="3" '
      ' cellspacing="0" class="centered">',
      file=ans)
print('<tbody>',file=ans)

@ While we're at it, we may as well close the table.  
Closing the table just means ending the main tags:
@<Close the table@>=
print('</tbody></table>',file=ans)

@ Printing the table header row is easy enough:
@<Print the top...@>=
# skip the first two columns
print('<tr><td>&nbsp;</td><td>&nbsp;</td>',file=ans) 

# print player name...
print('<th colspan="{0}" style="TEXT-ALIGN:center">'
      '{1}</th></tr>'.format(len(options1),play1),file=ans)
print('<tr><td>&nbsp;</td><td>&nbsp;</td>',file=ans) 

for opt in options1:
  print('<th>{0}</th>'.format(opt),file=ans)
print('</tr>',file=ans)

@ The first payoff row is special because it has a
|rowspan| header defining who player 2 is.  All other
payoff rows don't have that.
@<Print the first payoff...@>=
print('<tr><th rowspan="{0}">{1}</th>'.
      format(len(options2),play2),file=ans) 
print('<th>{0}</th>'.format(options2[0]),file=ans)

for i in range(len(options1)):
  print('<td style="TEXT-ALIGN:center">{0}</td>'.
           format(payoffs[0][i]),
        file=ans)

print('</tr>',file=ans)

@ The rest of the payoff rows are very similar to the first, as mentioned above.
@<Print each additional payoff row @>=
for i in range(1,len(options2)):
  print('<tr><th>{0}</th>'.format(options2[i]),file=ans)

  for j in range(len(options1)):
    print('<td style="TEXT-ALIGN:center">{0}</td>'.
             format(payoffs[i][j]),
          file=ans)

  print('</tr>',file=ans)


@+
@signature
@article-end

