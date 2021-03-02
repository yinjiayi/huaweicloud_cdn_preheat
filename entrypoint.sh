#!/bin/sh

set -e

if [ -z "$CDN_CLOUD" ]; then
  echo "CDN_CLOUD is not set. Default to myhuaweicloud.com."
  export CDN_CLOUD=myhuaweicloud.com
fi

if [ -z "$CDN_REGION" ]; then
  echo "CDN_REGION is not set. Default to cn-north-1."
  export CDN_REGION=cn-north-1
fi

if [ -z "$CDN_ENDPOINT" ]; then
  echo "CDN_ENDPOINT is not set. Default to https://cdn.myhuaweicloud.com/v1.0/."
  export CDN_ENDPOINT=https://cdn.myhuaweicloud.com/v1.0/
fi

if [ -z "$CDN_PROJECTID" ]; then
  echo "CDN_PROJECTID is not set. Default to null."
  export CDN_PROJECTID=""
fi

if [ -z "$CDN_AK" ]; then
  echo "CDN_AK is not set. Quitting."
  exit 1
fi

if [ -z "$CDN_SK" ]; then
  echo "CDN_SK is not set. Quitting."
  exit 1
fi

if [ -z "$CDN_URLS" ]; then
  echo "CDN_URLS is not set. Quitting."
  exit 1
fi

if [ -z "$OBS_AK" ]; then
  echo "OBS_AK is not set. Quitting."
  exit 1
fi

if [ -z "$OBS_SK" ]; then
  echo "OBS_AK is not set. Quitting."
  exit 1
fi

if [ -z "$OBS_SERVER" ]; then
  echo "OBS_AK is not set. Quitting."
  exit 1
fi

if [ -z "$OBS_BUCKET" ]; then
  echo "OBS_AK is not set. Quitting."
  exit 1
fi

cat > main.py <<EOF
# -*- coding:utf-8 -*-
import os
from obs import *
from openstack import connection

obs_ak = os.getenv('OBS_AK')
obs_sk = os.getenv('OBS_SK')
obs_server = os.getenv('OBS_SERVER')
obs_bucket = os.getenv('OBS_BUCKET')
cdn_projectId = os.getenv('CDN_PROJECTID')
cdn_cloud = os.getenv('CDN_CLOUD')
cdn_region = os.getenv('CDN_REGION')
cdn_ak = os.getenv('CDN_AK')
cdn_sk = os.getenv('CDN_SK')
cdn_urls = os.getenv('CDN_URLS')
cdn_endpoint = os.getenv('CDN_ENDPOINT')

def preheat_create(_preheat_task):

    os.environ.setdefault('OS_CDN_ENDPOINT_OVERRIDE', cdn_endpoint)

    conn = connection.Connection(project_id=cdn_projectId, cloud=cdn_cloud, region=cdn_region, ak=cdn_ak, sk=cdn_sk)
    task = conn.cdn.create_preheat_task(**_preheat_task)
    print(task)

def obs_list(obs_ak, obs_sk, obs_server, obs_bucket):

    obsClient = ObsClient(access_key_id=obs_ak, secret_access_key=obs_sk, server=obs_server)

    try:
        resp = obsClient.listObjects(obs_bucket)

        if resp.status <= 1000:
            listkey = []
            for content in resp.body.contents:
                key = cdn_urls + content.key
                listkey.append(key)
            return listkey

        else:
            print('errorCode:', resp.errorCode)
            print('errorMessage:', resp.errorMessage)

    except:
        import traceback
        print(traceback.format_exc())

if __name__ == "__main__":
    preheat_task = {
        "urls": obs_list(obs_ak, obs_sk, obs_server, obs_bucket)
    }
    preheat_create(preheat_task)

python main.py
