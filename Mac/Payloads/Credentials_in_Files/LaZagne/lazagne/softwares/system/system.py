from lazagne.config.write_output import print_debug
from lazagne.config.moduleInfo import ModuleInfo
from lazagne.config.constant import *


class System(ModuleInfo):
	def __init__(self):
		options = {'command': '-system', 'action': 'store_true', 'dest': 'system', 'help': 'Print system passwords found (keychain, system account)'}
		ModuleInfo.__init__(self, 'system', 'system', options)

	def run(self, software_name=None):
		pwdFound = []
		pwdFound += constant.keychains_pwd
		pwdFound += constant.system_pwd
		
		return pwdFound

