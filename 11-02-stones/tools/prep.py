# "Textual WASM" preprocessor (v 0.1)
#
# If this syntax seems weird, it is based entirely around preventing the
# Sublime Text wast syntax highlighter from freaking out on me.
#
# Syntax:
# ;;: if VAR=VAL
# ;;: else
# ;;: elseif VAR=VAL
# ;;: end
# ;;: insert VAR
# ;;: set VAR=VAL
# ;;: setv VAR=VAR
# ;;: error MESSAGE, PUNCTUATION AND SPACES OKAY
# Additionally all instances of the string 000 (or string specified as --delete) will be deleted
# Additionally VAR may be <VAR> to load var as filename
# Additionally VAR may be <VAR>|len for len of var file
# Additionally VAR may be <VAR>|i32 (or |i64) for var file translated from ascii to binary packed integers
# Addiitonally VAR may be <VAR>|bin for escaped binary string of var file
# Addiitonally VAR may be VAR|+:N for some integer N to add N to VAR (assuming var represents an int)
# Addiitonally VAR may be VAR|*:N for some integer N to mul N by VAR (assuming var represents an int)
# Addiitonally VAR may be VAR|/:N for some integer N to div N by VAR (assuming var represents an int)

#
# Command line syntax:
# python3 prep.py FILEIN -o FILEOUT [ASSIGNS..]
# Command line assign syntax:
# A=B -- set var A to B
# A=<B> -- set var A to contents of file B

import codecs
import copy
import optparse
import re
import os
import subprocess
import sys

help  = "%prog [FILEPATH] [ASSIGNS..]\n"
help += "\n"
help += "Accepted arguments:\n"
help += "-e                 # Attempt to run\n"
help += "-o [path.wast]     # Textual Wasm output\n"
help += "--bin [path.wasm]  # Wasm bytecode output\n"
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
            elif mod == "i64":
                s = b''.join([int(i).to_bytes(8, byteorder="little") for i in s.split()])
            else:
                fn = mod.split(":")
                if len(fn) > 1:
                    (plus, mul, div) = (fn[0] == "+", fn[0] == "*", fn[0] == "/")
                    if len(fn) == 2 and (plus or mul or div):
                        try:
                            if plus:
                                s = str(int(s) + int(fn[1]))
                            if mul:
                                s = str(int(s) * int(fn[1]))
                            if div:
                                s = str(int(s) // int(fn[1]))
                        except ValueError:
                            print("WARNING: FOR KEY %s PIPE DIRECTIVE %s%s%s, COULD NOT CONVERT TO INT" % (keytag or s, s, fn[0], fn[1]))
                            return ""
                    else:
                        print("WARNING: FOR KEY %s, FUNCTION-STYLE PIPE DIRECTIVE %s WITH %d ARGS WAS NOT UNDERSTOOD" % (keytag or s, fn[0], len(fn)-1))
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

# Stack for nested if sequences
eatstack = [] # Each entry can be False (not eating), True (eating) or "super" (eat all clauses)
linecount = 0

with utfOpen(inpath) as inf:
    with open(outpath, "w") as outf:
        for line in inf.readlines():
            linecount += 1
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
                issetv = cmd == "setv"
                if cmd == "error":
                    if not eating:
                        print("Error at line %d: %s" % (linecount, arg), file=sys.stderr)
                        sys.exit(1)
                elif cmd == "insert":
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
                    if eating is True or eating is False:
                        eatstack[-1] = not eating
                elif cmd == "end":
                    eatstack.pop()
                elif cmd == "set" or issetv:
                    (key, eq, value) = arg.partition("=")
                    if eq:
                        if issetv:
                            value = parse(value, key, True)
                        assignd[key.lower()] = value
                    else:
                        if issetv:
                            print("WARNING LINE %D: BLANK SETV FOR KEY %s", key)
                        else:
                            del assignd[key.lower()]

                    if verbose:
                        print("\tCMD-SET", assignd)
                else:
                    print("WARNING: UNRECOGNIZED COMMAND %s" % cmd)
                if verbose:
                    print("\tCMD2", eatstack)
            elif not eating:
                if delete:
                    line = line.replace(delete, "")
                outf.write(line)

if flag("o") or flag("e"):
    # Prevent modification of process environment by Popen
    globalEnv = copy.deepcopy( os.environ )
    startp = re.compile(r'^', re.MULTILINE)
    def pretag(tag, str):
        tag = u"\t%s: " % (tag)
        return startp.sub(tag, str)

    def subrun(invoke):
        if verbose:
            print("Exec", invoke)
        try:
            proc = subprocess.Popen(invoke, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=globalEnv)
        except OSError as e:
            print("\nCATASTROPHIC FAILURE: Couldn't find command line tool?:")
            print(e)
            sys.exit(1)

        result = proc.wait()
        outstr, errstr = proc.communicate()

        outstr = codecs.decode( outstr.rstrip(), 'utf-8' )
        errstr = codecs.decode( errstr.rstrip(), 'utf-8' )

        if result: # UNIX code
            print("Run", invoke[0], "failure", result) # TODO: print to stderr somehow
            print(pretag("STDERR:", errstr))
            sys.exit(1)

    subrun(["wat2wasm", outpath, "-o", binpath])

    if flag("e"):
        print("Success\n")
        print("wasmtime", binpath) # TODO: Note doesn't actually run, just print run instructins
