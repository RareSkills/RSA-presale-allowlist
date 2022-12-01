from loadKeyPair import load
from padHex import pad
import csv
import validAddress

def generateSigs(file, outputFile, header):
    # load key values
    n, e, d = load()

    # get length modulus hex data
    keyHexLength = len(hex(n))-2

    # read csv file (first value must be the address)
    with open(file, 'r') as readOutput:
        reader = csv.reader(readOutput)

        with open(outputFile, 'w', newline='') as writeOutput:
            writer = csv.writer(writeOutput)

            if header:
                # if user indicates presence of header
                initialData = next(reader)
                initialData.append('signature')
                writer.writerow(initialData)

            for line in reader:
                # for each line in  csv file get first value
                address = line[0]

                # check if valid eth address was passed in
                # else throw exception
                validAddress.checkValidity(address) 

                # generate signature for address
                message = int(address, 16)
                sig = pow(message, d, n)

                # check if decoded signature matches message
                # (verify validity of the public key/private key pair)
                if not message == pow(sig, e, n):
                    # decoded signature = signature ^ e % n  
                    raise Exception("Invalid key pair!")

                # signature will always be appended as last value 
                # i.e address, email, signature
                # pad to appropriate hex bytes length (each 2 digits is one byte)
                line.append(pad(hex(sig), keyHexLength))    
                writer.writerow(line)

            # close csv file objects
            writeOutput.close()
        readOutput.close