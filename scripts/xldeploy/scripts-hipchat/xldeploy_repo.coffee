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

###
Configuration:

1. XLDEPLOY_URL	
2. XLDEPLOY_USERNAME
3. XLDEPLOY_PASSWORD
4. HUBOT_NAME

Bot commands

1. deploy <filename> -> to deploy artifact
2. undeploy <version> from <environment> -> to undeploy artifact from environment
3. create repo <repoid> with file <filename> -> to create environment/host/server/virtualhost
4. update repo <repoid> with file <filename> -> to update environment/host/server/virtualhost
5. delete repo <repoid>
6. create role <rolename> 

Dependencies:
1. "elasticSearch": "^0.9.2"
2. "request": "2.81.0"

###
eindex = require('./index')
request= require('request')

xldeploy_url = process.env.XLDEPLOY_URL
username = process.env.XLDEPLOY_USERNAME
pawwsord = process.env.XLDEPLOY_PASSWORD
botname = process.env.HUBOT_NAME

deployapi = require('./xldeploy.js')
createrepo = require('./addinfra.js')
updaterepo = require('./updateinfra.js')
deleterepo = require('./deleteinfra.js')
undeploy = require('./undeploy.js')
deleterepo = require('./deleteinfra.js')
createrole = require('./createrole.js')
deleterole = require('./deleterole.js')
getrole = require('./getrole.js')
getuser = require('./getuser.js')
createuser = require('./createuser.js')
deleteuser = require('./deleteuser.js')
assignrole = require('./assignrole.js')
delassignrole = require('./delassignrole.js')
getrepo = require('./getrepo.js')
getjson = require './getjson.js'
generate_id = require('./mongoConnt')

module.exports = (robot) ->
	robot.respond /deploy (.*)/i, (msg) ->
		filename = msg.match[1]
		console.log(filename)
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.deploy.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for Hipchat	
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"xldeploy_deploy","filename":filename}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: for deployment with file '+filename+'\n approve or reject the request'
					robot.messageRoom(stdout.deploy.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.deploy.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert

			#Normal action without workflow flag
			else
				deployapi.deployment xldeploy_url, username, pawwsord, filename, (error, stdout, stderr) ->
					if error
						setTimeout (->eindex.passData error),1000
						console.log(error)
						msg.send "Error occured while deploying artifact";
					if stderr
						setTimeout (->eindex.passData stderr),1000
						console.log(stderr)
						msg.send stderr;
					if stdout
						setTimeout (->eindex.passData stdout),1000
						message = "xldeploy deployment done"
						actionmsg = "xldeploy deployment done"
						statusmsg = "sucess"
						eindex.wallData botname, message, actionmsg, statusmsg;
						console.log(stdout);
						msg.send stdout;
						
	#Listening the post url  
	robot.router.post '/xldeploy_deploy', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						deployapi.deployment xldeploy_url, username, pawwsord, data.filename, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while deploying artifact";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								message = "xldeploy repoupdate done"
								actionmsg = "xldeploy repoupdate done"
								statusmsg = "sucess"
								eindex.wallData botname, message, actionmsg, statusmsg;
								console.log(stdout);
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
			
	robot.respond /help/i, (msg) ->
		msg.send 'deploy <filename> \n create repo <id> with file <filename> \n update repo <id> with file <filename> \n undeploy <version> from <environment> \n delete repo <id> \n create role <role name> \n delete role <role name> \n get role \n get user <user name> \n create user <user name> with password <password> \n delete user <user name> \n assign role <role name> from user  <usr name> \n delete assignedrole <role name> from user <usr name> \n get repo'

	robot.respond /create repo (.*) with file (.*)/i, (msg) ->
		filename = msg.match[2]
		repoid = msg.match[1]
		
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.create.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for Hipchat	
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"xldeploy_create","filename":filename,"repoid":repoid}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: creating repo '+repoid+'\n approve or reject the request'
					robot.messageRoom(stdout.create.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.create.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert

			#Normal action without workflow flag
			else
				createrepo.create xldeploy_url, username, pawwsord, filename, repoid, (error, stdout, stderr) ->
					if error
						setTimeout (->eindex.passData error),1000
						console.log(error)
						msg.send "Error occured while creating repo";
					if stderr
						setTimeout (->eindex.passData stderr),1000
						console.log(stderr)
						msg.send stderr;
					if stdout
						setTimeout (->eindex.passData stdout),1000
						message = "xldeploy repo created"
						actionmsg = "xldeploy repo created"
						statusmsg = "sucess"
						eindex.wallData botname, message, actionmsg, statusmsg;
						console.log(stdout);
						msg.send stdout;
						
	#Listening the post url
	robot.router.post '/xldeploy_create', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						createrepo.create xldeploy_url, username, pawwsord, data.filename, data.repoid, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while creating repo";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								message = "xldeploy repo created"
								actionmsg = "xldeploy repo created"
								statusmsg = "sucess"
								eindex.wallData botname, message, actionmsg, statusmsg;
								console.log(stdout);
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
					
	robot.respond /update repo (.*) with file (.*)/i, (msg) ->
		filename = msg.match[2]
		repoid = msg.match[1]
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.update.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for Hipchat	
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"xldeploy_update","filename":filename,"repoid":repoid}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: updating repo '+repoid+'\n approve or reject the request'
					robot.messageRoom(stdout.update.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.update.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert

			#Normal action without workflow flag
			else
				updaterepo.update xldeploy_url, username, pawwsord, filename, repoid, (error, stdout, stderr) ->
					if error
						setTimeout (->eindex.passData error),1000
						console.log(error)
						msg.send "Error occured while updating repo";
					if stderr
						setTimeout (->eindex.passData stderr),1000
						console.log(stderr)
						msg.send stderr;
					if stdout
						setTimeout (->eindex.passData stdout),1000
						message = "rundeck project created"
						actionmsg = "rundeck project created"
						statusmsg = "sucess"
						eindex.wallData botname, message, actionmsg, statusmsg;
						console.log(stdout);
						msg.send stdout;
						
	#Listening the post url
	robot.router.post '/xldeploy_update', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						updaterepo.update xldeploy_url, username, pawwsord, data.filename, data.repoid, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while updating repo";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								message = "xldeploy repoupdate done"
								actionmsg = "xldeploy repoupdate done"
								statusmsg = "sucess"
								eindex.wallData botname, message, actionmsg, statusmsg;
								console.log(stdout);
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
			
	robot.respond /undeploy (.*) from (.*)/i, (msg) ->
		version = msg.match[1]
		environ = msg.match[2]
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.undeploy.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for Hipchat	
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"xldeploy_undeploy","version":version,"environ":environ}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command:  for undeploying '+version+' from'+environ +'\n approve or reject the request'
					robot.messageRoom(stdout.undeploy.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.undeploy.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert

			#Normal action without workflow flag
			else
				undeploy.undeployment xldeploy_url, username, pawwsord, version, environ, (error, stdout, stderr) ->
					if error
						setTimeout (->eindex.passData error),1000
						console.log(error)
						msg.send "Error occured while undeploying artifact";
					if stderr
						setTimeout (->eindex.passData stderr),1000
						console.log(stderr)
						msg.send stderr;
					if stdout
						setTimeout (->eindex.passData stdout),1000
						message = "xldeploy undeployment done"
						actionmsg = "xldeploy undeployment done"
						statusmsg = "sucess"
						eindex.wallData botname, message, actionmsg, statusmsg;
						console.log(stdout)
						config=JSON.stringify(stdout)
						msg.send config;	
						
	#Listening the post url
	robot.router.post '/xldeploy_undeploy', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						undeploy.undeployment xldeploy_url, username, pawwsord, data.version, data.environ, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while undeploying artifact";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								message = "xldeploy repo update "
								actionmsg = "xldeploy repo update "
								statusmsg = "sucess"
								eindex.wallData botname, message, actionmsg, statusmsg;
								console.log(stdout)
								config=JSON.stringify(stdout)
								robot.messageRoom data.userid, config;		
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
					
					
	robot.respond /delete repo (.*)/i, (msg) ->
		
		repoid = msg.match[1]
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.deleterepo.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for Hipchat	
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"xldeploy_deleterepo","repoid":repoid}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: deleting repo '+repoid+' \n approve or reject the request'
					robot.messageRoom(stdout.deleterepo.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.deleterepo.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert

			#Normal action without workflow flag
			else
				deleterepo.deleteinfra xldeploy_url, username, pawwsord, repoid, (error, stdout, stderr) ->
					if error
						setTimeout (->eindex.passData error),1000
						console.log(error)
						msg.send "Error occured while deleting repo";
					if stderr
						setTimeout (->eindex.passData stderr),1000
						console.log(stderr)
						msg.send stderr;
					if stdout
						setTimeout (->eindex.passData stdout),1000
						message = "xldeploy repo deleted"
						actionmsg = "xldeploy repo deleted"
						statusmsg = "sucess"
						eindex.wallData botname, message, actionmsg, statusmsg;
						console.log(stdout);
						msg.send stdout;
						
	#Listening the post url
	robot.router.post '/xldeploy_deleterepo', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						deleterepo.deleteinfra xldeploy_url, username, pawwsord, data.repoid, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while deleting repo";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								message = "xldeploy repo deleted"
								actionmsg = "xldeploy repo deleted"
								statusmsg = "sucess"
								eindex.wallData botname, message, actionmsg, statusmsg;
								console.log(stdout);
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
					
	robot.respond /create role (.*)/i, (msg) ->
		
		name = msg.match[1]
		
		getjson.getworkflow_coffee (error,stdout,stderr) ->
		#Action Flow with workflow flag
			if(stdout.createrole.workflowflag)
				#Generate Random Ticket Number
				generate_id.getNextSequence (err,id) ->
					tckid=id
					#Prepare payload for Hipchat	
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,podIp:process.env.MY_POD_IP,"callback_id":"xldeploy_createrole","name":name}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command: creating role '+name+' \n approve or reject the request'
					robot.messageRoom(stdout.createrole.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.createrole.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert

			#Normal action without workflow flag
			else
				createrole.createrole xldeploy_url, username, pawwsord, name, (error, stdout, stderr) ->
					if error
						setTimeout (->eindex.passData error),1000
						console.log(error)
						msg.send "Error occured while creating role";
					if stderr
						setTimeout (->eindex.passData stderr),1000
						console.log(stderr)
						msg.send stderr;
					if stdout
						setTimeout (->eindex.passData stdout),1000
						message = "xldeploy role created"
						actionmsg = "xldeploy role created"
						statusmsg = "sucess"
						eindex.wallData botname, message, actionmsg, statusmsg;
						console.log(stdout);
						msg.send stdout;
	#Listening the post url
	robot.router.post '/xldeploy_createrole', (request,response) ->
					data= if request.body.payload? then JSON.parse request.body.payload else request.body
					#Action flow after approve
					if data.action=='Approved'
						robot.messageRoom data.userid, 'your request is approved by '+data.approver;
						createrole.createrole xldeploy_url, username, pawwsord, data.name, (error, stdout, stderr) ->
							if error
								setTimeout (->eindex.passData error),1000
								console.log(error)
								robot.messageRoom data.userid, "Error occured while creating role";
							if stderr
								setTimeout (->eindex.passData stderr),1000
								console.log(stderr)
								robot.messageRoom data.userid, stderr;
							if stdout
								setTimeout (->eindex.passData stdout),1000
								message = "xldeploy role created"
								actionmsg = "xldeploy role created"
								statusmsg = "sucess"
								eindex.wallData botname, message, actionmsg, statusmsg;
								console.log(stdout);
								robot.messageRoom data.userid, stdout;
					#Action flow after reject
					else
						robot.messageRoom data.userid, 'your request is rejected by '+data.approver;
					response.send 'success http call'
