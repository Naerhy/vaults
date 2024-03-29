from flask import Flask, render_template, request, redirect, url_for
from web3 import Web3

import json

def convert_json(file):
    with open(file) as f:
        return json.load(f)

app = Flask(__name__)
LIST_NETWORKS = ["ropsten"]
LIST_PROVIDERS = ["https://ropsten.infura.io/v3/3bf84785afd6464ba615ed0c903d9878"]
VA_ADDRESSES = ["0x1eEC5Ed724aC0cADDa528550DD5136cDFd317Db7"]
VA_ABI = convert_json("Vaults.json")

def get_vaults(vaults, network, provider, va_address, user_address):
    web3 = Web3(Web3.HTTPProvider(provider))
    if not web3.isConnected():
        return 0
    va_contract = web3.eth.contract(address=va_address, abi=VA_ABI)
    nb_vaults = va_contract.functions.nbVaults().call()
    if nb_vaults == 0:
        return 0
    for i in range(nb_vaults):
        vault = va_contract.functions.vaults(i).call()
        if vault[2] == user_address:
            # converting tuple to list as we cannot modify tuple
            vault = list(vault)
            vault.append(i)
            vault.append(network)
            vaults.append(vault)

def format_input(vaults, web3):
    erc20_abi = convert_json("ERC20.json")
    for key in vaults:
        erc20_contract = web3.eth.contract(address=vaults[key][0], abi=erc20_abi)
        vaults[key][0] = erc20_contract.functions.symbol().call()
        vaults[key][1] = float(vaults[key][1] / 10 ** erc20_contract.functions.decimals().call())
        if vaults[key][4][0]:
            vaults[key][4][0] = "Signed"
        else:
            vaults[key][4][0] = "Not signed"
        if vaults[key][4][1]:
            vaults[key][4][1] = "Signed"
        else:
            vaults[key][4][1] = "Not signed"
        if vaults[key][5]:
            vaults[key][5] = "Active"
        else:
            vaults[key][5] = "Inactive"
    return vaults

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
    vaults = []
    for i in range(len(LIST_NETWORKS)):
        get_vaults(vaults, LIST_NETWORKS[i], LIST_PROVIDERS[i], VA_ADDRESSES[i], user_address)
    # format_input(vaults, web3)
    return render_template("vaults.html", vaults=vaults)

if __name__ == "__main__":
    # disable debug mode when deployed to live servers
    app.run(debug=True)
