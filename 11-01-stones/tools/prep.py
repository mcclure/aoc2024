# "Textual WASM" preprocessor (v 0.1)
#
# Syntax:
# ;;: if VAR=VAL
# ;;: else
# ;;: elseif VAR=VAL
# ;;: end
# ;;: insert VAR
# Additionally all instances of the string 000 (or string specified as --delete) will be deleted
# Additionally VAR may be <VAR> to load var as filename
# Additionally VAR may be <VAR>|len for len of var file
# Addiitonally VAR may be <VAR>|bin for escaped binary string of var file
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
help += "-v                 # Verbose mode (for debugging)\n"

parser = optparse.OptionParser(usage=help)
for a in ["e", "v"]: # Single letter args, flags
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
verbose = bool(flag("v"))
assigns = cmds[1:]
assignd = {}

temps = [outpath, binpath, delete]
for idx, flagname in enumerate(["-o", "--bin", "--delete"]):
    if not hads[idx]:
        print("\t%s not found, using: %s" % (flagname, temps[idx]))
temps = None

# Interpret expansion syntax
bracketp = re.compile(r'^<(.+)>$')
quotep = re.compile(r'^"(.+)"$')

# This function is used twice: In assigning values to assignd, and again when reading them back out.
def parse(s, keytag, iskey=False, maynull=False):
    # Syntax: | for function (unless ""-wrapped)
    (s, pipe, mods) = s.partition("|") if not quotep.match(s) else (s, None, None)
    if mods:
        mods = mods.split("|")
    if verbose:
        print("P1", s,pipe,mods)
    # Syntax: <> to read file
    isfile = False
    bracket = bracketp.match(s)
    if bracket:
        isfile = True
        s = bracket.group(1)
    if verbose:
        print("P2", s,isfile)
    # Syntax: "" to prevent variable expansion
    quote = quotep.match(s)
    if quote:
        iskey = False
        s = quote.group(1)
    if verbose:
        print("P3", s,iskey)
    # Expand variables
    if iskey:
        slower = s.lower()
        if slower in assignd:
            s = assignd[slower]
        else:
            if not maynull:
                print("WARNING: UNKNOWN KEY %s" % key)
            return ""
    if verbose:
        print("P4", s,isfile)
    # Read files
    if isfile:
        with open(s, "rb") as innerf: # Notice: Raw bytes, NOT UTF-16
            s = innerf.read()
    if pipe: # They gave a | directive
        for mod in mods:
            if mod == "len":
                s = str(len(s))
            elif mod == "bin": # TODO FORMAT
                if type(s) == str:
                    s = s.encode()
                s = '"' + "".join(("\\"+bytes([x]).hex()) for x in s) + '"'
            elif mod == "i32":
                s = b''.join([int(i).to_bytes(4, byteorder="little") for i in s.split()])
            else:
                print("WARNING: FOR KEY %s UNKNOWN PIPE DIRECTIVE %s" % (keytag or s, mod))
                return ""
    if type(s) == bytes:
        s = s.decode()
    if verbose:
        print("P5", keytag, s)
    return s # Convert to string

for assign in assigns:
    (key, eq, value) = assign.partition("=")
    if not eq:
        parser.error("Stray string among assignments: " + key)
    assignd[key.lower()] = parse(value, key)

if flag("v"):
    print("Keys:", assignd)

# Take a path to a UTF-8 or UTF-16 file. Return an object to be used with utflines()
def utfOpen(path):
    with open(path, 'rb') as f:
        start = f.read(2) # Check first bytes for BOM
        utf16 = start.startswith(codecs.BOM_UTF16_BE) or start.startswith(codecs.BOM_UTF16_LE)
    return codecs.open(path, 'r', 'utf-16' if utf16 else 'utf-8-sig')

# Interpret a ;;: line
commandp = re.compile(r'^\s*;;:\s*(\S+)(?:\s+(\S.*))?', re.S) # Capture command + rest-as-arg

eatstack = [] # Each entry can be False (not eating), True (eating) or "super" (eat all clauses)

with utfOpen(inpath) as inf:
    with open(outpath, "w") as outf:
        for line in inf.readlines():
            eating = len(eatstack) > 0 and eatstack[-1]
            match = commandp.match(line)
            if match:
                cmd = match.group(1)
                arg = match.group(2)
                if arg:
                    arg = arg.rstrip()
                if verbose:
                    print("CMD", cmd, arg, eatstack)
                iselseif = cmd == "elseif"
                if cmd == "insert":
                    if not eating:
                        outf.write(parse(arg, None, True))
                        outf.write("\n")
                elif cmd == "if" or iselseif:
                    if iselseif and not eating:
                        eatstack[-1] = "super"
                    elif not (iselseif and eating == "super"): # in not case, leave "super""
                        if iselseif:
                            eatstack.pop()
                        (key, eq, test) = arg.partition("=")
                        value = parse(key, None, True, not eq)
                        if not key or not eq:
                            cond = value
                        else:
                            cond = value == test
                        eatstack.append(not cond)
                elif cmd == "else":
                    if eating is True:
                        eatstack[-1] = False
                elif cmd == "end":
                    eatstack.pop()
                else:
                    print("WARNING: UNRECOGNIZED COMMAND %s" % cmd)
                if verbose:
                    print("\tCMD2", eatstack)
            elif not eating:
                if delete:
                    line = line.replace(delete, "")
                outf.write(line)
