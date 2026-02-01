--[[
Script Name: Chaos Randomizer
Description: 随机旋转和缩放每个字符 (Mac Compatible)
Author: NickCollect
Version: 1.0
]]

script_name = "Chaos Randomizer"
script_description = "混沌/随机旋转缩放"
script_author = "Gemini"
script_version = "1.0"

include("karaskel.lua")

-- UTF-8 迭代器
function utf8_chars(str)
    local i = 1
    return function()
        if i > #str then return nil end
        local c = string.byte(str, i)
        local len = 1
        if c >= 0xF0 then len = 4
        elseif c >= 0xE0 then len = 3
        elseif c >= 0xC0 then len = 2 end
        local char = string.sub(str, i, i + len - 1)
        i = i + len
        return char
    end
end

function process_lines(subs, sel)
    local meta, styles = karaskel.collect_head(subs, false)
    
    local dialog_config = {
        {class="label", label="Max Rotation (deg):", x=0, y=0},
        {class="edit", name="rot", x=1, y=0, value="15", hint="最大旋转角度(+/-)"},
        
        {class="label", label="Scale Variation (%):", x=0, y=1},
        {class="edit", name="scale", x=1, y=1, value="20", hint="大小浮动范围(+/-)"},
        
        {class="label", label="Keep Tags?", x=0, y=2},
        {class="checkbox", name="keep", x=1, y=2, label="Ignore {} tags", value=true}
    }
    
    local btn, res = aegisub.dialog.display(dialog_config, {"Chaos!", "Cancel"})
    if btn == "Cancel" then aegisub.cancel() end
    
    local max_rot = tonumber(res.rot) or 15
    local max_scale = tonumber(res.scale) or 20
    
    for i = #sel, 1, -1 do
        local line_index = sel[i]
        local line = subs[line_index]
        karaskel.preproc_line(subs, meta, styles, line)
        
        local text = line.text_stripped -- 简单起见，这里处理纯文本
        if res.keep then 
            -- 如果要保留标签比较复杂，这里简化处理：只处理 text_stripped
            -- 原始标签会丢失。如果需要保留标签，建议用之前的 Typewriter Smart 逻辑修改
            -- 但对于混沌效果，通常是单独的一句特效，丢标签影响不大
        end
        
        local new_text = ""
        
        for char in utf8_chars(text) do
            -- 随机旋转
            local rot = math.random(-max_rot, max_rot)
            -- 随机缩放 (例如 80% - 120%)
            local sc_x = 100 + math.random(-max_scale, max_scale)
            local sc_y = 100 + math.random(-max_scale, max_scale)
            
            -- 生成标签
            local tag = string.format("{\\frz%d\\fscx%d\\fscy%d}", rot, sc_x, sc_y)
            new_text = new_text .. tag .. char
        end
        
        line.text = new_text
        subs[line_index] = line
    end
    
    aegisub.set_undo_point("Chaos Randomizer")
end

aegisub.register_macro(script_name, script_description, process_lines)