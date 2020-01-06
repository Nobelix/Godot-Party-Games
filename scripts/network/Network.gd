extends Node

var port = 25565
const MAX_PEERS = 20
var players = {}
var player_data = {name=""}
var ip = '0.0.0.0'

func _ready():
	pass

#SETUP -----------------------------------------------------------------------------

# Each client has an unique id which is stored in the `players` dictionary, the is of the server is always 1

#SERVER SIDE:

func start_server(): 
	var host = NetworkedMultiplayerENet.new()
	host.create_server(port, MAX_PEERS)
	get_tree().set_network_peer(host)
	host.connect("peer_connected", self, "player_connected")
	host.connect("peer_disconnected", self, "player_disconnected")
	
	print("hosting the server at: " + str(port))
	players[1] = player_data
	print(players)
	
#THE CLIENT ASKS THE SERVER TO REGISTER HIM AND SYNC THE PLAYER LIST
remote func register_new_player(id, data):
	players[id] = data
	print("current registered players on server: " + str(players))
	rpc("syncplayers", players)

#-----------------------------------------------------------------------------------

#GLOBAL:

#EXECUTED ON ALREADY CONNECTED PEERS (INCLUDING THE SERVER) WHEN A NEW CLIENT CONNECTS
func player_connected(id):
	print("new client connected with ID " + str(id))

#EXECUTED ON ALREADY CONNECTED PEERS (INCLUDING THE SERVER) WHEN A CLIENT DISCONNECTS
func player_disconnected(id):
	print(str(id)+" disconnected")
	players.erase(id)

#SYNCS THE PLAYERLIST ACCROSS ALL PEERS
sync func syncplayers(playerlist):
	players=playerlist
	print("synced player list"+str(players))

#-----------------------------------------------------------------------------------

#CLIENT SIDE:

func join_server():
	var client = NetworkedMultiplayerENet.new()
	client.connect("peer_connected", self, "player_connected")
	client.connect("peer_disconnected", self, "player_disconnected")
	client.connect("connection_succeeded", self, "connected_to_server")
	client.connect("connection_failed", self, "connection_failed")
	client.connect("server_disconnected", self, "connection_lost")
	client.create_client(ip, port)
	get_tree().set_network_peer(client)
	print("connecting to the server at " + ip + ":" + str(port))
	players[get_tree().get_network_unique_id()] = player_data

#EXECUTED ON THE CLIENT WHEN IT FAILS TO CONNECT TO THE SERVER
func connection_failed():
	print("connection to the server failed")
	get_parent().get_parent().leave_game()

#EXECUTED ON THE CLIENT WHEN SUCCESSFULLY CONNECTED  TO THE SERVER
func connected_to_server():
	print("successfully connected to the server")
	player_data.spawned=true
	rpc_id(1, 'register_new_player',get_tree().get_network_unique_id(), player_data) #ASKS FOR REGISTRATION

#EXECUTED ON CLIENTS WHEN THEY LOSE THE CONNECTION TO THE SERVER
func connection_lost():
	get_parent().get_parent().leave_game()

#METHOD THAT SETUPS A NEW PLAYER ACCORDING TO A PEER //FROM THE CAT PROTOTYPE
#remote func spawn_player(id):
#	var player_scene = load("res://Scenes/Player.tscn")
#	var player = player_scene.instance()
#	player.set_name(str(id))
#
#	if id == get_tree().get_network_unique_id():
#		player.get_node("Camera").current=true
#		player.set_network_master(id)
#		player.player_id = id
#		player.move = true
#		player.nametag=player_data.name
#		player.hat=player_data.hat
#
#	else:
#		player.move = false
#		player.nametag=str(players[id].name)
#		player.hat=players[id].hat
#
#	get_parent().add_child(player)
#	player_data.spawned=true



