#count the duplicate line 
fileName = sys.argv[0]
lines = open(fileName).readlines()

lastLine = ""
lastLineCount = 0
for line in lines:
    if (line.strip() != lastLine.strip()):
        print "-%s %d" % (line.strip(), lastLineCount)
        lastLineCount = 0
    else:
        lastLineCount = lastLineCount + 1
    lastLine = line.strip()
print "-%s %d" % (lastLine.strip(), lastLineCount)
