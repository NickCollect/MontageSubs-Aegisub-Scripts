--[[
Script Name: Glitch Effect
Description: 随机拉伸变形干扰特效 (Mac Compatible)
Author: NickCollect
Version: 1.3
]]

script_name = "Glitch Effect"
script_description = "故障干扰/信号抽搐"
script_author = "Gemini"
script_version = "1.0"

include("karaskel.lua")

function process_lines(subs, sel)
    local meta, styles = karaskel.collect_head(subs, false)
    
    local dialog_config = {
        {class="label", label="Intensity (变形强度 %):", x=0, y=0, width=1, height=1},
        {class="edit", name="power", x=1, y=0, width=1, height=1, value="50", hint="例如50代表拉伸范围在 50%-150%"},
        
        {class="label", label="Probability (0-100):", x=0, y=1, width=1, height=1},
        {class="edit", name="prob", x=1, y=1, width=1, height=1, value="30", hint="每帧发生故障的概率，30代表30%"},
        
        {class="label", label="Speed (ms/frame):", x=0, y=2, width=1, height=1},
        {class="edit", name="speed", x=1, y=2, width=1, height=1, value="40"},
        
        {class="checkbox", name="keep", x=0, y=3, width=2, height=1, label="Keep Original", value=false}
    }
    
    local btn, res = aegisub.dialog.display(dialog_config, {"Glitch!", "Cancel"})
    if btn == "Cancel" then aegisub.cancel() end
    
    local power = tonumber(res.power) or 50
    local prob = tonumber(res.prob) or 30
    local frame_dur = tonumber(res.speed) or 40
    
    for i = #sel, 1, -1 do
        local line_index = sel[i]
        local line = subs[line_index]
        karaskel.preproc_line(subs, meta, styles, line)
        
        local start_time = line.start_time
        local end_time = line.end_time
        local duration = end_time - start_time
        local frames = math.ceil(duration / frame_dur)
        
        -- 预处理：移除旧的变形标签
        local clean_text = line.text:gsub("\\fsc[xy][%d%.]+", "")
        
        for f = 0, frames - 1 do
            local new_line = table.copy(line)
            new_line.start_time = start_time + (f * frame_dur)
            new_line.end_time = start_time + ((f + 1) * frame_dur)
            if new_line.end_time > end_time then new_line.end_time = end_time end
            
            -- 随机判定是否发生故障
            if math.random(0, 100) < prob then
                -- 产生随机拉伸
                -- power=50 意味着 scale 在 100-50 到 100+50 之间 (50% - 150%)
                local scale_x = 100 + math.random(-power, power)
                local scale_y = 100 + math.random(-power, power)
                
                local tag = string.format("{\\fscx%d\\fscy%d}", scale_x, scale_y)
                
                -- 插入标签
                if clean_text:match("^{") then
                    new_line.text = clean_text:gsub("^{", tag, 1)
                else
                    new_line.text = tag .. clean_text
                end
                new_line.text = new_line.text:gsub("}{", "")
            else
                -- 正常帧 (重置为100%)
                local tag = "{\\fscx100\\fscy100}"
                 if clean_text:match("^{") then
                    new_line.text = clean_text:gsub("^{", tag, 1)
                else
                    new_line.text = tag .. clean_text
                end
                new_line.text = new_line.text:gsub("}{", "")
            end
            
            subs.insert(line_index + 1 + f, new_line)
        end
        
        if res.keep then
            line.comment = true
            subs[line_index] = line
        else
            subs.delete(line_index)
        end
    end
    aegisub.set_undo_point("Glitch Effect")
end

aegisub.register_macro(script_name, script_description, process_lines)