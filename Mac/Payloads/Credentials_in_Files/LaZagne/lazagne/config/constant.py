import time

date = time.strftime("%d%m%Y_%H%M%S")

class constant():
	folder_name 		= '.'
	file_name_results 	= 'credentials_{current_time}'.format(current_time=date) # the extention is added depending on the user output choice
	MAX_HELP_POSITION 	= 27
	CURRENT_VERSION 	= '0.2'
	output 				= None
	file_logger 		= None
	verbose 			= False
	
	# mozilla options
	manually 			= None
	path 				= None
	bruteforce 			= None
	specific_path 		= None
	mozilla_software 	= ''

	# total password found
	nbPasswordFound 	= 0
	passwordFound 		= []

	# password of the keychain
	keychains_pwd 		= []

	# passwords contain in the keychain
	keychains_pwds 		= []
	
	system_pwd 			= []

	finalResults 		= {}

	# standart output
	st 					= None

	dictionary_attack 	= False

	user_password		= None
	user_keychain_find 	= False 