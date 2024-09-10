import sickle
from lxml import etree
import re
import os
import sys
import datetime
from time import sleep
from requests.exceptions import HTTPError

retry_sleep = int(os.environ.get('RETRY_SLEEP', 60))
retry_error = int(os.environ.get('RETRY_ERROR', 60))

retry_count = 0
harvested = 0


def main():
  harvester = sickle.Sickle(os.environ.get('URL', 'https://oai-pmh.api.melinda.kansalliskirjasto.fi/bib'))

  set = sys.argv[1] if len(sys.argv) >= 2 and len(sys.argv[1]) > 0 else None
  from_param = sys.argv[2] if len(sys.argv) >= 3 else None
  until = sys.argv[3] if len(sys.argv) >= 4 else None


  iterator = harvester.ListRecords(**{'metadataPrefix': 'melinda_marc', 'set': set, 'from': from_param, 'until': until})

  harvest(iterator)

def harvest(iterator):
  global harvested, retry_count

  try:
    for response in iterator:
      if not response.deleted:
        record = response.xml.find('.//' + response._oai_namespace + 'metadata').getchildren()[0]
        print(etree.tounicode(record))
      harvested += 1
      if (harvested % 1000) == 0:
        print("{} harvested {} records".format(datetime.datetime.now(), harvested), file=sys.stderr)
  except Exception as e:
    if retry_count < retry_error:
      retry_count += 1
      print("{} Got error: {}. Trying again in {} seconds. {}/{}".format(datetime.datetime.now(), e, retry_sleep, retry_count, retry_error))
      sleep(retry_sleep)
      harvest(iterator)
    else:
      raise e
    
if __name__ == '__main__':
  main()
