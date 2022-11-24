import genRSAKeyPair
import viewRSAKeyPair
import genSingularSignature
import bulkGenSignatures
import sys

# mainRSA.py --genKeyPair -genExponent
# if no -genKeyPair then use existing keys inside ./crypto dir
# if no --genExponent then by default use e=3
# mainRSA.py --genSingularSignature [address]
# mainRSA.py --bulkGenSignatures [readingFile] [outputFile] [headerPresent (True or False)]
# csv files and main files must be in same dir
# crypto files must be in crypto folder

def main():
    flags = sys.argv

    if len(sys.argv) > 1:
        if "--viewKeyPair" in flags and "--genKeyPair" in flags:
            raise Exception("Cannot both view then generate a signature! Either or")
        
        if "--viewKeyPair" in flags:
            viewRSAKeyPair.viewKeys()

        # see if they want to generate a new key, if not then use stored keys in ./crypto dir
        if "--genKeyPair" in flags:
            # if there is genExponent or not
            if "--genExponent" in flags:
                # generate a random exponent value
                genRSAKeyPair.generateKeys(True)
            else:
                # use default exponent value of 3
                genRSAKeyPair.generateKeys()
        else:
            # continue without generating a new key pair
            pass

        # there cannot both be genSingularSignature and bulkGenSignatures (error)
        if ("--genSingularSignature" in flags) and  ("--bulkGenSignatures" in flags):
            raise Exception("Cannot generate both singular and bulk signatures!")

        if "--genSingularSignature" in flags:
            # -genSingularSignature [address] 
            index = flags.index('--genSingularSignature')

            # address is immediately proceeding argument
            address =  flags[index + 1]
            genSingularSignature.generateSig(address)

        if "--bulkGenSignatures" in flags:
            # -bulkGenSignatures [readingFile] [outputFile] [headerPresent]
            index = flags.index('--bulkGenSignatures')

            # immediately proceeding arguments
            file =  flags[index + 1]
            outputFile = flags[index + 2]

            if index + 3 < len(flags):
                # regarding headers in csv file
                # if there is a header
                headerPresent = flags[index + 3]

                # translate string arguments to bool equivalents
                if headerPresent == "False":
                    # if there is no header in the csv
                    bulkGenSignatures.generateSigs(file, outputFile, 0)
                else:
                    # assume there is a header in the csv
                    bulkGenSignatures.generateSigs(file, outputFile, 1) 
            else:
                raise Exception("Invalid arguments for bulk generation specified!")
            
    else:
        print("No arguments provided!")

def help():
    pass

main()
