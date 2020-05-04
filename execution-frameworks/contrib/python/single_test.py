import os
import os.path
import ruamel.yaml
import sys
sys.path.insert(1,'./execution-frameworks/contrib/python')
import runner

default_path = '/opt/AtomicRedTeam/atomics/single_test/T0000/T0000.yaml'
load_path = '/opt/AtomicRedTeam/atomics'
yaml = ruamel.yaml.YAML()
def load_yaml_file(payload):
	with open(payload) as f:
		list_doc = yaml.load(f)
	return list_doc

def write_new_yaml(list_doc,path):
	with open(path,'w') as f:
		yaml.dump(list_doc,f)
	check = load_yaml_file(path)
	if check:
		return True
	return False

def modify(list_doc):
	list_doc['attack_technique'] = 'T0000'
	list_doc['display_name'] = 'Single test'
	#print(len(list_doc['atomic_tests']))
	while len(list_doc['atomic_tests'])>1:
		list_doc['atomic_tests'].pop()
	write_new_yaml(list_doc,default_path)
			
	return list_doc

def add_command(original,new_add):
	while len(new_add['atomic_tests'])>1:
		new_add['atomic_tests'].pop()
	for inputs in new_add['atomic_tests']:
		input_args = inputs['input_arguments']
		#executor = inputs['executor']
	#command2add = executor['command']
	#print(command2add)
	with open(default_path,'w') as f:
		for data in original['atomic_tests']:
			data['input_arguments'] = [data['input_arguments']]
			#original_exec = data['executor']
			#original_exec['command'] = [original_exec['command']]
		#original_exec['command'].append(command2add)
		data['input_arguments'].append(input_args)
		yaml.dump(original,f)

if __name__ == "__main__":
	relative = os.path.join(load_path,'credential_access')
	load_file = os.path.join(relative,'T1139/T1139.yaml')
	normalize = os.path.normpath(load_file)
	list_doc = load_yaml_file('/opt/AtomicRedTeam/atomics/escalation/T1166/T1166.yaml')
	list_doc2 = load_yaml_file(normalize)
	#print(list_doc)
	list_doc = modify(list_doc)
	add_command(list_doc,list_doc2)
	
