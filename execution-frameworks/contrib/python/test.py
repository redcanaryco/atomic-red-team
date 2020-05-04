import json
import os
import os.path
import sys
sys.path.insert(1,'./execution-frameworks/contrib/python')
import runner
from os import listdir
from os.path import isfile, join
import random


def generate_index_list():
	path = './atomics'
	index_list = []
	count = 0
	load_list = ['escalation','execution','collection','command&control','credential_access',\
	'defence_evasion','discovery','exfiltration','initial_access','lateral_movement','persistence']
	for i in range(len(load_list)):
		tmp = []
		relative_path = os.path.join(path,load_list[i])
		tmp.append(load_list[i])
		attacks = [f for f in listdir(relative_path)]
		count += len(attacks)
		tmp.append(attacks)
		index_list.append(tmp)
	#print(index_list)
	#print(count)
	return index_list
def load():
	technique = runner.AtomicRunner()
	index_list = generate_index_list()
	#flag = technique.execute("T1169",position = 0)
	#print(flag)
	return(technique, index_list)

def random_func(need_random:list):
	return random.choice(need_random)

def handle_fail(modified_list:list,technique):
	selected = random_func(modified_list)
	flag = technique.execute(selected, position = random.randint(0,2))
	if flag is True:
		return
	else:
		new_list = modified_list.copy()
		new_list.remove(selected)
		if len(new_list) == 0:
			print('no available test at this moment, continue to next step')
			return
	handle_fail(new_list,technique)

def generate_random_test(index_list,technique):
	for i in index_list:
		x =  0
		selected = random_func(i[1])
		tmp = i[1].copy()
		#print("select is ",selected)
		while x < 3:
			flag = technique.execute(selected, position = x)
			if flag is True:
				break
			else:
				x+=1
				if x == 3:
					print('no available command for this specific test')
					tmp.remove(selected)
					#print(tmp)
					if len(tmp) != 0:
						handle_fail(tmp, technique)
					else:
						print('no available test')

			

if __name__ == "__main__":
	technique, index_list = load()
	generate_random_test(index_list,technique)
	
