xcake-event-server
==================

Events server for Xcake Rubymotion episode



Yeah I'll fill this in laters.

```
➜ curl -X POST -d '{"email" : "wibble@b.com", "password" : "woot"}' http://xcake-events.herokuapp.com/api/v1.0/register
{"token":"tjqi8-pW6Xw9DJbL-AR8Sw"}
```

```
➜  curl http://xcake-events.herokuapp.com/api/v1.0/events
[{"ref":"531c96646823e4b050000002","name":"event1","organizer":"o@converser.io","location":"Science Gallery","description":"Some kind of a hoolie","starts":1398364200,"ends":1398371400},{"ref":"531c96646823e4b050000004","name":"event2","organizer":"o@converser.io","location":"Science Gallery","description":"Some kind of a hoolie","starts":1396722600,"ends":1396729800},{"ref":"531c96646823e4b050000006","name":"event3","organizer":"o@converser.io","location":"Science Gallery","description":"Some kind of a hoolie","starts":1416421800,"ends":1416429000},{"ref":"531c96646823e4b050000008","name":"event4","organizer":"o@converser.io","location":"Science Gallery","description":"Some kind of a hoolie","starts":1394821800,"ends":1394829000}]
```

```
➜  curl http://xcake-events.herokuapp.com/api/v1.0/event/531c96646823e4b050000002
{"ref":"531c96646823e4b050000002","name":"event1","organizer":"o@converser.io","location":"Science Gallery","description":"Some kind of a hoolie","starts":1398364200,"ends":1398371400}
```

```
➜ curl -X POST -d '{"interested" : true}' 'http://xcake-events.herokuapp.com/api/v1.0/event/531c96646823e4b050000002?token=tjqi8-pW6Xw9DJbL-AR8Sw'
```

```
➜ curl http://xcake-events.herokuapp.com/api/v1.0/event/531c96646823e4b050000002
{"ref":"531c96646823e4b050000002","name":"event1","organizer":"o@converser.io","location":"Science Gallery","description":"Some kind of a hoolie","starts":1398364200,"ends":1398371400}
```
