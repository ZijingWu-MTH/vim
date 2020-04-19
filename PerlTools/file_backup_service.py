import os;
import sys;
import shutil;
import glob;

def GetBackupFiles(dirPath, fileName):
    tempList = []
    metaFile = os.path.join(dirPath, fileName + ".bk")
    if os.path.isfile(metaFile):
        tempList = file(metaFile).readlines()
    bkFileList = []
    for infile in tempList:
        infile = infile.strip()
        if (os.path.isfile(infile)):
            bkFileList = bkFileList + [infile]
    return bkFileList

def CleanUp(dirPath, fileName, maxCount):
    bkFiles = GetBackupFiles(dirPath, fileName)
    index = 0
    while (index < len(bkFiles) - maxCount):
        if (os.path.isfile(os.path.join(dirPath, bkFiles[index]))):
            os.unlink(os.path.join(dirPath, bkFiles[index]))
        index = index + 1
    if (len(bkFiles) > maxCount):
        WriteBackupFiles(dirPath, fileName, bkFiles[len(bkFiles) - maxCount : len(bkFiles)])
    if (maxCount == 0):
        os.unlink(os.path.join(dirPath, fileName + ".bk")) 

def WriteBackupFiles(dirPath, fileName, bkFiles):
    metaFile = os.path.join(dirPath, fileName + ".bk")
    fo = open(metaFile, "w")
    for line in bkFiles:
        print line
        fo.write(line + os.linesep)
    fo.close()

def AddNewBackUpFile(dirPath, fileName, newBackUpFile):
    bkFiles = GetBackupFiles(dirPath, fileName)
    bkFiles = bkFiles + [newBackUpFile]
    WriteBackupFiles(dirPath, fileName, bkFiles)

def GetNextBackupFileName(dirPath, fileName):
    index = 0
    while True:
        if (not os.path.exists(os.path.join(dirPath, fileName + ".bak%s" % index))):
            return fileName + ".bak%s" % index
        index = index + 1
    return None

if __name__ == '__main__':
    filePath = sys.argv[1]
    dirPath = os.path.dirname(filePath)
    fileName = os.path.basename(filePath)
    print fileName

    bakFiles = GetBackupFiles(dirPath, fileName)
    newBackFileName = GetNextBackupFileName(dirPath, fileName)
    if (sys.argv[2] == "backup"):
        print filePath
        print os.path.join(dirPath, newBackFileName)
        shutil.copy(filePath,  os.path.join(dirPath, newBackFileName))
        AddNewBackUpFile(dirPath, fileName, newBackFileName)
        CleanUp(dirPath, fileName, 3)
    elif (sys.argv[2] == "cleanup"):
        CleanUp(dirPath, fileName, 0)
    elif ((sys.argv[2] == "restore") and (len(bakFiles) > 0)):
        lastFile = bakFiles[-1]
        shutil.copy(os.path.join(dirPath, lastFile), filePath)

