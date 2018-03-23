#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Mar 21 17:29:10 2018

@author: arroyo
"""

import requests

district_ids = set()
location_ids = set()

singaporeUrl = "https://www.instagram.com/explore/locations/SG/"
baseLocationURL = "https://www.instagram.com/explore/locations/"

headers = {"authority": "www.instagram.com",\
           "path": "/explore/locations/SG/",\
           "cookie": 'mid=WnuoowAEAAGGwyjHYmh5n_-QT_Xo; csrftoken=kKIv08js5QORSweSpWX99HTTyD9R7t7Z; ds_user_id=2989419123; ig_vw=1400; ig_pr=2; ig_vh=805; ig_or=landscape-primary; social_hash_bucket_id=768; rur=PRN; urlgen="{\"time\": 1521615471\054 \"202.94.70.51\": 55919\054 \"103.24.77.51\": 55919}:1eya20:7QMAFXk2-iHSKc5jCRgAfIpK_l4"; sessionid=IGSC86f475829ba892569994d1b2e876be24d96fbe917f7005894aa7e482cd9216d9%3A9xwsJRwqTa9RtP54p979N4pQBHaxzTc5%3A%7B%22_auth_user_id%22%3A2989419123%2C%22_auth_user_backend%22%3A%22accounts.backends.CaseInsensitiveModelBackend%22%2C%22_auth_user_hash%22%3A%22%22%2C%22_platform%22%3A4%2C%22_token_ver%22%3A2%2C%22_token%22%3A%222989419123%3AWmPfMjz7k2LkeJ4f0WJeY0PCnl9l55Li%3A1ad1119a2660255dc6d2218575ab85ffeafbce059d106c2461f88f2c3bf54666%22%2C%22last_refreshed%22%3A1521624460.5050013065%7D',\
           "origin": "https://www.instagram.com",\
           "referer": "https://www.instagram.com/explore/locations/SG/singapore/",\
           "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.186 Safari/537.36 OPR/51.0.2830.55",\
           "x-csrftoken": "kKIv08js5QORSweSpWX99HTTyD9R7t7Z",\
           "x-instagram-ajax": "1",\
           "x-requested-with": "XMLHttpRequest"}
payload = {"page": "1"}

def loopThroughPages(URL, key, payload, save_list):
    more_pages = True
    while more_pages:
        r = requests.post(URL, headers=headers, data=payload)
        response = r.json()
        
        for district in response[key]:
            save_list.add(district['id'])
        
        if response['next_page'] != None:
            payload['page'] = response['next_page']
        else:
            more_pages = False    

# Get all district ids
loopThroughPages(baseLocationURL + "SG/", "city_list", {"page":"1"}, district_ids)

# Get all location ids
payload['page'] = '1'
for district in district_ids:
    print("Checking district: " + district)
    loopThroughPages(baseLocationURL + district + "/", "location_list", {"page":"1"}, location_ids)
    
print(location_ids)