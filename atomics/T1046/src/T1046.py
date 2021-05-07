from socket import *
from threading import Thread
import argparse


def checking_port(host, port_number):
    s = socket(AF_INET, SOCK_STREAM)
    try:
        s.connect((host, int(port_number)))
        print(f'{host}/{port} - open')
    except:
        pass


arguments = argparse.ArgumentParser()
arguments.add_argument('-i', required=True, action='store', dest='ip', help='IP using to scan ports')

values = arguments.parse_args()
print('\nOpen ports:')
for port in range(0, 65536):
    t = Thread(target=checking_port, args=(values.ip, port))
    t.start()
