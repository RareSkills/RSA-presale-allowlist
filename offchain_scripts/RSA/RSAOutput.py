from padHex import pad
from displayBits import getBits
from padHex import pad

def output(n, e, d):
	print('\n==========================================================================================')
	print('================================Values for RSA===================================')
	print(f'Small prime, e: {pad(e, 64)}\n') # pad to 32 bytes
	print(f'Modulus,     n: {n}\n') 
	print(f'Modulus bits(approximate): {getBits(int(n, 16))}\n')
	print(f'Modulus bytes length in EVM: {(len(n)-2) / 2}\n') # length of bytes stored in the evm
	print('==========================================================================================\n')

	print('==========================================================================================')
	print('================================Private key (off-chain)===================================')
	print(f'private key: {d}\n')
	print('==========================================================================================')