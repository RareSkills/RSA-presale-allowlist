def getBits(number):
    # returns the length of binary bits
    # subtract two as python prefaces binary with '0b'
    # i.e bin(2) -> '0b10'
    return len(bin(number)) - 2