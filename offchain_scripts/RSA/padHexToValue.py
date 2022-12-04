def padTo(hexValue, padTo):
    # with a passed hex value pad it to this amount
    # return as string for proper display/text storage format
    return "0x" + str(hexValue)[2:].zfill(padTo)