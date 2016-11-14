extends Node2D # or another class of you scene

# instance
var websocket

# handler to text messages
func _on_message(msg):
    print("SERVER SAYS: ", msg)

# handler to some button on you scene
func _on_some_button_released():
    websocket.send("Some short message here")

# entry point
func _ready():
    websocket = preload('ws.gd').new(self)
    websocket.start('boiling-waters-10225.herokuapp.com',80)
    websocket.set_reciever(self,'_on_message')

func _on_Button_pressed():
	_on_some_button_released()
