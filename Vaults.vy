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
	is_signed: bool[2]
	is_active: bool
	time: uint256

##########
# EVENTS #
##########

# add indexed keyword

event Created:
	index: uint256
	token: address
	amount: uint256
	owner: address

event Signed:
	index: uint256
	signer: address

event Withdrawn:
	index: uint256

event EmergencyCalled:
	index: uint256
	time: uint256

event EmergencyWithdrawn:
	index: uint256

###################
# STATE VARIABLES #
###################

EMERGENCY_DELAY: constant(uint256) = 259200 # 3 days

vaults: public(HashMap[uint256, Vault])
nb_vaults: public(uint256)

######################
# EXTERNAL FUNCTIONS #
######################

@nonpayable
@external
def create_vault(token: address, amount: uint256, first_signer: address,
		second_signer: address):
	assert first_signer != ZERO_ADDRESS and second_signer != ZERO_ADDRESS
	assert msg.sender != first_signer and msg.sender != second_signer
	assert first_signer != second_signer
	self.vaults[self.nb_vaults] = Vault({
		token: token,
		amount: amount,
		owner: msg.sender,
		signers: [first_signer, second_signer],
		is_signed: [False, False],
		is_active: True,
		time: 0})
	self.nb_vaults += 1
	ERC20(token).transferFrom(msg.sender, self, amount)
	log Created(self.nb_vaults - 1, token, amount, msg.sender)
	# return value [?]

@nonpayable
@external
def sign_withdrawal(index: uint256):
	assert index < self.nb_vaults
	assert self.vaults[index].is_active
	if msg.sender == self.vaults[index].signers[0]:
		self.vaults[index].is_signed[0] = True
	elif msg.sender == self.vaults[index].signers[1]:
		self.vaults[index].is_signed[1] = True
	else:
		raise "address is not a signer"
	log Signed(index, msg.sender)
	# return value [?]

@nonpayable
@external
def withdraw_from_vault(index: uint256):
	assert index < self.nb_vaults
	assert msg.sender == self.vaults[index].owner
	assert self.vaults[index].is_signed[0] and self.vaults[index].is_signed[1]
	assert self.vaults[index].is_active
	ERC20(self.vaults[index].token).transfer(msg.sender,
			self.vaults[index].amount)
	self.vaults[index].is_active = False
	log Withdrawn(index)
	# return value [?]

@nonpayable
@external
def call_emergency(index: uint256):
	assert index < self.nb_vaults
	assert msg.sender == self.vaults[index].owner
	assert self.vaults[index].is_active
	self.vaults[index].time = block.timestamp + EMERGENCY_DELAY
	log EmergencyCalled(index, self.vaults[index].time)
	# return value [?]

@nonpayable
@external
def emergency_withdraw(index: uint256):
	assert index < self.nb_vaults
	assert msg.sender == self.vaults[index].owner
	assert self.vaults[index].is_active
	assert self.vaults[index].time > 0 and \
			self.vaults[index].time < block.timestamp
	ERC20(self.vaults[index].token).transfer(msg.sender,
			self.vaults[index].amount)
	self.vaults[index].is_active = False
	log EmergencyWithdrawn(index)
	# return value [?]
