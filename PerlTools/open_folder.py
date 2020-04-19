import sys
import util
import subprocess

if (len(sys.argv) < 1):
    print "please give a path to open explorer"
    sys.exit(0)
path = sys.argv[1]
platform = util.getPlatformName()
if (platform == "win32"):
    subprocess.call(["open", path])
else:
    subprocess.call(["start", path])
