from lazagne.config.constant import constant
from time import gmtime, strftime
import logging
import getpass
import socket
import json
import sys
import os

tmp_user = None

# --------------------------- Standard output functions ---------------------------

class StandartOutput():
	def __init__(self):
		self.banner = '''
|====================================================================|
|                                                                    |
|                        The LaZagne Project                         |
|                                                                    |
|                          ! BANG BANG !                             |
|                                                                    |
|====================================================================|
		'''

		self.grey_color 	= '\033[90m'
		self.red_color 		= '\033[91m'
		self.green_color 	= '\033[92m'
		self.cyan_color		= '\033[94m'
		self.no_color		= '\033[0m'

	# print banner
	def first_title(self):
		self.do_print(message=self.banner, color='white')
	
	# info option for the logging
	def print_title(self, title):
		t = '------------------- ' + title + ' passwords -----------------\n'
		self.do_print(message=t, color='white')
	
	# debug option for the logging
	def title_info(self, title):
		t = '------------------- ' + title + ' passwords -----------------\n'
		self.print_logging(function=logging.info, category='', message=t, color='white')

	def print_user(self, user):
		self.do_print('########## User: %s ##########\n' % user)

	def print_footer(self):
		footer = '\n[+] %s passwords have been found.\n' % str(constant.nbPasswordFound)
		if logging.getLogger().isEnabledFor(logging.INFO) == False:
			footer += 'For more information launch it again with the -v option\n'
		self.do_print(footer)

	def try_unicode(self, obj, encoding='utf-8'):
		try:
			if isinstance(obj, basestring):
				if not isinstance(obj, unicode):
					obj = unicode(obj, encoding)
		except:
			pass
		return obj

	# centralize print function
	def do_print(self, message='', color=False):
		# quiet mode => nothing is printed
		# if constant.quiet_mode:
		# 	return
		
		message = self.try_unicode(message)
		self.print_without_error(message, color=color)

	def choose_color(self, color):
		if color == 'white':
			return self.grey_color
		elif color == 'red':
			return self.red_color
		elif color == 'green':
			return self.green_color
		elif color == 'cyan':
			return self.cyan_color
		else:
			return self.no_color

	def print_without_error(self, message, color):
		print '{color}{message}{restore_color}'.format(
														color=self.choose_color(color), 
														message=message, 
														restore_color=self.no_color
													)

	def print_logging(self, function, category='INFO', message='', color=False):
		# if constant.quiet_mode:
		# 	return

		if category:
			category = '[%s]' % category

		function('{color}{category} {message}{restore_color}\n'.format(
																		color=self.choose_color(color), 
																		category=category, 
																		message=message, 
																		restore_color=self.no_color)
																	)

	def print_output(self, software_name, pwdFound, title1=False):
	
		# manage differently hashes / and hex value
		if pwdFound:
			category = None
			if '__SYSTEM__' in pwdFound:
				pwdFound.remove('__SYSTEM__')
				category = 'hash'
				pwdFound = pwdFound[0]

		if pwdFound:
			# if the debug logging level is not apply => print the title
			if logging.getLogger().isEnabledFor(logging.INFO) == False:
				# print the username only if password have been found
				user = constant.finalResults.get('User', '')
				global tmp_user
				if user != tmp_user:
					tmp_user = user
					self.print_user(user)

				# if not title1:
				self.print_title(software_name)
			
			toWrite = []
						
			# System Hashes
			if category == 'hash':
				for pwd in pwdFound:
					self.do_print(pwd)
					toWrite.append(pwd)
				self.do_print()

			# Other passwords
			else:
				for pwd in pwdFound:
					password_category = False
					# detect which kinds of password has been found
					lower_list = [s.lower() for s in pwd.keys()]
					password = [s for s in lower_list if "password" in s]
					if password: 
						password_category = password
					else:
						key = [s for s in lower_list if "key" in s] # for the wifi
						if key: 
							password_category = key
						else:
							hash = [s for s in lower_list if "hash" in s]
							if hash:
								password_category = hash
					
					# No password found
					if not password_category:
						print_debug("FAILED", "Password not found !!!")
					else:
						print_debug("OK", '%s found !!!' % password_category[0].title())
						toWrite.append(pwd)
						
						# Store all passwords found on a table => for dictionary attack if master password set
						constant.nbPasswordFound += 1

						if password_category[0] in pwd:
							constant.passwordFound.append(pwd[password_category[0]])

						elif password_category[0].capitalize() in pwd:
							constant.passwordFound.append(pwd[password_category[0].capitalize()])
					
					for p in pwd.keys():
						self.do_print('%s: %s' % (p, pwd[p]))
					self.do_print()
				
			# write credentials into a text file
			self.checks_write(toWrite, software_name)
		else:
			logging.info("[!] No passwords found\n")


	def write_header(self):
		time = strftime("%Y-%m-%d %H:%M:%S", gmtime())
		header = '{banner}\r\n- Date: {date}\r\n- Username: {username}\r\n- Hostname:{hostname}\r\n\r\n'.format(
				banner	 = self.banner.replace('\n', '\r\n'),
				date 	 = str(time), 
				username = getpass.getuser(), 
				hostname = socket.gethostname()
			)
		open(os.path.join(constant.folder_name, '%s.txt' % constant.file_name_results),"a+b").write(header)

	def write_footer(self):
		footer = '\n[+] %s passwords have been found.\r\n\r\n' % str(constant.nbPasswordFound)
		open(os.path.join(constant.folder_name, '%s.txt' % constant.file_name_results),"a+b").write(footer)
	
	def checks_write(self, values, category):
		if values:
			if "Passwords" not in constant.finalResults:
				constant.finalResults["Passwords"] = []
			constant.finalResults["Passwords"].append([{"Category": category}, values])

def print_debug(error_level, message):

	# print when password is found
	if error_level == 'OK':
		constant.st.do_print(message=message, color='green')

	# print when password is not found
	elif error_level == 'FAILED':
		constant.st.do_print(message=message, color='red')

	elif error_level == 'CRITICAL' or error_level == 'ERROR':
		constant.st.print_logging(function=logging.error, category='ERROR', message=message, color='red')

	elif error_level == 'WARNING':
		constant.st.print_logging(function=logging.warning, category='WARNING', message=message, color='cyan')

	elif error_level == 'DEBUG':
		constant.st.print_logging(function=logging.debug, message=message, category='DEBUG')

	else:
		constant.st.print_logging(function=logging.info, message=message, category='INFO')

# --------------------------- End of output functions ---------------------------

def parseJsonResultToBuffer(jsonString, color=False):
	buffer = u''
	try:
		for json in jsonString:
			if json:
				buffer += u'##################  User: {username} ################## \r\n'.format(username=json['User'])
				if 'Passwords' not in json:
					buffer += u'No passwords found for this user !\r\n\r\n'
				else:
					for all_passwords in json['Passwords']:
						buffer += u'\r\n------------------- {password_category} -----------------\r\n'.format(password_category=all_passwords[0]['Category'])
						if all_passwords[0]['Category'].lower() in ['lsa', 'hashdump', 'cachedump']:
							for dic in all_passwords[1]:
								if all_passwords[0]['Category'].lower() == 'lsa':
									for d in dic:
										buffer += u'%s\r\n' % (constant.st.try_unicode(d))
								else:
									buffer += u'%s\r\n' % (constant.st.try_unicode(dic))
						else:
							for password_by_category in all_passwords[1]:
								buffer += u'\r\nPassword found !!!\r\n'
								for dic in password_by_category.keys():
									try:
										buffer += u'%s: %s\r\n' % (dic, constant.st.try_unicode(password_by_category[dic]))
									except Exception, e:
										print_debug('ERROR', 'Error retrieving the password encoding: %s' % e)
						buffer += u'\r\n'
	except Exception as e:
		print_debug('ERROR', 'Error parsing the json results: %s' % e)
		print_debug('ERROR', 'json content: %s' % jsonString)

	return buffer
