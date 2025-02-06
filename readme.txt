### ---------------------------------------- ###
Description: Get news list

Endpoint: /news

Request Method: GET

Input: None

Output:
[
  {
     cover_link: "cover link",
     title1: "Flood in City Center",
     title2: "Have",
     date: "2024-11-12",
     location: [lon, lat],
     views: 200,
  }
]
### ---------------------------------------- ###

### ---------------------------------------- ###
Description: Get one news

Endpoint: /news/{news_id}

Request Method: GET

Input:
news_id : string

Output:
{
 cover_link: "cover link",
 title1: "Flood in City Center",
 title2: "Have",
 date: "2024-11-12",
 location: [lon, lat],
 views: 200,
}
### ---------------------------------------- ###

### ---------------------------------------- ###
Description: Add one news - users

Endpoint: /news

Request Method: POST

Input:
{
  "title": "flood",
  "description": "what happened",
  "cover_image": base64,
  location: [lon, lat]
}

Output:
{
  "success": 200,
  "msg": "success",
  "data": {
    "news": {
      "id": added_new_id
      "...": ...
    }
  }
}

### ---------------------------------------- ###
Description: Edit one news - nextjs officer

Endpoint: /news

Request Method: PUT

Input:
{
  "id": 29,
  "title": "flood",
  "description": "what happened",
  "cover_image": base64,
  location: [lon, lat]
}

Output:
{
  "success": 200,
  "msg": "success",
  "data": {}
}


### ---------------------------------------- ###
Description: Delete one news

Endpoint: /news/id

Request Method: DELETE

Input: None

Output:
{
  "success": 200,
  "msg": "success",
  "data": {}
}

# ------------------------------------------ ###
