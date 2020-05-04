import os
import os.path
import ruamel.yaml
import sys
sys.path.insert(1,'./execution-frameworks/contrib/python')
import runner

load_path = '/opt/AtomicRedTeam/atomics'
yaml = ruamel.yaml.YAML()

def load_yaml_file(payload):
	with open(payload) as f:
		list_doc = yaml.load(f)
	return list_doc

def useful_test(atomic_tests, position):
	count = -1
	for data in atomic_tests:
		if data['name']:
			count += 1
		if count == position:
			return data
		else:
			print('out of bound')

def get_payload(list_doc,new_payload=None):
	test = useful_test(list_doc['atomic_tests'],0)
	inputs = test['input_arguments']
	if not new_payload:
		payload = inputs['payload']
		new_payload = payload['default']
	return new_payload

if __name__ == "__main__":
	technique = runner.AtomicRunner()
	index_list = ['execution','escalation','credential_access','presistance','collection','exfiltration','command&control']
	selected_list = ['T1166','T1156','T1113','T1022','T1090','T1059','T1139','T1146']
	relative = os.path.join(load_path,'escalation')
	load_file = os.path.join(relative,'T1166/T1166.yaml')
	normalize = os.path.normpath(load_file)
	list_doc = load_yaml_file(normalize)
	payload = get_payload(list_doc)
	for selected in selected_list:
		technique.execute(selected, position = 0)
	#print(payload)
