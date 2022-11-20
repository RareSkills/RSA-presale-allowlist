import math
import random
import Crypto.Util.number

# amount of bits random primes generated will have
# must be multiple of 32 for this program
bits=1024

while True:
    p = Crypto.Util.number.getPrime(bits, randfunc=Crypto.Random.get_random_bytes)
    q = Crypto.Util.number.getPrime(bits, randfunc=Crypto.Random.get_random_bytes)
    #print('p: {}'.format(p))
    #print('q: {}'.format(q))

    """
    p = 174888828555925305075390329546013143919324268647735221221937813264127029256780097712250494933358872513494593532908644633146504541804334196341648036380445816347893239737947399342322517460815718649105318199301061568955594214058922168087745911441241786540941293082276552204888319489033375221896758138935340412251
    q = 170526776011501505943239164018296461218869706665296733474047279752986145195732565634823236537838902607152165668195153112273308928601181542403149851811695702004532693514928558557948633007304483833339623707762804960189267299150391589443817562159519078803855179891439953387134969310357526815902694071346231441213
    """

    ####
    t = (p - 1) * (q- 1) # this is magic math, don't try to understand it yet or you will get nerdsniped

    # n 
    n = p * q

    """
    # compute e (using a small prime 256 bits and less)
    candidates = []
    for i in range(5, min(30000, t)):
        if math.gcd(i, t) == 1:
            candidates.append(i)

    #e = random.choice(candidates)
    """

    # e can be hardcoded to 3 for simplicity, but you need to check the following is true
    e = 3
    if math.gcd(e, t) == 1:
        # if condition is false calculate again
        # need a valid p and q where exponent 3 is valid for the encryption parameters
        break

d = pow(e, -1, t) 


# eth address to be signed
#message = 0x000000000000000000007361B301B10b371840ca7F6EB2A1aB41Fe1c938B
#message = 0x000000000000000000005B38Da6a701c568545dCfcB03FcB875f56beddC4
message = int(input('\nEnter ETH address: '), 16)

# sign with private key
sig = pow(message, d, n)

# verify with public key
decodedSignature = pow(sig, e, n)

print('==========================================================================================')
print('================================Values for RSA===================================')
print(f'p: {q}\n')
print(f'q: {p}\n')
print(f'Small prime, e: {hex(e)}\n')
print(f'Modulus,     n: {hex(n)}\n')
print(f'Length of n   : {len(str(n))}\n')
print('==========================================================================================\n')

print('==========================================================================================')
print('================================Signature Gen and Decoding===================================')
print(f'message: {message}\n')
print(f'signature: {hex(sig)}\n')
print(f'decoded signature: {hex(decodedSignature)}\n')
print('==========================================================================================\n')

print('==========================================================================================')
print('================================Private key (off-chain)===================================')
print(f'private key: {hex(d)}\n')
print('==========================================================================================')
