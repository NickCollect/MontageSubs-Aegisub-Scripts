--[[
Script Name: Cinematic Tracking
Description: 电影感字间距动画 (Mac Compatible)
Author: NickCollect
Version: 1.2
]]

script_name = "Cinematic Tracking"
script_description = "电影感字间距缩放"
script_author = "Gemini"
script_version = "1.0"

include("karaskel.lua")

function process_lines(subs, sel)
    local meta, styles = karaskel.collect_head(subs, false)
    
    local dialog_config = {
        {class="label", label="Start Spacing:", x=0, y=0, width=1, height=1},
        {class="edit", name="s_fsp", x=1, y=0, width=1, height=1, value="0", hint="开始时的间距"},
        
        {class="label", label="End Spacing:", x=0, y=1, width=1, height=1},
        {class="edit", name="e_fsp", x=1, y=1, width=1, height=1, value="10", hint="结束时的间距"},
        
        {class="label", label="Accel (1=Linear):", x=0, y=2, width=1, height=1},
        {class="edit", name="accel", x=1, y=2, width=1, height=1, value="1", hint="加速度: 1=匀速, <1=减速, >1=加速"}
    }
    
    local btn, res = aegisub.dialog.display(dialog_config, {"Animate", "Cancel"})
    if btn == "Cancel" then aegisub.cancel() end
    
    local s_fsp = res.s_fsp
    local e_fsp = res.e_fsp
    local accel = res.accel
    
    for i = #sel, 1, -1 do
        local line_index = sel[i]
        local line = subs[line_index]
        karaskel.preproc_line(subs, meta, styles, line)
        
        -- 生成 \t(\fsp) 动画
        -- 格式: {\fspSTART\t(accel,\fspEND)}
        
        local tag = string.format("{\\fsp%s\\t(%s,\\fsp%s)}", s_fsp, accel, e_fsp)
        
        -- 插入标签
        if line.text:match("^{") then
            line.text = line.text:gsub("^{", tag, 1)
        else
            line.text = tag .. line.text
        end
        
        -- 清理可能产生的重复标签
        line.text = line.text:gsub("}{", "")
        
        subs[line_index] = line
    end
    
    aegisub.set_undo_point("Cinematic Tracking")
end

aegisub.register_macro(script_name, script_description, process_lines)