from flask import Flask, render_template, request
from web3 import Web3

import json

app = Flask(__name__)

@app.route("/", methods=["POST", "GET"])
def index():
    if request.method == "POST":
        # connect to ALL web3 providers
        # check return errors
        # declare contract address
        # get abi
        # declare web3 contract
        # check nb_vaults function and exit if == 0
        user_address = request.form["address"]
        if Web3.isAddress(user_address):
            user_address = Web3.toChecksumAddress(user_address)
            # vaults = set()
            # for i in range(nb_vaults):
                # vault = xxx.functions.vaults(i).call()
                # if (vault[2] == user_address:
                    # vaults.add(vault)
        return render_template("vaults.html", vaults)
    else:
        return render_template("index.html")

if __name__ == "__main__":
    # disable debug mode when deployed to live servers
    app.run(debug=True)
