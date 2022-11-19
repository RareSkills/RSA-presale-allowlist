import math
import random
import Crypto.Util.number
from Crypto.Hash import keccak

# amount of bits random primes generated will have
bits=1024


p = Crypto.Util.number.getPrime(bits, randfunc=Crypto.Random.get_random_bytes)
q = Crypto.Util.number.getPrime(bits, randfunc=Crypto.Random.get_random_bytes)
print('p: {}'.format(p))
print('q: {}'.format(q))

"""
p = 162000876594795597299736998001679487049057496798720601339662692672237514980928850230680638253758148790892979149412352683873598801002541898305005494241468150282789666050369058317630579730422909061884749314764680041972966994998364831361656364941832746341857573215194601515572114046142094101603891585411758312973
q = 105037078970721664052587554882401740522045237815528584789863171878010674009565781466562144073774457198472108418761396609824138842554734072093136501383500744791836516576978898949211563437859729871121702438831384866852676609614813495363591554607398233420396145880432874902181124751411998956844268008370838796077
"""

####
t = (p - 1) * (q- 1) # this is magic math, don't try to understand it yet or you will get nerdsniped

# n 
n = p * q

# compute e
candidates = []
for i in range(5, min(30000, t)):
	if math.gcd(i, t) == 1:
		candidates.append(i)

e = random.choice(candidates)
# e can be hardcoded to 3 for simplicity, but you need to check the following is true
# e = 20395
assert math.gcd(e, t) == 1

d = pow(e, -1, t) 

# eth address to be signed
message = 0x7361B301B10b371840ca7F6EB2A1aB41Fe1c938B

# sign with private key
sig = pow(message, d, n)

# verify with public key
decodedSignature = pow(sig, e, n)

print('==========================================================================================')
print('================================Values for on chain RSA===================================')
print(f'Small prime, e: {hex(e)}\n')
print(f'Modulus,     n: {hex(n)}\n')
print(f'Length of n   : {len(str(n))}\n')
print('==========================================================================================\n')

print('==========================================================================================')
print('================================Signature Gen and Decoding===================================')
print(f'message: {hex(message)}\n')
print(f'signature: {hex(sig)}\n')
print(f'decoded signature: {hex(decodedSignature)}\n')
print('==========================================================================================\n')

print('==========================================================================================')
print('================================Private key (off-chain)===================================')
print(f'private key: {hex(d)}\n')
print('==========================================================================================')
