from padHexToValue import padTo
from displayBits import getBits
from roundToEvenInt import roundEven

def output(n, e, d):
	# convert to hex for display and pad to appropriate values
	n, e, d = hex(n), hex(e), hex(d)
	
	# pad to appropriate byte formats for display
	n, e, d = padTo(n, roundEven(len(n) - 2)), padTo(e, 64), padTo(d, roundEven(len(n) - 2))
	
	print('\n==========================================================================================')
	print('================================Values for RSA===================================')
	print(f'Small prime, e: {e}\n') 
	print(f'Modulus,     n: {n}\n') 
	print(f'Modulus bits(approximate): {getBits(int(n, 16))}\n')
	print(f'Modulus bytes length: {(len(n)-2) / 2}\n') 
	print('==========================================================================================\n')

	print('==========================================================================================')
	print('================================Private key (off-chain)===================================')
	print(f'private key: {d}\n')
	print('==========================================================================================')