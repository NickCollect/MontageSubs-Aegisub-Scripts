--[[
Script Name: Quick Border & Blur
Description: 批量给字幕加边框和模糊 (Mac兼容版)
Author: NickCollect
Version: 1.0
]]

script_name = "Quick Border & Blur"
script_description = "批量加边框和模糊"
script_author = "Gemini"
script_version = "1.0"

function process_lines(subs, sel)
    -- GUI 配置：使用纯文本框以确保 Mac 兼容性
    local dialog_config = {
        -- 边框设置
        {class="label", label="Border Size (边框):", x=0, y=0, width=1, height=1},
        {class="edit", name="bord_val", x=1, y=0, width=1, height=1, value="2"},
        
        -- 模糊设置
        {class="label", label="Blur Size (模糊):", x=0, y=1, width=1, height=1},
        {class="edit", name="blur_val", x=1, y=1, width=1, height=1, value="3"},
        
        -- 阴影设置 (顺手给你加上，不需要可以填0)
        {class="label", label="Shadow (阴影):", x=0, y=2, width=1, height=1},
        {class="edit", name="shad_val", x=1, y=2, width=1, height=1, value="0"},
    }
    
    local btn, res = aegisub.dialog.display(dialog_config, {"Run", "Cancel"})
    
    if btn == "Cancel" then aegisub.cancel() end
    
    -- 获取输入值
    local bord = res.bord_val
    local blur = res.blur_val
    local shad = res.shad_val

    -- 开始处理每一行
    for i, idx in ipairs(sel) do
        local line = subs[idx]
        local text = line.text
        
        -- 1. 清理旧标签 (防止代码堆积，比如 {\bord2\bord5} 这种)
        -- 移除已有的 \bord, \blur, \shad, \be 等
        text = text:gsub("\\bord[%d%.]+", "")
        text = text:gsub("\\blur[%d%.]+", "")
        text = text:gsub("\\shad[%d%.]+", "")
        text = text:gsub("\\be[%d%.]+", "") -- 移除旧的边缘模糊标签
        
        -- 2. 构建新标签字符串
        local new_tags = ""
        
        -- 只有当输入值大于等于0时才添加标签
        if tonumber(bord) and tonumber(bord) >= 0 then
            new_tags = new_tags .. "\\bord" .. bord
        end
        
        if tonumber(blur) and tonumber(blur) >= 0 then
            new_tags = new_tags .. "\\blur" .. blur
        end
        
        if tonumber(shad) and tonumber(shad) > 0 then
            new_tags = new_tags .. "\\shad" .. shad
        end
        
        -- 3. 插入到文本中
        if text:match("^{") then
            -- 如果这行本来就有特效标签 {...}
            -- 我们就把新标签插在第一个 { 的后面
            text = text:gsub("^{", "{" .. new_tags, 1)
        else
            -- 如果这行是纯文本
            -- 我们就给它包上花括号
            text = "{" .. new_tags .. "}" .. text
        end
        
        -- 4. 清理可能产生的空标签 (美观)
        text = text:gsub("{}", "")
        
        line.text = text
        subs[idx] = line
    end
    
    aegisub.set_undo_point("Add Border & Blur")
end

aegisub.register_macro(script_name, script_description, process_lines)