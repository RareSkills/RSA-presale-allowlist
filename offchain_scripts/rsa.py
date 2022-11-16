import math
import random

p = 196793513198967711746475883934064505068451893214629404257561516295520529266971114666669126978337558469273926399323788163543303586195329307435530347170940318594323540717425428051639823515815345486512051246523301316930787173267145653470793298359163230031430422896583610400744727704483824874035451177299

q = 277777212976096740932177656338439976209684260285182261627499250065513770747703349171779989031758565058576493506705163468053649729349668479511572968674997482794142185644731037888218909183633421531030075911272150774246288019861173421808745899470083153161358599945036907566193014721730864915154228743329
t = (p - 1) * (q- 1) # this is magic math, don't try to understand it yet or you will get nerdsniped

# n needs to be less than 1024 bits in size or it won't fit in the smart contract. But it shouldn't be too much less or it won't be safe
n = p * q

# compute e

candidates = []
for i in range(5, min(30000, t)):
	if math.gcd(i, t) == 1:
		candidates.append(i)

print(len(candidates))
e = random.choice(candidates)

# e can be hardcoded to 3 for simplicity, but you need to check the following is true
assert math.gcd(e, t) == 1

d = pow(e, -1, t) # You've been warned. This is magic math, don't try to understand it yet or you will get nerdsniped. Only study this after the project is done.
print(d)

message = 590

sig = pow(message, d, n)

print(pow(sig, e, n))
print(message)