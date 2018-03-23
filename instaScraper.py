#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Mar 21 18:35:09 2018

@author: arroyo
"""
import requests
import io
import datetime

def writePosts(file, lat, long, name, arrayOfPosts):
    
    for edge in arrayOfPosts:
        post_id = edge['node']['id']
        
        # If no content
        if len(edge['node']['edge_media_to_caption']['edges']) == 0:
            continue
        
        userId = edge['node']['owner']['id']
        timestamp = edge['node']['taken_at_timestamp']
        time = datetime.datetime.fromtimestamp(int(timestamp)).strftime('%Y-%m-%d %H:%M:%S')
        text = edge['node']['edge_media_to_caption']['edges'][0]['node']['text']
        text = text.replace('\n', ' ').replace('\r', '').replace(',', '')
        out = name + ',' + str(post_id) + ',' + str(lat) + ',' + str(long) + ',' + time + ',' + text + '\n'
        out = unicode(out)
        file.write(out)

# get all location ids
file = open("location_ids.txt", 'r')
location_ids = file.readline().split(", ")
file.close()

# file for saving scrape results
file = io.open("posts.csv", 'a', encoding='utf8')
#out = unicode("name,id,lat,long,time,content\n")
#file.write(out)

# file for keeping track what ids have we completed
doneFile = open("done.txt", 'r+')
done = doneFile.readline().split(",")
if len(done) == 1:
    done = []
print(done)

# create list of unsearched location ids
notDone = list(set(location_ids) - set(done))
print(len(notDone) == len(location_ids))

api_endpoint = "https://www.instagram.com/graphql/query/"
query_id = "17881432870018455"
params = {"query_id": query_id, "first": 100}

try:
    
    for location in notDone:
        params['id'] = location
        has_next = True
        end_cursor = ""
        depth = 0
        
        while has_next:
            params['after'] = end_cursor        
            r = requests.get(api_endpoint, params=params)   
            response = r.json()
            
            # Get all the necessary information
            data = response['data']['location']
            lat = data['lat']
            long = data['lng']
            name = data['name']
            has_next = data['edge_location_to_media']['page_info']['has_next_page']
            end_cursor = data['edge_location_to_media']['page_info']['end_cursor']
            edges = data['edge_location_to_media']['edges']
            
            # write to file
            writePosts(file, lat, long, name, edges)
            depth += 1

        doneFile.write(',' + location)
        
            
except RuntimeError as detail:
    print("RuntimeError: " + detail)

finally:
    doneFile.close()
    file.close()
    

    
