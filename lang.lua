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

local cleaned = ngx.re.sub(ngx.var.http_accept_language, "^.*:", "")
local options = {}
local iterator, err = ngx.re.gmatch(cleaned, "([^,;]+)(;q=([^,]+))?")
for m, err in iterator do
    local lang = m[1]
    local priority = 1
    if m[3] ~= nil then
        priority = tonumber(m[3])
    end
    table.insert(options, {lang, priority})
end

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
