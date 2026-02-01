--[[
Script Name: Split By Character
Description: 将一行字幕拆分为单字行 (自动保留位置)
Author: NickCollect
Version: 1.0
]]

script_name = "Split By Character"
script_description = "一键拆分单字 (Split)"
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
        elseif c >= 0xC0 then len = 2
        end
        local char = string.sub(str, i, i + len - 1)
        i = i + len
        return char
    end
end

function process_lines(subs, sel)
    local meta, styles = karaskel.collect_head(subs, false)
    
    -- 倒序处理
    for i = #sel, 1, -1 do
        local line_index = sel[i]
        local line = subs[line_index]
        karaskel.preproc_line(subs, meta, styles, line)
        
        -- 只有当 karaskel 计算出了宽度信息才继续
        if line.kara and #line.kara > 0 then
            -- 如果有 karaoke 信息(非常罕见)，利用它
            -- 但通常普通字幕没有 karaoke，我们需要手动算宽度
            -- 简易版逻辑：利用 karaskel 提供的 line.left 等信息很难精确到每个字
            -- 最精确的方法是利用 \k 模板，但这里我们用简单的“假设等宽”或者依靠 karaskel.layout
            -- 注：Aegisub 的 Lua 接口在没有渲染库支持下，很难精准计算每个字的像素宽度
            -- 所以这个脚本使用 "Center Pos + Offset" 的估算方法，或者利用 karaskel 的 character split
        end
        
        -- 为了不写几十行复杂的字体宽度计算(依赖 C++ 库)，我们换一种策略：
        -- 我们生成多行，内容分别是 "你", "{\alphaFF}你{\alpha00}好", ...
        -- 不对，最实用的方法是：保持整行文字，但是用 \alpha&HFF& 把不需要显示的字隐藏掉
        -- 这样位置绝对不会乱！
        
        local text_stripped = line.text_stripped
        local char_list = {}
        for c in utf8_chars(text_stripped) do
            table.insert(char_list, c)
        end
        
        for c_idx, char in ipairs(char_list) do
            local new_line = table.copy(line)
            
            -- 构建“伪拆分”字符串
            -- 原理：把前面的字设为透明，把后面的字设为透明，只显示中间那个字
            -- 例子：对于 "ABC" 拆 "B" -> "{\alphaFF}A{\alpha00}B{\alphaFF}C"
            -- 这样 Aegisub 渲染时会自动对齐，看起来就像是拆开了一样
            
            local build_text = ""
            
            -- 前面的字透明
            if c_idx > 1 then
                build_text = build_text .. "{\\alpha&HFF&}" .. table.concat(char_list, "", 1, c_idx - 1)
            end
            
            -- 当前字显示 (重置 alpha)
            build_text = build_text .. "{\\alpha&H00&}" .. char
            
            -- 后面的字透明
            if c_idx < #char_list then
                build_text = build_text .. "{\\alpha&HFF&}" .. table.concat(char_list, "", c_idx + 1, #char_list)
            end
            
            -- 合并原有的标签 (放在最前面)
            -- 简单的把原 text 里的标签提取出来可能比较乱
            -- 这里我们简单粗暴：把构建好的带透明度的文本作为新文本
            -- 注意：这会丢失原行内极其复杂的卡拉OK标签，但保留行首标签
            
            local tag_head = line.text:match("^({[^}]+})") or ""
            new_line.text = tag_head .. build_text
            
            subs.insert(line_index + c_idx, new_line)
        end
        
        subs.delete(line_index)
    end
    
    aegisub.set_undo_point("Split Chars")
end

aegisub.register_macro(script_name, script_description, process_lines)