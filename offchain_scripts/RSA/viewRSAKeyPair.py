from loadKeyPair import load
from RSAOutput import output

def viewKeys():
    # load key values
    n, e, d = load()

    # display RSA key data
    output(n, e, d)