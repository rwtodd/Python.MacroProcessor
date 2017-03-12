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
