package scene

Init_Scene_t :: proc(p_game_context: rawptr, p_scene_data: rawptr)
Start_Scene_t :: proc(p_game_context: rawptr, p_scene_data: rawptr)
Render_Scene_t :: proc(p_game_context: rawptr, p_scene_data: rawptr)
Update_Scene_t :: proc(p_game_context: rawptr, p_scene_data: rawptr)
Stop_Scene_t :: proc(p_game_context: rawptr, p_scene_data: rawptr)
Destroy_Scene_t :: proc(p_game_context: rawptr, p_scene_data: rawptr)

Scene_t :: struct {
    init: Init_Scene_t,
    start: Start_Scene_t,
    render: Render_Scene_t,
    update: Update_Scene_t,
    stop: Stop_Scene_t,
    destroy: Destroy_Scene_t,
    data: rawptr,
}



Scene_Manager_t :: struct {
    current_scene: string,
    scenes: map[string]Scene_t,
}


create_scene_manager :: proc() -> ^Scene_Manager_t {
    p_manager               := new(Scene_Manager_t)
    p_manager.scenes        = make(map[string]Scene_t)
    p_manager.current_scene = ""
    return p_manager
}


scene_manager_add_scene :: proc(p_scene_manager: ^Scene_Manager_t, name: string, scene: Scene_t) {
    p_scene_manager.scenes[name] = scene
}


scene_manager_init_scenes :: proc(p_scene_manager: ^Scene_Manager_t, p_game_context: rawptr) {
    for name in p_scene_manager.scenes {
        scene := p_scene_manager.scenes[name]
        if scene.init != nil {
            scene.init(p_game_context, scene.data)
        }
    }
}

scene_manager_run_scene :: proc(p_scene_manager: ^Scene_Manager_t, p_game_context: rawptr, name: string) {
    scene_to_stop, ok_scene_to_stop := p_scene_manager.scenes[p_scene_manager.current_scene]
    if ok_scene_to_stop {
        if scene_to_stop.stop != nil {
            scene_to_stop.stop(p_game_context, scene_to_stop.data)
        }
    }
    
    p_scene_manager.current_scene = name
    scene_to_start, ok_scene_to_start := p_scene_manager.scenes[p_scene_manager.current_scene]
    if ok_scene_to_start {
        if scene_to_start.start != nil {
            scene_to_start.start(p_game_context, scene_to_start.data)
        }
    }
}

scene_manager_render :: proc(p_scene_manager: ^Scene_Manager_t, p_game_context: rawptr) {
    scene_to_render, ok_scene_to_render := p_scene_manager.scenes[p_scene_manager.current_scene]
    if ok_scene_to_render {
        if scene_to_render.render != nil {
            scene_to_render.render(p_game_context, scene_to_render.data)
        }
    }
}

scene_manager_update :: proc(p_scene_manager: ^Scene_Manager_t, p_game_context: rawptr) {
    scene_to_update, ok_scene_to_update := p_scene_manager.scenes[p_scene_manager.current_scene]
    if ok_scene_to_update {
        if scene_to_update.update != nil {
            scene_to_update.update(p_game_context, scene_to_update.data)
        }
    }
}



destroy_scene_manager :: proc(p_scene_manager: ^Scene_Manager_t, p_game_context: rawptr) {
    for name in p_scene_manager.scenes {
        scene := p_scene_manager.scenes[name]
        if scene.destroy != nil {
            scene.destroy(p_game_context, scene.data)
        }
    }
}

