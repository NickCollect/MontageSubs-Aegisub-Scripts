--[[
Script Name: Neon Flicker
Description: 随机透明度闪烁，模拟霓虹灯故障 (Mac Compatible)
Author: NickCollect
Version: 1.0
]]

script_name = "Neon Flicker"
script_description = "霓虹灯/光线闪烁"
script_author = "Gemini"
script_version = "1.0"

include("karaskel.lua")

function process_lines(subs, sel)
    local dialog_config = {
        {class="label", label="Min Alpha (0-255):", x=0, y=0},
        {class="edit", name="min_a", x=1, y=0, value="0", hint="最亮时的透明度(0=不透)"},
        
        {class="label", label="Max Alpha (0-255):", x=0, y=1},
        {class="edit", name="max_a", x=1, y=1, value="200", hint="最暗时的透明度(255=全透)"},
        
        {class="label", label="Speed (ms/flicker):", x=0, y=2},
        {class="edit", name="speed", x=1, y=2, value="50", hint="闪烁速度(越小越快)"}
    }
    
    local btn, res = aegisub.dialog.display(dialog_config, {"Flicker", "Cancel"})
    if btn == "Cancel" then aegisub.cancel() end
    
    local min_a = tonumber(res.min_a) or 0
    local max_a = tonumber(res.max_a) or 200
    local speed = tonumber(res.speed) or 50
    
    for i, idx in ipairs(sel) do
        local line = subs[idx]
        local duration = line.end_time - line.start_time
        local loops = math.ceil(duration / speed)
        
        local tags = ""
        -- 初始状态
        tags = tags .. string.format("\\alpha&H%02X&", min_a)
        
        for l = 0, loops - 1 do
            local t_start = l * speed
            local t_end = t_start + speed
            
            -- 随机生成目标透明度
            local target_alpha = math.random(min_a, max_a)
            
            -- 每一段都瞬间变化，模拟电流不稳定
            tags = tags .. string.format("\\t(%d,%d,\\alpha&H%02X&)", t_start, t_end, target_alpha)
        end
        
        -- 插入标签
        if line.text:match("^{") then
            line.text = line.text:gsub("^{", "{" .. tags, 1)
        else
            line.text = "{" .. tags .. "}" .. line.text
        end
        line.text = line.text:gsub("}{", "")
        
        subs[idx] = line
    end
    
    aegisub.set_undo_point("Neon Flicker")
end

aegisub.register_macro(script_name, script_description, process_lines)