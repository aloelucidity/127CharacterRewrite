class_name Character
extends KinematicBody2D


### Basics
var velocity: Vector2
var facing_direction: int
var gravity: float = 7.82

### Attributes
export var gravity_factor: float = 1
export var base_size: Vector2

### Nodes
onready var collider = $"%Collider"
onready var physics_states = $PhysicsStates

### States
var physics: PhysicsState
var action: ActionState

# the below is used for coyote time; when the ground state transitions 
# to the air state, it'll set an override for a few frames so you
# can still do ground actions even if you're slightly late
var container_override: PhysicsState
var override_timer: int

### Inputs
enum input_names {
	left, 
	right, 
	jump, 
	dive, 
	spin, 
	gp, 
	gpcancel, 
	fludd, 
	nozzles, 
	crouch, 
	interact, 
	up, 
	down 
}
# First parameter is "pressed",
# second parameter is "just_pressed", 
# and third parameter is the input name.
export var inputs: Array

func update_inputs() -> void:
	for input in inputs:
		# previously, they were indexed as input0 and input1 due to 
		# multiplayer. since it's no longer in the game it just adds 0 now
		input[0] = Input.is_action_pressed(input[2] + "0")
		input[1] = Input.is_action_just_pressed(input[2] + "0")


### Main loop
func _ready():
	for input in input_names.keys():
		inputs.append([false, false, str(input)])

func _physics_process(delta: float):
	update_inputs()
	
	handle_general_updates(delta)
	update_states(delta, "physics", physics_states)
	
	var container: PhysicsState = physics
	if override_timer > 0:
		override_timer -= 1
		container = container_override
		if override_timer <= 0: container_override = null
	
	update_states(delta, "action", container)
	
	collider._update(delta)


### States
func set_state(type: String, state: State) -> void:
	var old_state: State = self[type]
	if is_instance_valid(old_state):
		old_state._on_exit()
	
	self[type] = state
	
	if is_instance_valid(state):
		state._on_enter()


func check_startups(cur_state: State, container: Node) -> State:
	var cur_priority: int = int(-INF)
	if is_instance_valid(cur_state): cur_priority = cur_state.priority
	for check_state in container.get_children():
		var char_state: State
		if check_state is State:
			char_state = check_state
		elif check_state is StateLink:
			var link: StateLink = check_state
			char_state = link.link_to
		
		if (
			char_state.priority > cur_priority
		) or (
			char_state.priority >= cur_priority and 
			cur_state.allow_priority_override
		):
			if char_state._startup_check():
				return char_state
	return null


func handle_general_updates(delta: float) -> void:
	if is_instance_valid(physics_states):
		for phys in physics_states.get_children():
			phys._general_update(delta)
			
			for act in phys.get_children():
				var action_state: ActionState
				if act is ActionState:
					action_state = act
				elif act is StateLink:
					var link: StateLink = act
					action_state = link.link_to
				action_state._general_update(delta)


func update_states(delta: float, type: String, container: Node) -> void:
	## handle updates, transitions
	var cur_state: State = self[type]
	if is_instance_valid(cur_state):
		var transition_to: String = cur_state._transition_check()
		if transition_to == cur_state.name:
			cur_state._update(delta)
		elif is_instance_valid(container) and container.has_node(transition_to):
			var found_node: Node = container.get_node(transition_to)
			var new_state: State
			if found_node is State:
				new_state = found_node
			elif found_node is StateLink:
				var link: StateLink = found_node
				new_state = link.link_to
			
			set_state(type, new_state)
		else:
			set_state(type, null)
	
	## handle startups
	if is_instance_valid(container):
		var startup_state: State = check_startups(self[type], container)
		if is_instance_valid(startup_state):
			set_state(type, startup_state)


### Collision queries
func is_grounded() -> bool:
	return collider.floor_info["is_colliding"]


### Physics
func get_gravity_sum() -> float:
	# yeah, for some reason gravity is twice as strong as advertised in 127
	var total_factor: float = gravity * 2 * gravity_factor
	if is_instance_valid(physics):
		total_factor *= physics.gravity_factor
	if is_instance_valid(action):
		total_factor *= action.gravity_factor
	return total_factor

func get_size() -> Vector2:
	if is_instance_valid(action) and action.override_size:
		return action.custom_size
	if is_instance_valid(physics) and physics.override_size:
		return physics.custom_size
	return base_size

func can_snap() -> bool:
	if is_instance_valid(action):
		return not action.disable_snap
	if is_instance_valid(physics):
		return not physics.disable_snap
	return true
