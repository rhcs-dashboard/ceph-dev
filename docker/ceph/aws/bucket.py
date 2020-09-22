#!/usr/bin/env python3

"""Run this tool inside a running cluster container i.e.:

docker-compose exec ceph bash
/docker/aws/bucket.py -h
"""

import argparse
import sys

import boto3
from botocore.parsers import ResponseParserError


parser = argparse.ArgumentParser(description="Bucket bulk operations")
parser.add_argument("action", help="action to perform. 'Delete' action deletes all buckets.",
                    type=str, choices=['create', 'delete'])
parser.add_argument("--amount", help="amount of buckets to create.", type=int, default=1)
parser.add_argument("--offset", help="bucket offset for create action.", type=int, default=1)
parser.add_argument("--objects", help="amount of objects to create per bucket.", type=int, default=0)
parser.add_argument("--endpoint_url", help="endpoint url.", type=str, default='http://localhost:8000')
args = parser.parse_args()

s3 = boto3.resource('s3',
                    endpoint_url=args.endpoint_url,
                    use_ssl=False
                    )

if args.action == 'create':
    for bucket_index in range(args.offset, args.offset + args.amount):
        bucket_name = 'bucket{}'.format(bucket_index)
        try:
            bucket = s3.create_bucket(Bucket=bucket_name)
        except ResponseParserError:
            pass
        print("Bucket created:", bucket_name)

        if args.objects > 0:
            for obj_index in range(args.objects):
                object_name = 'obj{}'.format(obj_index)
                s3.Object(bucket_name, object_name).put(Body=open(sys.argv[0], 'rb'))
                print("Object created:", object_name)

elif args.action == 'delete':
    for bucket in s3.buckets.all():
        for key in bucket.objects.all():
            key.delete()
            print('Deleted object', key.key, 'from bucket', bucket.name)
        bucket.delete()
        print('Deleted bucket', bucket.name)

print("\nOperation completed!", "\n--------------------\n")
