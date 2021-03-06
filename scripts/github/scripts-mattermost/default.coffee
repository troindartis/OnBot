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
# ensures hubot says "Sorry, I didn't get you" if user's command is not handled by hubot
#
#Configuration:
# None
#
#COMMANDS:
# none
#
#Dependencies:
# "elasticSearch": "^0.9.2"

index = require('./index')

module.exports = (robot) ->
  robot.hear /.+/, (msg) ->
    commands = ["show","github status","show issues","repo show","repo commiters","repo top-commiters","who do you know","i am","who am i","forget me","show issues","merge","github search","reload","create orgrepo","create repo","delete repo","create branch","delete branch","help","watch repo","stop watching","list my repos","list collaborators"]
    message = msg.message
    message.text = message.text or ''
    if message.text.match RegExp '^@?' + robot.name + ' +.*$', 'i'
     len = robot.name.length
     startIndex = message.text.indexOf(robot.name)
     endIndex = startIndex + len + 1
     realmsg = message.text.substr endIndex
     flag = 0
     for i in [0...commands.length]
      if realmsg.match ///.*^#{commands[i]}.*$///i
       flag = 1
      else
       #doStuff
     if flag == 0
      replies = ["All of your syntax mistakes are causing overload in my algorithms. Use help command","Please use the help command. I can't understand what you are talking about.","I'm sorry. I'm afraid I can't do that. Please use help command","Sometimes 'No' is the kindest word. I'm being kind now. Now only help command will save me",":mouse:. Help command please."]
      msg.send msg.random replies
      setTimeout ( ->index.passData "Sorry, I didn't get you."),1000
