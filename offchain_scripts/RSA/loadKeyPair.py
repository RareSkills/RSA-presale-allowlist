def load():
    try:
        nFile = open("./crypto/n.txt", "r")
        n = int(nFile.read())

        eFile = open("./crypto/e.txt", "r")
        e = int(eFile.read())

        dFile = open("./crypto/d.txt", "r")
        d = int(dFile.read())
    except:
        raise Exception("You did not generate any keypairs yet!")

    return(n, e, d)