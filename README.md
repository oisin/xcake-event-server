xcake-event-server
==================

Events server for Xcake Rubymotion episode

Yeah I'll fill this in laters.

```
$ curl -X POST -d '{"email" : "a@b.com", "password" : "woot"}' http://localhost:9292/api/v1.0/register
{"token":"hRw4lUsWKZ0VzbJVk8IdBQ"}
```

```
$ curl http://localhost:9292/api/v1.0/events
[
  {
    "ref": "531b483ac6a4da3663000001",
    "name": "event1",
    "organizer": "o@converser.io",
    "location": "Science Gallery",
    "description": "Some kind of a hoolie",
    "starts": 1409769000,
    "ends": 1409776200
  },
  {
    "ref": "531b4884c6a4da036e000001",
    "name": "event1",
    "organizer": "o@converser.io",
    "location": "Science Gallery",
    "description": "Some kind of a hoolie",
    "starts": 1394821800,
    "ends": 1394829000
  },
  {
    "ref": "531b4884c6a4da036e000004",
    "name": "event2",
    "organizer": "o@converser.io",
    "location": "Science Gallery",
    "description": "Some kind of a hoolie",
    "starts": 1399314600,
    "ends": 1399321800
  },
  {
    "ref": "531b4884c6a4da036e000006",
    "name": "event3",
    "organizer": "o@converser.io",
    "location": "Science Gallery",
    "description": "Some kind of a hoolie",
    "starts": 1415730600,
    "ends": 1415737800
  },
  {
    "ref": "531b4884c6a4da036e000008",
    "name": "event4",
    "organizer": "o@converser.io",
    "location": "Science Gallery",
    "description": "Some kind of a hoolie",
    "starts": 1399401000,
    "ends": 1399408200
  }
]
```

```
$ curl -X POST -d '{"interested" : true}' http://localhost:9292/api/v1.0/event/531b483ac6a4da3663000001
{"errors":["you need to log in now"]
```
