#!/usr/bin/env python
#
#   Copyright 2013 Dominic LoBue
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License. 
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#

import sys
import socket
from time import time
import json

import logging

import boto

def main(domain, key, deployment):
    sdbconn = boto.connect_sdb()
    maxtime = int(time()) + 5 * 60
    chef_attribs = json.load(open('/root/chef_attribs.json'))
    traits = chef_attribs.get('traits', [])
    if isinstance(traits, basestring):
        traits = [traits]

    lockr_attribs = dict(((_, key) for _ in traits))

    state = {}
    while 1:
        if not state.get('deregistered', False):
            try:
                r = sdbconn.delete_attributes(domain, key)
                if r is True:
                    state['deregistered'] = True
            except boto.exception.SDBResponseError, e:
                if e.status == 404:
                    state['deregistered'] = True
                else:
                    raise e
            except socket.gaierror, e:
                logging.warn("socket gaierror: %s" % (e,))
            except socket.error, e:
                logging.warn("socket error: %s" % (e,))

        if not state.get('unlocked', False):
            try:
                r = sdbconn.delete_attributes(domain, deployment, lockr_attribs)
                if r is True:
                    state['unlocked'] = True
            except boto.exception.SDBResponseError, e:
                if e.status == 404:
                    state['unlocked'] = True
                else:
                    raise e
            except socket.gaierror, e:
                logging.warn("socket gaierror: %s" % (e,))
            except socket.error, e:
                logging.warn("socket error: %s" % (e,))

        if state.get('unlocked', False) and state.get('deregistered', False):
            break

        if int(time()) > maxtime:
            logging.error("unable to succeed for 5 min - dying")
            sys.exit(1)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], sys.argv[3])

