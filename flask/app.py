from flask import Flask, render_template, request, redirect, url_for
from web3 import Web3

import json

app = Flask(__name__)
PROVIDER = "https://ropsten.infura.io/v3/3bf84785afd6464ba615ed0c903d9878"

def convert_json(file):
    with open(file) as f:
        return json.load(f)

@app.route("/", methods=["POST", "GET"])
def index():
    if request.method == "POST":
        user_address = request.form["address"]
        if not Web3.isAddress(user_address):
            return redirect("/")
        user_address = Web3.toChecksumAddress(user_address)
        return redirect(url_for("search", user_address=user_address))
    else:
        return render_template("index.html")

@app.route("/<user_address>")
def search(user_address):
    web3 = Web3(Web3.HTTPProvider(PROVIDER))
    if not web3.isConnected():
        return redirect("/")
    va_address = "0x1eEC5Ed724aC0cADDa528550DD5136cDFd317Db7"
    va_abi = convert_json("Vaults.json")
    va_contract = web3.eth.contract(address=va_address, abi=va_abi)
    nb_vaults = va_contract.functions.nbVaults().call()
    if nb_vaults == 0:
        return redirect("/")
    vaults = []
    for i in range(nb_vaults):
        vault = va_contract.functions.vaults(i).call()
        if vault[2] == user_address:
            vaults.append(vault)
    return render_template("vaults.html", vaults=vaults)

if __name__ == "__main__":
    # disable debug mode when deployed to live servers
    app.run(debug=True)
