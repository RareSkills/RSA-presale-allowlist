import re

def checkValidity(address):
    # reg ex pattern for eth address
    pattern = '^0x[a-fA-F0-9]{40}$'
    result = re.match(pattern, address)

    # check if valid eth address was passed in
    if not result:
        raise Exception("Invalid Eth address specified!")