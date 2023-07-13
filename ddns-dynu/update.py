import requests
import json
import dns.resolver  #in package dnspython
import os
import datetime

apiKey = os.environ['apiKey']
ddnsname = os.environ['ddnsname']

class Dynu: 
    def __init__(self, name, apiKey):
        self.name = name     
        self.baseURL = "https://api.dynu.com/v2"
        self.myHeaders = { "accept": "application/json", "API-Key": apiKey }
        self.ipCacheFilePath = "ipcache.txt"
        self.idCacheFilePath = "idcache.txt"
        self.lastModifiedIP = self.__getCachedIP()
         
    def getID(self):
        if os.path.exists(self.idCacheFilePath):  
           f = open(self.idCacheFilePath, "r")
           return int(f.read())
        else: 
           response = requests.get(f"{self.baseURL}/dns", headers=self.myHeaders)   
           data = response.json()
           #print(json.dumps(data, indent=4))  
           id = data.get("domains")[0].get("id")
           f = open(self.idCacheFilePath, "wt")
           f.write(str(id))
           f.close()
           return id

    def __getCachedIP(self):
        if os.path.exists(self.ipCacheFilePath):  
           f = open(self.ipCacheFilePath, "r")
           return f.read()
        else: 
           return "0.0.0.0"
        
    def cacheIP(self, ipAddressCache):        
        #print("Caching IP address: {}".format(ipAddressCache))  
        f = open(self.ipCacheFilePath, "wt")
        f.write(ipAddressCache)
        f.close()
         

    def updateIP(self, newIP):
        updateData =  { "name": self.name , "ipv4Address": newIP }
        updateDataJson = json.dumps(updateData)
        response = requests.post(f"{self.baseURL}/dns/{self.getID()}",headers=self.myHeaders, data=updateDataJson).json()
        #print(json.dumps(response, indent=4))
        if response.get("statusCode") == requests.codes.ok:
            self.cacheIP(newIP)
            print("{} IP addresses {} updated successfully".format(datetime.datetime.now(), newIP))
        else:
            print("Failed to update IP address {} with response as: {} ".format(newIP,response))
     

def getDNSIP(name):
    answer = dns.resolver.resolve(name, 'A')   # answer datatype: <class 'dns.rdtypes.IN.A.A'>
    return answer[0].__str__()

def getCurrentIP():
    ipaddress = requests.get("https://api.ipify.org?format=json").json()
    return ipaddress["ip"]  

ddnsIP = getDNSIP(ddnsname)
currentIP = getCurrentIP()

if currentIP != ddnsIP: 
    ddns = Dynu(ddnsname, apiKey)
    ddns.updateIP(currentIP)

#print("current IP: {} ,  cached IP: {} , ddns IP: {}".format(currentIP, ddns.lastModifiedIP, ddnsIP))