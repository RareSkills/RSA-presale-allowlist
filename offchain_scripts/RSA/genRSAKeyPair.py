import math
import random
import Crypto.Util.number

def generateKeys(genExponent=False):
	# amount of bits random primes generated will have
	# ** DO NOT CHANGE **
	bits=1024

	while True:
		# will keep looping until a p and q is chosen that has a satsifactory exponent value
		
		# 2 random primes
		p = Crypto.Util.number.getPrime(bits, randfunc=Crypto.Random.get_random_bytes)
		q = Crypto.Util.number.getPrime(bits, randfunc=Crypto.Random.get_random_bytes)

		# Euler's totient 
		t = (p - 1) * (q- 1) 

		# n modulus (public key)
		n = p * q

		# if user indicates a random exponent to be used then generate one
		if genExponent:
			# compute e (using a small prime 256 bits and less)
			candidates = []
			for i in range(5, min(30000, t)):
				if math.gcd(i, t) == 1:
					candidates.append(i)

			e = random.choice(candidates)
		
		# else use a hardcoded exponent of 3
		else:
			# e can be hardcoded to 3 for simplicity, but you need to check the following is true
			e = 3

		if math.gcd(e, t) == 1:
			# if condition is false calculate again
			# need a valid p and q where exponent is valid for the encryption parameters
			break

    # calculate private key
	d = pow(e, -1, t)

	# store private and public key pairs in crypto folder
	with open('./crypto/n.txt', 'w') as f:
		f.write(str(n))
		f.close()

	with open('./crypto/e.txt', 'w') as f:
		f.write(str(e))
		f.close()

	with open('./crypto/d.txt', 'w') as f:
		f.write(str(d))
		f.close()

	print('\n==========================================================================================')
	print('================================Values for RSA===================================')
	print(f'p: {p}\n')
	print(f'q: {q}\n')
	print(f'Small prime, e: {"0x" + str(hex(e))[2:].zfill(64)}\n') # pad to 32 bytes
	print(f'Modulus,     n: {hex(n)}\n')
	print('==========================================================================================\n')

	print('==========================================================================================')
	print('================================Private key (off-chain)===================================')
	print(f'private key: {hex(d)}\n')
	print('==========================================================================================')