# "Textual WASM" preprocessor
#
# Syntax:
# ;;: if VAR=VAL
# ;;: else
# ;;: elseif VAR=VAL
# ;;: end
# ;;: insert VAR
# Additionally all instances of the string 000 (or string specified as --delete) will be deleted
# Additionally VAR may be <VAR> to load var as filename
# Additionally VAR may be <VAR|len> for len of var file
# Addiitonally VAR may be <VAR|bin> for escaped binary string of var file
#
# Command line syntax:
# python3 prep.py FILEIN -o FILEOUT [ASSIGNS..]
# Command line assign syntax:
# A=B -- set var A to B
# A=<B> -- set var A to contents of file B

import codecs
import optparse
import re

help  = "%prog [FILEPATH] [ASSIGNS..]\n"
help += "\n"
help += "Accepted arguments:\n"
#help += "-e                 # Attempt to run\n"
help += "-o [path.wast]     # Textual Wasm output\n"
#help += "--bin [path.wasm]  # Wasm bytecode output\n"
help += "--delete [path]    # Delete this string (default 000)\n"

parser = optparse.OptionParser(usage=help)
for a in ["e"]: # Single letter args, flags
    parser.add_option("-"+a, action="store_true")
for a in ["o", "-bin", "-delete"]: # Long args with arguments
    parser.add_option("-"+a, action="append")

(options, cmds) = parser.parse_args()
def flag(a):
    x = getattr(options, a)
    if x:
        return x
    return []

if len(cmds) < 1:
	parser.error("Input file argument required")
hads = [bool(flag("o")), bool(flag("bin")), bool(flag("delete"))]

inpath = cmds[0]
outpath = (flag("o") or ["tmp/a.wast"])[0]
binpath = (flag("bin") or ["tmp/a.wasm"])[0]
delete = (flag("delete") or ["000"])[0]
assigns = cmds[1:]
assignd = {}

temps = [outpath, binpath, delete]
for idx, flag in enumerate(["-o", "--bin", "--delete"]):
	if not hads[idx]:
		print("\t%s not found, using: %s" % (flag, temps[idx]))
temps = None

for assign in assigns:
	(key, eq, value) = assign.partition("=")
	if not eq:
		parser.error("Stray string among assignments: " + key)
	if value:
		assignd[key.lower()] = value

# Take a path to a UTF-8 or UTF-16 file. Return an object to be used with utflines()
def utfOpen(path):
    with open(path, 'rb') as f:
        start = f.read(2) # Check first bytes for BOM
        utf16 = start.startswith(codecs.BOM_UTF16_BE) or start.startswith(codecs.BOM_UTF16_LE)
    return codecs.open(path, 'r', 'utf-16' if utf16 else 'utf-8-sig')

# Interpret a ;;: line
commandp = re.compile(r'^\s*;;:\s*(\S+)(?:\s+(\S.*))?', re.S) # Capture command + rest-as-arg
bracketp = re.compile(r'^<(.+)>$')

eatstack = [] # Each entry can be False (not eating), True (eating) or "super" (eat all clauses)

def avimpl(key, value):
	match = bracketp.match(value)
	if match: # File load
		inner = match.group(1)
		if inner:
			if bracketp.match(inner):
				return inner # Undocumented features: <<>> is <>
			(inner, pipe, mod) = inner.partition("|")
			with open(inner, "rb") as innerf:
				innerstr = innerf.read()
			if pipe: # They gave a | directive
				if mod == "len":
					return len(innerstr)
				if mod == "bin": # TODO FORMAT
					return "".join(("\\"+x.hex()) for x in innerstr)
				print("WARNING: FOR KEY %s UNKNOWN PIPE DIRECTIVE %s" % (key, mod))
				return "" # Yeah just return it
			return innerstr.decode() # Convert to string
		else:
			print("WARNING: FOR KEY %s EMPTY FILENAME %s" % (key, inner))
			return ""
	else: # Raw string
		return s

def avalue(key):
	if bracketp.match(key):
		return avimpl("[anonymous]", key) # Undocumented features: key can be a <file>
	if key in assignd:
		return avimpl(key, assignd[key])
	print("WARNING: UNKNOWN KEY %s" % key)

with utfOpen(inpath) as inf:
	with open(outpath, "w") as outf:
	    for line in inf.readlines():
	    	eating = len(eatstack) > 0 and eatstack[-1]
	    	match = commandp.match(line)
	    	if match:
	    		cmd = match.group(1)
	    		arg = match.group(2)
	    		iselseif = cmd == "elseif"
	    		if cmd == "insert":
	    			if not eating:
	    				outf.write(avalue(arg))
	    				outf.write("\n")
	    		elif cmd == "if" or iselseif:
	    			if ifelseif and not eating:
	    				eatstack[-1] = "super"
	    			elif not (iselseif and eating == "super"): # in not case, leave "super""
	    				if iselseif:
	    					eatstack.pop()
		    			(key, eq, test) = arg.partition("=")
		    			value = avalue(key)
		    			if not key or not eq:
		    				cond = value
		    			else:
		    				cond = value == test
		    			eatstack.push(not cond)
	    		elif cmd == "else":
	    			if eating is True:
	    				eatstack[-1] = False
	    		elif cmd == "end":
	    			eatstack.pop()
	    		else:
	    			print("WARNING: UNRECOGNIZED COMMAND %s" % cmd)
	    	elif not eating:
	    		if delete:
	    			line = line.replace(delete, "")
	    		outf.write(line)
