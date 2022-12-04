from loadKeyPair import load
from padHexToValue import padTo
from validAddress import checkValidity
from roundToEvenInt import roundEven

def generateSig(address):
    # load key values
    n, e, d = load()

    # get modulus length hex data
    # prune '0x'
    keyHexLength = roundEven(len(hex(n))-2)

    # check if valid eth address was passed in
    # else throw exception
    checkValidity(address) 

    # eth address to be signed
    # convert to base 10 for calculation purposes
    message = int(address, 16)

    # convert string hex to 

    # sign with private key
    # message ^ d % n 
    sig = pow(message, d, n)

    # verify with public key
    # signature ^ e % n 
    decodedSignature = pow(sig, e, n)

    print('==========================================================================================')
    print('================================Signature Gen and Decoding===================================')
    print(f'message: {address}\n')
    print(f'signature: {padTo(hex(sig), keyHexLength)}\n') # pad to correct hex length
    print(f'decoded signature: {hex(decodedSignature)}\n')
    print('==========================================================================================\n')