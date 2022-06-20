# @version 0.3.3

from vyper.interfaces import ERC20

##############
# STRUCTURES #
##############

struct Vault:
	token: address
	amount: uint256
	owner: address
	signers: address[2]
	isSigned: bool[2]
	isActive: bool
	time: uint256

##########
# EVENTS #
##########

# add indexed keyword

event Created:
	index: indexed(uint256)
	token: address
	amount: uint256
	owner: indexed(address)

event Signed:
	index: indexed(uint256)
	signer: address

event Withdrawn:
	index: indexed(uint256)

event EmergencyCalled:
	index: indexed(uint256)
	time: uint256

event EmergencyWithdrawn:
	index: indexed(uint256)

###################
# STATE VARIABLES #
###################

EMERGENCY_DELAY: constant(uint256) = 259200 # 3 days

vaults: public(HashMap[uint256, Vault])
nbVaults: public(uint256)

######################
# EXTERNAL FUNCTIONS #
######################

@nonpayable
@external
def createVault(token: address, amount: uint256, firstSigner: address,
		secondSigner: address):
	assert firstSigner != ZERO_ADDRESS and secondSigner != ZERO_ADDRESS
	assert msg.sender != firstSigner and msg.sender != secondSigner
	assert firstSigner != secondSigner
	assert amount > 0
	self.vaults[self.nbVaults] = Vault({
		token: token,
		amount: amount,
		owner: msg.sender,
		signers: [firstSigner, secondSigner],
		isSigned: [False, False],
		isActive: True,
		time: 0})
	self.nbVaults += 1
	# user has to approve token transfer from contract first
	ERC20(token).transferFrom(msg.sender, self, amount)
	log Created(self.nbVaults - 1, token, amount, msg.sender)
	# return value [?]

@nonpayable
@external
def signWithdrawal(index: uint256):
	assert index < self.nbVaults
	assert self.vaults[index].isActive
	if msg.sender == self.vaults[index].signers[0]:
		self.vaults[index].isSigned[0] = True
	elif msg.sender == self.vaults[index].signers[1]:
		self.vaults[index].isSigned[1] = True
	else:
		raise "address is not a signer"
	log Signed(index, msg.sender)
	# return value [?]

@nonpayable
@external
def withdrawFromVault(index: uint256):
	assert index < self.nbVaults
	assert msg.sender == self.vaults[index].owner
	assert self.vaults[index].isSigned[0] and self.vaults[index].isSigned[1]
	assert self.vaults[index].isActive
	ERC20(self.vaults[index].token).transfer(msg.sender, self.vaults[index].amount)
	self.vaults[index].isActive = False
	log Withdrawn(index)
	# return value [?]

@nonpayable
@external
def callEmergency(index: uint256):
	assert index < self.nbVaults
	assert msg.sender == self.vaults[index].owner
	assert self.vaults[index].isActive
	self.vaults[index].time = block.timestamp + EMERGENCY_DELAY
	log EmergencyCalled(index, self.vaults[index].time)
	# return value [?]

@nonpayable
@external
def emergencyWithdraw(index: uint256):
	assert index < self.nbVaults
	assert msg.sender == self.vaults[index].owner
	assert self.vaults[index].isActive
	assert self.vaults[index].time > 0 and self.vaults[index].time < block.timestamp
	ERC20(self.vaults[index].token).transfer(msg.sender, self.vaults[index].amount)
	self.vaults[index].isActive = False
	log EmergencyWithdrawn(index)
	# return value [?]
