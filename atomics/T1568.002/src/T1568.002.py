import datetime
import random
import string
import subprocess
import time

TLDs = ['.com', '.net', '.org', '.ru', '.biz']

def generate_domain(seed):
  random.seed(seed)
  length = random.randint(10, 15)
  name = ''.join(random.choice(string.ascii_lowercase) for _ in range(length))
  return name + random.choice(TLDs)


  today = datetime.date.today().strftime('%Y%m%d')
  print('[*] DGA cycle seed:', today)
  
  for i in range(10):
    domain = generate_domain(today + str(i))
    print('[+] Querying:', domain)
    subprocess.run(['dig', '+short', domain], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(2)
