package main

import "core:fmt"
import "core:strings"
import "core:container/priority_queue"
import rl "vendor:raylib"

World_Pos :: [2]int
WORLD_SIZE :: 10
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 800
TILE_SIZE :: SCREEN_WIDTH / WORLD_SIZE

World :: struct {
	tiles: [WORLD_SIZE][WORLD_SIZE]bool,
	goal: World_Pos,
	start: World_Pos,
}

Node :: struct {
	pos: World_Pos,
	weight: int,
	prev: World_Pos,
}


nodes: map[World_Pos]Node
pq: priority_queue.Priority_Queue(World_Pos)

world: World
path: [dynamic]World_Pos
done_pathfinding: bool

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

reset_world :: proc() {
	done_pathfinding = false
	priority_queue.clear(&pq)
	clear(&nodes)

	world.goal.x = int(rl.GetRandomValue(0, WORLD_SIZE - 1))
	world.goal.y = int(rl.GetRandomValue(0, WORLD_SIZE - 1))

	for {
		world.start.x = int(rl.GetRandomValue(0, WORLD_SIZE - 1))
		world.start.y = int(rl.GetRandomValue(0, WORLD_SIZE - 1))
		if world.start != world.goal {
			start_node := Node{world.start, 0, world.start}
			add_node(start_node)
			break
		}
	}


	for column in 0..<WORLD_SIZE {
		for row in 0..<WORLD_SIZE {
			world.tiles[column][row] = true
		}
	}

	for i in 0..<10 {
		pos : World_Pos
		pos.x = int(rl.GetRandomValue(0, WORLD_SIZE - 1))
		pos.y = int(rl.GetRandomValue(0, WORLD_SIZE - 1))
		if pos != world.goal && pos != world.start {
			world.tiles[pos.x][pos.y] = false
		}
	}
}

my_less :: proc(a: World_Pos, b: World_Pos) -> bool {
	a_node := nodes[a]
	b_node := nodes[b]
	return a_node.weight + dist_from_goal(a, world.goal) < b_node.weight + dist_from_goal(b, world.goal)
}


dist_from_goal :: proc(pos: World_Pos, goal: World_Pos) -> int {
	return abs(goal.x - pos.x) + abs(goal.y - pos.y)
}

calc_node_weight :: proc(prev: World_Pos, pos: World_Pos) -> int {
	return nodes[prev].weight + 1
}

add_node :: proc(node: Node) {
	nodes[node.pos] = node
	priority_queue.push(&pq, node.pos)
}

astar :: proc(path: ^[dynamic]World_Pos) -> int {
	valid_node_pos :: proc(pos: World_Pos) -> bool {
		if (pos.x < WORLD_SIZE && pos.x >= 0) {
			if pos.y < WORLD_SIZE && pos.y >= 0 {
				if world.tiles[pos.x][pos.y] {
					if (pos in nodes) == false {
						return true
					}
				}
			}
		}
		return false
	}

	try_to_add_node :: proc(prev: World_Pos, pos: World_Pos) {
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
			try_to_add_node(node.pos, new_positions[i])
		}
	}

	expand_node :: proc() -> (int, ^Node) {
		if priority_queue.len(pq) > 0 {
			node := &nodes[priority_queue.pop(&pq)]
			if node.pos == world.goal {
				return 1, node
			}
			else {
				add_nodes_around_to_queue(node)
				return 2, node
			}

		}
		else {
			return 0, nil
		}
	}

	path_node : ^Node
	status : int

	status, path_node = expand_node()

	clear(path)
	if status != 0 && path_node != nil {
		append(path, path_node.pos)

		done_rewind := false
		for !done_rewind {
			if path_node.prev == world.start {
				done_rewind = true
			}
			else if path_node.prev in nodes {
				path_node = &nodes[path_node.prev]
				append(path, path_node.pos)
			}
			else {
				done_rewind = true
			}
		}
	}

	return status
}

main :: proc() {

	nodes = make(map[World_Pos]Node)
	priority_queue.init(&pq, my_less, priority_queue.default_swap_proc(World_Pos))

	rl.InitWindow(i32(SCREEN_WIDTH), i32(SCREEN_HEIGHT), "Odin Astar")
	defer rl.CloseWindow()

	reset_world()

	last_step := rl.GetTime()

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		defer rl.EndDrawing()


		// GUI

		// process astar
		step_delay := 0.1
		by_step := true 
		if !done_pathfinding {
			if last_step + step_delay < rl.GetTime() {
				status := 2
				for status == 2 {
					status = astar(&path)
					switch status {
					case 0:
						done_pathfinding = true
					case 1:
						done_pathfinding = true
					case 2:
					}


					if by_step {
						last_step = rl.GetTime()
						break
					}
				}
			}
		}


		// INPUT
		if rl.IsKeyPressed(.R) {
			reset_world()
		}

		
		// DRAWING
		rl.ClearBackground(rl.PINK)
		for x in 0..<WORLD_SIZE {
			for y in 0..<WORLD_SIZE {
				pos_x := i32(x * TILE_SIZE)
				pos_y := i32(y * TILE_SIZE)
				if world.tiles[x][y] {
					rl.DrawRectangle(pos_x, pos_y, TILE_SIZE, TILE_SIZE, rl.DARKBLUE)
				}
				else {
					rl.DrawRectangle(pos_x, pos_y, TILE_SIZE, TILE_SIZE, rl.BROWN)
				}
				rl.DrawRectangleLines(pos_x, pos_y, TILE_SIZE, TILE_SIZE, rl.BLACK)
			}
		}

		// draw path
		for pos in path {
			pos_x := i32(pos.x * TILE_SIZE)
			pos_y := i32(pos.y * TILE_SIZE)
			rl.DrawRectangle(pos_x, pos_y, TILE_SIZE, TILE_SIZE, rl.LIGHTGRAY)
		}

		// draw start
		start_x := i32(world.start.x * TILE_SIZE)
		start_y := i32(world.start.y * TILE_SIZE)
		rl.DrawRectangle(start_x, start_y, TILE_SIZE, TILE_SIZE, rl.RED)

		// draw goal
		goal_x := i32(world.goal.x * TILE_SIZE)
		goal_y := i32(world.goal.y * TILE_SIZE)
		rl.DrawRectangle(goal_x, goal_y, TILE_SIZE, TILE_SIZE, rl.GREEN)


	}
}
