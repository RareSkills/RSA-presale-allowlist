import math
import random
import Crypto.Util.number
from RSAOutput import output

def generateKeys(bits, genExponent=False):
	if not bits % 4 == 0:
		# allows for generation of modulus in the correct format
		raise Exception("Must specify a key size divisible by 4!")

	# A 1024 bit modulus is the product of two 512 bit primes
	# thus divide by 2 to get the bits needed for each prime
	randPrimeBits = bits//2

	# will keep looping until a p and q is chosen that has a satsifactory exponent value
	while True:
		# 2 random primes of variable bit length
		p = Crypto.Util.number.getPrime(randPrimeBits, randfunc=Crypto.Random.get_random_bytes)
		q = Crypto.Util.number.getPrime(randPrimeBits, randfunc=Crypto.Random.get_random_bytes)

		# Euler's totient 
		t = (p - 1) * (q - 1) 

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
	# values are stored as an integer
	with open('./crypto/n.txt', 'w') as f:
		f.write(str(n))
		f.close()

	with open('./crypto/e.txt', 'w') as f:
		f.write(str(e))
		f.close()

	with open('./crypto/d.txt', 'w') as f:
		f.write(str(d))
		f.close()

	# convert to hex for display
	n, e, d = hex(n), hex(e), hex(d)

	# display RSA key data
	output(n, e, d)