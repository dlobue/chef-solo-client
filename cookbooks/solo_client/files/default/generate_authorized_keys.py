#!/usr/bin/env python2
#
#   Copyright 2013 Geodelic
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

import hashlib
import os
import sys
import urllib2
import boto

def get_deployment_pubkeys():
    pubkeyurl = 'http://instance-data/latest/meta-data/public-keys/'
    for line in urllib2.urlopen(pubkeyurl).readlines():
        line = line.strip()
        if not line:
            continue
        keyid = line.split('=')[0].strip()
        yield urllib2.urlopen(pubkeyurl + keyid + '/openssh-key').read().strip()

def update_authorized_keys(pubkey_bucket, pubkey_prefix, user):
    s3conn = boto.connect_s3()
    try:
        bucket = s3conn.get_bucket(pubkey_bucket)
    except boto.exceptions.S3ResponseError:
        sys.stderr.write("Specified bucket doesn't exist.\n")
        sys.exit(10)
    s3pubkeys = dict([(os.path.basename(pk.name), pk) for pk in bucket.get_all_keys(prefix=pubkey_prefix) if pk.name.endswith('.pub')])

    if not s3pubkeys:
        sys.stderr.write("No public keys found in the %s bucket with a prefix of %s.\n" % (pubkey_bucket, pubkey_prefix))
        sys.exit(10)

    localpubkeys = []

    home_dir = os.path.expanduser('~%s' % user)
    if not os.path.exists(home_dir):
        sys.stderr.write("Homedir for user %s, or user doesn't exist." % user)
        sys.exit(10)

    dot_ssh = os.path.join(home_dir, '.ssh')
    authorized_keys = os.path.join(dot_ssh, 'authorized_keys')

    for item in os.listdir(dot_ssh):
        filePath = os.path.join(dot_ssh, item)
        if os.path.isfile(filePath) and item.endswith('.pub'):
            if item not in s3pubkeys or s3pubkeys[item].etag.strip('"') != md5sum(filePath):
                os.remove(filePath)
            else:
                localpubkeys.append(filePath)
                s3pubkeys.pop(item)

    for filename,pkey in s3pubkeys.iteritems():
        filePath = os.path.join(dot_ssh, filename)
        pkey.get_contents_to_filename(filePath)
        localpubkeys.append(filePath)

    with open(authorized_keys, 'w') as f:
        for pubkey in get_deployment_pubkeys():
            f.write(pubkey + '\n')

        for pubkey in localpubkeys:
            with open(pubkey) as pk:
                f.write(pk.read().strip() + '\n')


def md5sum(filePath):
    h = hashlib.md5()
    with open(filePath,'r') as f:
        while True:
            data = f.read(4096)
            if not data: break
            h.update(data)
    return h.hexdigest()

if __name__ == '__main__':
    update_authorized_keys(sys.argv[1], sys.argv[2], sys.argv[3])

