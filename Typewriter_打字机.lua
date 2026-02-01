--[[
Script Name: Typewriter Smart (Lua 5.1 Fix)
Description: 智能打字机 (兼容旧版 Lua 引擎)
Author: NickCollect
Version: 4.1
]]

script_name = "Typewriter Smart"
script_description = "打字机 (智能忽略标签)"
script_author = "Gemini"
script_version = "4.1"

include("karaskel.lua")

function process_lines(subs, sel)
    local meta, styles = karaskel.collect_head(subs, false)
    
    local dialog_config = {
        {class="label", label="Speed (ms/char):", x=0, y=0, width=1, height=1},
        {class="edit", name="speed", x=1, y=0, width=1, height=1, value="100"},
        {class="label", label="Start Delay (ms):", x=0, y=1, width=1, height=1},
        {class="edit", name="delay", x=1, y=1, width=1, height=1, value="0"},
        {class="checkbox", name="fade", x=1, y=2, width=2, height=1, label="Fade In (淡入)", value=false}
    }
    
    local btn, res = aegisub.dialog.display(dialog_config, {"Type!", "Cancel"})
    if btn == "Cancel" then aegisub.cancel() end
    
    local speed = tonumber(res.speed) or 100
    local start_delay = tonumber(res.delay) or 0
    local is_fade = res.fade
    
    for i = #sel, 1, -1 do
        local line_index = sel[i]
        local line = subs[line_index]
        karaskel.preproc_line(subs, meta, styles, line)
        
        local text_raw = line.text
        local new_text = ""
        local current_time = start_delay
        
        local i_pos = 1
        while i_pos <= #text_raw do
            local char = string.sub(text_raw, i_pos, i_pos)
            local processed = false -- 标记是否被特殊处理了
            
            -- Case 1: 遇到特效代码块的开始 "{"
            if char == "{" then
                local end_bracket = string.find(text_raw, "}", i_pos, true)
                if end_bracket then
                    -- 找到了完整代码块，直接复制
                    local tag_block = string.sub(text_raw, i_pos, end_bracket)
                    new_text = new_text .. tag_block
                    i_pos = end_bracket + 1
                    processed = true
                end
                -- 如果没找到 }，processed 为 false，会掉下去按普通字处理

            -- Case 2: 遇到换行符或硬空格
            elseif char == "\\" then
                local next_char = string.sub(text_raw, i_pos+1, i_pos+1)
                if next_char == "N" or next_char == "n" or next_char == "h" then
                    new_text = new_text .. "\\" .. next_char
                    i_pos = i_pos + 2
                    processed = true
                end
                -- 如果不是特殊换行，processed 为 false，会掉下去按普通字处理
            end
            
            -- Case 3: 普通文字 (UTF-8 处理)
            -- 如果上面没有处理过，就进入这里
            if not processed then
                local c = string.byte(text_raw, i_pos)
                local len = 1
                if c >= 0xF0 then len = 4
                elseif c >= 0xE0 then len = 3
                elseif c >= 0xC0 then len = 2 end
                
                local utf8_char = string.sub(text_raw, i_pos, i_pos + len - 1)
                
                -- 计算时间
                local t_start = current_time
                local t_end = current_time
                
                if is_fade then
                    t_end = t_start + speed
                else
                    t_end = t_start + 1
                end
                
                local tag = string.format("{\\alpha&HFF&\\t(%d,%d,\\alpha&H00&)}", t_start, t_end)
                
                new_text = new_text .. tag .. utf8_char
                
                current_time = current_time + speed
                i_pos = i_pos + len
            end
        end
        
        line.text = new_text
        subs[line_index] = line
    end
    
    aegisub.set_undo_point("Typewriter Smart")
end

aegisub.register_macro(script_name, script_description, process_lines)