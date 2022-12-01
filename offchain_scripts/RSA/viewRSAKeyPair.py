from loadKeyPair import load
from RSAOutput import output

def viewKeys():
    # load key values
    n, e, d = load()

    # convert to hex for display
    n, e, d = hex(n), hex(e), hex(d)

    # display RSA key data
    output(n, e, d)