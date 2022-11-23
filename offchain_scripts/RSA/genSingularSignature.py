from loadKeyPair import load
import validAddress

def generateSig(address):
    # load key values
    n, e, d = load()

    # check if valid eth address was passed in
    # else throw exception
    validAddress.checkValidity(address) 

    # eth address to be signed
    # convert to base 10 for calculation purposes
    message = int(address, 16)

    # sign with private key
    # message ^ d % n 
    sig = pow(message, d, n)

    # verify with public key
    # signature ^ e % n 
    decodedSignature = pow(sig, e, n)

    print('==========================================================================================')
    print('================================Signature Gen and Decoding===================================')
    print(f'message: {address}\n')
    print(f'signature: {hex(sig)}\n')
    print(f'decoded signature: {hex(decodedSignature)}\n')
    print('==========================================================================================\n')