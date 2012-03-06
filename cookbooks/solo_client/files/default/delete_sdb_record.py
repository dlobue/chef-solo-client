
import sys
import socket
from time import sleep

import logging

import boto

def main(domain, key):
    sdbconn = boto.connect_sdb()
    attempts = 1
    while 1:
        try:
            sdbconn.delete_attributes(domain, key)
        except boto.exception.SDBResponseError, e:
            if e.status == 404:
                break
            elif e.status in (500,503):
                logging.warn("aws service error!")
                pass
            else:
                raise e
        except socket.gaierror, e:
            logging.warn("warning: socket gaierror: %s" % (e,))
        except socket.error, e:
            logging.warn("warning: socket error: %s" % (e,))

        sleep(1+.2*attempts) # simple back off
        attempts += 1

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])

