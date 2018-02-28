# browsers
from lazagne.softwares.browsers.mozilla import Mozilla
from lazagne.softwares.browsers.chrome import Chrome

# system
from lazagne.softwares.system.hashdump import Hashdump
from lazagne.softwares.system.chainbreaker import Chainbreaker
from lazagne.softwares.system.system import System

def get_categories():
	category = {
		'browsers'	: {'help': 'Web browsers supported'},
		'mails'		: {'help': 'Email clients supported'},
		'system'	: {'help': 'System credentials'},
	}
	return category

def get_modules():
	moduleNames = [
		Mozilla(),
		Chrome(),
		Hashdump(), 
		Chainbreaker(), 
		System()
	]
	return moduleNames
