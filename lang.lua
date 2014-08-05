--------------------------------------------------
-- HTTP Accept-Language header handler          --
-- @author f.ghibellini@gmail.com               --
-- @license MIT                                 --
-- @requires:                                   --
--  -gnu find                                   --
-- @description:                                --
--     redirects to subfolders according        --
--     to the http Accept-Language header       --
-- @example coinfguration:                      --
--                                              --
--     server {                                 --
--         listen 8080 default_server;          --
--         index index.html index.htm;          --
--         server_name localhost;               --
--                                              --
--         set $root /usr/share/nginx/html;     --
--         root $root;                          --
--                                              --
--         location /index.html {               --
--             # lua_code_cache off;            --
--             set $default_lang "cz";          --
--             set $ngx_html_path $root;        --
--             rewrite_by_lua_file lang.lua;    --
--         }                                    --
--     }                                        --
--                                              --
--------------------------------------------------

function scandir(directory)
    local t = {}
    for filename in io.popen('find "'..directory..'" -type d -mindepth 1 -maxdepth 1 -printf "%f\n"'):lines() do
        table.insert(t, filename)
    end
    return t
end

function inTable(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return key end
    end
    return false
end

local default_lang = ngx.var.default_lang or "en"
local folders = scandir(ngx.var.ngx_html_path)

local lang_header = ngx.var.http_accept_language
if ( lang_header == nil ) then
    ngx.redirect( "/" .. default_lang )
    return
end

local cleaned = ngx.re.sub(lang_header, "^.*:", "")
local options = {}
local iterator, err = ngx.re.gmatch(cleaned, "\\s*([a-z]+(?:-[a-z])*)\\s*(?:;q=([0-9]+(.[0-9]*)?))?\\s*(,|$)", "i")
for m, err in iterator do
    local lang = m[1]
    local priority = 1
    if m[2] ~= nil then
        priority = tonumber(m[2])
        if priority == nil then
            priority = 1
        end
    end
    table.insert(options, {lang, priority})
end

--for index, lang in pairs(options) do
--    ngx.print(lang[1] .. " := " .. lang[2] .. "<br>")
--end
--ngx.print("\n")

table.sort(options, function(a,b) return b[2] < a[2] end)

local redirected = false
for index, lang in pairs(options) do
    if inTable(folders, lang[1]) then
        ngx.redirect( "/" .. lang[1] )
        redirected = true
        break
    end
end
if not redirected then
    ngx.redirect( "/" .. default_lang )
end
