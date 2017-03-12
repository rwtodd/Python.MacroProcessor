def run(processor,args):
   if len(args)>1:
      raise Exception("Too many arguments to INC: "+str(args))
   return open(args[0],'r')
def init_processor_module(processor):
  processor.register("inc",run,True)
