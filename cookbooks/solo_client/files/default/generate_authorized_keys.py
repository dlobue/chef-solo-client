#!/usr/bin/env python2.7

import argparse
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

def get_s3_pubkeys(pubkey_bucket, pubkey_prefix):
    s3conn = boto.connect_s3()
    try:
        bucket = s3conn.get_bucket(pubkey_bucket)
    except boto.exceptions.S3ResponseError:
        sys.stderr.write("Specified bucket doesn't exist.\n")
        sys.exit(10)
    return dict([(os.path.basename(pk.name), pk) for pk in bucket.get_all_keys(prefix=pubkey_prefix) if pk.name.endswith('.pub')])

def update_authorized_keys(pubkey_bucket, pubkey_prefix, user, include_deployment_keys=False, include_deployment_local_keys=False):
    s3pubkeys = get_s3_pubkeys(pubkey_bucket, pubkey_prefix)

    if include_deployment_local_keys:
        s3pubkeys.update( get_s3_pubkeys(pubkey_bucket, '%s/%s' % (include_deployment_local_keys, pubkey_prefix)) )

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
        if os.path.isfile(filePath):
            if (os.path.getsize(filePath) == pkey.size and
                pkey.etag.strip('"') == md5sum(filePath)):
                localpubkeys.append(filePath)
            else:
                os.remove(filePath)

    with open(authorized_keys, 'w') as f:
        if include_deployment_keys:
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
    parser = argparse.ArgumentParser()
    parser.add_argument('pubkey_bucket')
    parser.add_argument('pubkey_prefix')
    parser.add_argument('user')
    parser.add_argument('-d', dest="include_deployment_keys", action='store_true')
    parser.add_argument('-l', dest="include_deployment_local_keys", default=False)
    args = parser.parse_args()

    update_authorized_keys(args.pubkey_bucket, args.pubkey_prefix, args.user, args.include_deployment_keys, args.include_deployment_local_keys)

