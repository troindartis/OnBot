#-------------------------------------------------------------------------------
# Copyright 2018 Cognizant Technology Solutions
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License.  You may obtain a copy
# of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.
#-------------------------------------------------------------------------------

#Description:
#Description:
# installs the given plugins to jenkins
#
#Configuration:
# HUBOT_NAME
# HUBOT_JENKINS_URL
# HUBOT_JENKINS_USER
# HUBOT_JENKINS_PASSWORD
#
#COMMANDS:
# install <plugin1> <plugin2>... in jenkins -> install the given plugins to jenkins
# Example~
# install ccm msbuild mstest in jenkins
# (The above command will install ccm, msbuld and mstest plugin in jenkins)
#
#Depencencies:
# "request":"2.81.0"
# "elasticSearch": "^0.9.2"

request = require('request')
index = require('./index')
readjson = require './readjson.js'
finaljson=" ";
generate_id = require('./mongoConnt');

module.exports = (robot) ->
	robot.respond /install (.+) in jenkins/i, (res) ->
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			userplugin=[]
			userplugin=res.match[1].split(' ')
			if stdout.install_plugin.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					console.log(tckid);
					payload={botname:process.env.HUBOT_NAME,username:res.message.user.name,userid:res.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"installplugin",userplugin:userplugin}
					data='Ticket Id : '+tckid+'\n Raised By: '+res.message.user.name+'\n Command: install plugin(s) '+userplugin+' in jenkins\n approve or reject the request'
					robot.messageRoom(stdout.install_plugin.adminid, data);
					res.send 'Your request is waiting for approval by '+stdout.install_plugin.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				pluginString=[]
				plugins=[]
				flag=0
				pluginString=res.match[1].split(' ')
				jenkins_url=process.env.HUBOT_JENKINS_URL
				jenkins_user=process.env.HUBOT_JENKINS_USER
				jenkins_pass=process.env.HUBOT_JENKINS_PASSWORD
				url=jenkins_url+"/pluginManager/installNecessaryPlugins"
				pluginData="<jenkins>"
				for i in [0...pluginString.length]
					pluginData=pluginData+"<install plugin=\""+pluginString[i]+"@latest\" /></jenkins>"
					options = {
					auth: {
					'user': jenkins_user,
					'pass': jenkins_pass
					},
					method: 'POST',
					url: url,
					headers: {"Content-Type": "text/xml"},
					body: pluginData};
					request.post options, (error, response, body) ->
						if(response.statusCode!=302)
							dt="Error in installing"
							res.send dt
							setTimeout (->index.passData dt),1000
						else
							setTimeout ( -> getInstallations()),1000
					pluginData="<jenkins>"

				getInstallations = () ->
					options.url=jenkins_url+"/pluginManager/api/json?depth=1&xpath=/*/*/shortName|/*/*/version&wrapper=plugins"
					options.headers={"Content-Type": "text/json"}
					request.post options, (error, response, body) ->
						plugins=JSON.parse(body).plugins
				setTimeout ( -> check plugins),2000
				check = (plugins) ->
					if(plugins.length!=0)
						for i in [0...pluginString.length]
							for j in [0...plugins.length]
								console.log plugins[j].shortName
								if(pluginString[i]==plugins[j].shortName)
									dt=pluginString[i]+": Installed successfully"
									res.send dt
									setTimeout (->index.passData dt),1000
									message = res.match[0]
									actionmsg = "jenkins plugin installed"
									statusmsg = "Success"
									index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
									flag=1
									break
							if(flag==0)
								dt=pluginString[i]+": Error in installation. Verify the pluginID and try again"
								res.send dt
								setTimeout (->index.passData dt),1000
							flag=0
	#the following code handles the approval flow of the command
	robot.router.post '/installplugin', (req, response) ->
		recipientid=req.body.userid
		if(req.body.action=='Approved')
			dt=req.body.approver+" approved installation of plugins "+req.body.userplugin+", requested by "+req.body.username+"\n"
			robot.messageRoom recipientid, dt
			index.passData dt
			pluginString=[]
			plugins=[]
			flag=0
			pluginString=req.body.userplugin
			jenkins_url=process.env.HUBOT_JENKINS_URL
			jenkins_user=process.env.HUBOT_JENKINS_USER
			jenkins_pass=process.env.HUBOT_JENKINS_PASSWORD
			url=jenkins_url+"/pluginManager/installNecessaryPlugins"
			pluginData="<jenkins>"
			for i in [0...pluginString.length]
				pluginData=pluginData+"<install plugin=\""+pluginString[i]+"@latest\" /></jenkins>"
				options = {
				auth: {
				'user': jenkins_user,
				'pass': jenkins_pass
				},
				method: 'POST',
				url: url,
				headers: {"Content-Type": "text/xml"},
				body: pluginData};
				request.post options, (error, response, body) ->
					if(response.statusCode!=302)
						dt="Error in installing"
						robot.messageRoom recipientid, dt
						setTimeout (->index.passData dt),1000
					else
						setTimeout ( -> getInstallations()),1000
				pluginData="<jenkins>"

			getInstallations = () ->
				options.url=jenkins_url+"/pluginManager/api/json?depth=1&xpath=/*/*/shortName|/*/*/version&wrapper=plugins"
				options.headers={"Content-Type": "text/json"}
				request.post options, (error, response, body) ->
					plugins=JSON.parse(body).plugins
			setTimeout ( -> check plugins),2000
			check = (plugins) ->
				if(plugins.length!=0)
					for i in [0...pluginString.length]
						for j in [0...plugins.length]
							console.log plugins[j].shortName
							if(pluginString[i]==plugins[j].shortName)
								dt=pluginString[i]+": Installed successfully"
								robot.messageRoom recipientid, dt
								setTimeout (->index.passData dt),1000
								message = "install "+pluginString+" in jenkins"
								actionmsg = "jenkins plugin installed"
								statusmsg = "Success"
								index.wallData process.env.HUBOT_NAME, message, actionmsg, statusmsg;
								flag=1
								break
						if(flag==0)
							dt=pluginString[i]+": Error in installation. Verify the pluginID and try again"
							robot.messageRoom recipientid, dt
							setTimeout (->index.passData dt),1000
						flag=0
		else
			dt="The jenkins plugin installation request from "+req.body.username+" was rejected by "+req.body.approver
			robot.messageRoom recipientid, dt
			setTimeout (->index.passData dt),1000
