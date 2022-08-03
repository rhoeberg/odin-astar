package main

import "core:fmt"
import "core:strings"
import "core:container/priority_queue"

World_Pos :: [2]int
WORLD_SIZE :: 12

World :: struct {
	tiles: [WORLD_SIZE][WORLD_SIZE]bool,
	goal: World_Pos,
	start: World_Pos,
}

Node :: struct {
	pos: World_Pos,
	weight: int,
	prev: ^Node,
}

/* Queue_Node :: struct { */
/* 	node: ^Node, */
/* } */

nodes: [dynamic]Node
pq: priority_queue.Priority_Queue(^Node)
world: World

my_less :: proc(a: ^Node, b: ^Node) -> bool {
	return a.weight < b.weight
}


dist_from_goal :: proc(pos: World_Pos, goal: World_Pos) -> int {
	return abs(goal.x - pos.x) + abs(goal.y - pos.y)
}

calc_node_weight :: proc(prev: ^Node, pos: World_Pos) -> int {
	return prev.weight + dist_from_goal(pos, world.goal) 
}

add_node :: proc(node: Node) {
	append(&nodes, node)
	priority_queue.push(&pq, &nodes[len(nodes)-1])
}

astar :: proc() {

	sb : strings.Builder

	valid_node_pos :: proc(pos: World_Pos) -> bool {
		if (pos.x < WORLD_SIZE && pos.x >= 0) {
			if pos.y < WORLD_SIZE && pos.y >= 0 {
				if world.tiles[pos.x][pos.y] {
					return true
				}
			}
		}
		return false
	}

	try_to_add_node :: proc(prev: ^Node, pos: World_Pos) {
		if valid_node_pos(pos) {
			node := Node{pos=pos, weight=calc_node_weight(prev, pos), prev=prev}
			add_node(node)
		}
	}

	add_nodes_around_to_queue :: proc(node: ^Node) {

		new_positions: [4]World_Pos
		count := 0

		// up
		up := node.pos + World_Pos{0, 1} 
		if valid_node_pos(up) {
			new_positions[count] = up
			count += 1
		}

		// down
		down := node.pos - World_Pos{0, 1}
		if valid_node_pos(down) {
			new_positions[count] = down
			count += 1
		}

		// left
		left := node.pos - World_Pos{1, 0}
		if valid_node_pos(left) {
			new_positions[count] = left
			count += 1
		}

		// right
		right := node.pos + World_Pos{1, 0}
		if valid_node_pos(right) {
			new_positions[count] = right
			count += 1
		}

		lowest_score := 0 
		lowest_id := 0
		for i in 0..<count {
			if i == 0 {
				lowest_score = calc_node_weight(node, new_positions[i])
			}
			else {
				new_score := calc_node_weight(node, new_positions[i])
				if new_score < lowest_score {
					lowest_score = new_score
					lowest_id = i
				}
			}
		}

		try_to_add_node(node, new_positions[lowest_id])



		/* if node.prev == nil || up_pos != node.prev.pos { */
		/* 	try_to_add_node(node, {node.pos.x, node.pos.y + 1}) */
		/* } */

		/* // down */
		/* if node.prev == nil || down_pos != node.prev.pos { */
		/* 	try_to_add_node(node, down_pos) */
		/* } */
		
		/* // left */
		/* if node.prev == nil || left_pos != node.prev.pos { */
		/* 	try_to_add_node(node, left_pos) */
		/* } */

		/* // right */
		/* if node.prev == nil || right_pos != node.prev.pos { */
		/* 	try_to_add_node(node, right_pos) */
		/* } */

	}

	start_node := Node{world.start, 0, nil}
	path_node : ^Node
	add_node(start_node)

	found_goal := false
	for !found_goal {
		if priority_queue.len(pq) > 0 {
			node := priority_queue.pop(&pq)
			if node.pos == world.goal {
				// found the path
				fmt.println("found goal")
				found_goal = true
				path_node = node
				break
			}
			else {
				add_nodes_around_to_queue(node)
			}
		}
		else {
			fmt.println("could not find goal")
			break
		}
	}

	fmt.println("writing path")
	done_rewind := false
	for !done_rewind {
		fmt.println(path_node.pos)
		if path_node.prev == nil {
			done_rewind = true
		}
		else {
			path_node = path_node.prev
		}
	}
}

print_world :: proc() {
	sb : strings.Builder
	for column in 0..<WORLD_SIZE {
		for row in 0..<WORLD_SIZE {
			if (world.goal == World_Pos{column, row}) {
				fmt.sbprint(&sb, "[2]")
			}
			else if (world.start == World_Pos{column, row}) {
				fmt.sbprint(&sb, "[1]")
			}
			else if world.tiles[column][row] {
				fmt.sbprint(&sb, "[x]")
			}
			else {
				fmt.sbprint(&sb, "[0]")
			}
		}
		fmt.sbprint(&sb, "\n")
	}

	fmt.print(strings.to_string(sb))
}

main :: proc() {

	world.goal = World_Pos{ WORLD_SIZE-1, WORLD_SIZE-1}
	world.start = World_Pos{ 0, 0}

	reserve(&nodes, 1024)

	priority_queue.init(&pq, my_less, priority_queue.default_swap_proc(^Node), 1024)

	for column in 0..<WORLD_SIZE {
		for row in 0..<WORLD_SIZE {
			world.tiles[column][row] = true
		}
	}
	world.tiles[0][5] = false
	print_world()

	astar()
}
